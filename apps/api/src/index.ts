// The whole API as one fetch handler. No router framework (ai-app-playbook chapter 02).
import { getAuth } from "./auth";
import { entitlementFor, handleSuperwallWebhook } from "./billing";
import { deliverEvents, type EventRow, receiveEvents, requestContext, type ServerEvent, Tracker } from "./events";
import { errorResponse, HttpError } from "./http";
import { completePlanStep, getPlan, listPlans, startPlan } from "./plans";
import { completeOnboarding, deleteAvatar, getAvatar, getMe, putAvatar, updatePreferences, updateProfile } from "./profile";
import { getStreak, recordReading } from "./reading";
import { listSaved, savePassage, unsavePassage } from "./saved";
import { registerDevice, unregisterDevice } from "./push";
import { sendTrialReminders } from "./reminders";
import { type AiTool, getAiStudy, getOriginal, getRelated, reportStudy, TOOLS } from "./study";
import { restorePurchases } from "./restore";
import { getChapter, getPassage, listBooks, listTranslations, search } from "./scripture";

const savedPath = new URLPattern({ pathname: "/me/saved/:ref" });
const devicePath = new URLPattern({ pathname: "/me/devices/:token" });
const studyPath = new URLPattern({ pathname: "/study/:ref/:tool" });
const studyReportPath = new URLPattern({ pathname: "/study/:ref/:tool/report" });
const planPath = new URLPattern({ pathname: "/plans/:id" });
const planStartPath = new URLPattern({ pathname: "/plans/:id/start" });
const planStepPath = new URLPattern({ pathname: "/plans/:id/steps/:position/complete" });
const passagePath = new URLPattern({ pathname: "/scripture/:translation/passages/:ref" });
const chapterPath = new URLPattern({ pathname: "/scripture/:translation/:book/:chapter" });

export default {
  async fetch(request, env, ctx): Promise<Response> {
    const url = new URL(request.url);
    const tracker = new Tracker(env, ctx, requestContext(request));
    try {
      return await route(request, env, ctx, url, tracker); // await so rejected handlers land in this catch
    } catch (err) {
      if (err instanceof HttpError) return errorResponse(err);
      // Errors go to Tinybird with every other event (no separate error tracker); Workers Observability keeps the log.
      console.error(`${request.method} ${url.pathname}`, err);
      tracker.error(request, url, err);
      return Response.json({ error: "internal" }, { status: 500 });
    }
  },

  // Analytics queue → Tinybird.
  async queue(batch, env): Promise<void> {
    await deliverEvents(batch as MessageBatch<EventRow>, env);
  },

  // Cron Trigger (every 15 minutes): trial-ending reminders.
  async scheduled(controller, env, ctx): Promise<void> {
    await sendTrialReminders(env, controller.scheduledTime, ctx);
  },
} satisfies ExportedHandler<Env>;

/** Emits a feature event when the handler succeeded. */
async function tracked(response: Promise<Response>, tracker: Tracker, event: ServerEvent, props = {}): Promise<Response> {
  const res = await response;
  if (res.ok) tracker.track(event, props);
  return res;
}

async function route(request: Request, env: Env, ctx: ExecutionContext, url: URL, tracker: Tracker): Promise<Response> {
  if (url.pathname.startsWith("/api/auth/")) {
    const ip = request.headers.get("cf-connecting-ip") ?? "unknown";
    const { success } = await env.AUTH_LIMITER.limit({ key: ip });
    if (!success) return Response.json({ error: "rate_limited" }, { status: 429 });
    return getAuth().handler(request);
  }

  switch (`${request.method} ${url.pathname}`) {
    case "GET /health":
      return Response.json({ ok: true, env: env.APP_ENV });
    case "POST /webhooks/superwall":
      return handleSuperwallWebhook(request, env, ctx); // verified by signature, not by session
  }

  const session = await getAuth().api.getSession({ headers: request.headers });
  if (session) tracker.userId = session.user.id;
  // Analytics also accepts events from before guest sign-in (app_opened).
  if (request.method === "POST" && url.pathname === "/events") return receiveEvents(request, tracker);
  if (!session) return Response.json({ error: "unauthorized" }, { status: 401 });
  const user = session.user;

  switch (`${request.method} ${url.pathname}`) {
    case "GET /me":
      return getMe(env, user);
    case "GET /me/entitlements":
      return Response.json(await entitlementFor(env, user.id));
    case "POST /me/restore":
      return restorePurchases(request, env, user, tracker);
    case "PATCH /me/profile":
      return updateProfile(request, env, user);
    case "PATCH /me/preferences":
      return updatePreferences(request, env, user);
    case "POST /me/onboarding/complete":
      return completeOnboarding(env, user, tracker);
    case "GET /me/avatar":
      return getAvatar(env, user);
    case "PUT /me/avatar":
      return putAvatar(request, env, user);
    case "DELETE /me/avatar":
      return deleteAvatar(env, user);
    case "PUT /me/devices":
      return registerDevice(request, env, user);
    case "GET /me/saved":
      return listSaved(env, user);
    case "POST /me/reading-events":
      return tracked(recordReading(request, env, user), tracker, "passage_read");
    case "GET /me/streak":
      return getStreak(url, env, user);
    case "GET /plans":
      return listPlans(env, user);
    case "GET /scripture/translations":
      return listTranslations(env);
    case "GET /scripture/books":
      return listBooks(url, env);
    case "GET /scripture/search":
      return search(url, env);
  }

  const saved = savedPath.exec(url);
  if (saved) {
    const ref = decodeURIComponent(saved.pathname.groups.ref!);
    if (request.method === "PUT") return tracked(savePassage(env, user, ref), tracker, "passage_saved");
    if (request.method === "DELETE") return unsavePassage(env, user, ref);
  }
  const study = request.method === "GET" && studyPath.exec(url);
  if (study) {
    const ref = decodeURIComponent(study.pathname.groups.ref!);
    const tool = study.pathname.groups.tool!;
    if (tool === "related") return getRelated(env, user, ref, url);
    if (tool === "original") return getOriginal(env, user, ref);
    if ((TOOLS as readonly string[]).includes(tool)) return getAiStudy(request, env, ctx, user, ref, tool as AiTool, tracker);
  }
  const studyReport = request.method === "POST" && studyReportPath.exec(url);
  if (studyReport && (TOOLS as readonly string[]).includes(studyReport.pathname.groups.tool!)) {
    return reportStudy(request, env, user, decodeURIComponent(studyReport.pathname.groups.ref!), studyReport.pathname.groups.tool as AiTool, tracker);
  }
  const device = devicePath.exec(url);
  if (device && request.method === "DELETE") return unregisterDevice(env, user, decodeURIComponent(device.pathname.groups.token!));
  const step = planStepPath.exec(url);
  if (step && request.method === "POST") {
    const { id, position } = step.pathname.groups;
    return tracked(completePlanStep(env, user, id!, Number(position)), tracker, "plan_step_completed", { plan_id: id, position: Number(position) });
  }
  const start = planStartPath.exec(url);
  if (start && request.method === "POST") {
    return tracked(startPlan(env, user, start.pathname.groups.id!), tracker, "plan_started", { plan_id: start.pathname.groups.id });
  }
  const passage = request.method === "GET" && passagePath.exec(url);
  if (passage) return getPassage(env, passage.pathname.groups.translation!, decodeURIComponent(passage.pathname.groups.ref!));
  const chapter = request.method === "GET" && chapterPath.exec(url);
  if (chapter) {
    const { translation, book, chapter: n } = chapter.pathname.groups;
    return getChapter(env, translation!, book!, n!);
  }
  const plan = planPath.exec(url);
  if (plan && request.method === "GET") return getPlan(env, user, plan.pathname.groups.id!);

  return Response.json({ error: "not_found" }, { status: 404 });
}
