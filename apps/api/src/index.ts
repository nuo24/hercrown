// The whole API as one fetch handler. No router framework (ai-app-playbook chapter 02).
import { getAuth } from "./auth";
import { errorResponse, HttpError } from "./http";
import { completePlanStep, getPlan, listPlans, startPlan } from "./plans";
import { completeOnboarding, deleteAvatar, getAvatar, getMe, putAvatar, updatePreferences, updateProfile } from "./profile";
import { getStreak, recordReading } from "./reading";
import { listSaved, savePassage, unsavePassage } from "./saved";
import { getChapter, getPassage, listBooks, listTranslations, search } from "./scripture";

const savedPath = new URLPattern({ pathname: "/me/saved/:ref" });
const planPath = new URLPattern({ pathname: "/plans/:id" });
const planStartPath = new URLPattern({ pathname: "/plans/:id/start" });
const planStepPath = new URLPattern({ pathname: "/plans/:id/steps/:position/complete" });
const passagePath = new URLPattern({ pathname: "/scripture/:translation/passages/:ref" });
const chapterPath = new URLPattern({ pathname: "/scripture/:translation/:book/:chapter" });

export default {
  async fetch(request, env, ctx): Promise<Response> {
    const url = new URL(request.url);
    try {
      return await route(request, env, url); // await so rejected handlers land in this catch
    } catch (err) {
      if (err instanceof HttpError) return errorResponse(err);
      // Tinybird `error` events come with the analytics step; Workers Observability logs this meanwhile.
      console.error(`${request.method} ${url.pathname}`, err);
      return Response.json({ error: "internal" }, { status: 500 });
    }
  },
} satisfies ExportedHandler<Env>;

async function route(request: Request, env: Env, url: URL): Promise<Response> {
  if (url.pathname.startsWith("/api/auth/")) {
    const ip = request.headers.get("cf-connecting-ip") ?? "unknown";
    const { success } = await env.AUTH_LIMITER.limit({ key: ip });
    if (!success) return Response.json({ error: "rate_limited" }, { status: 429 });
    return getAuth().handler(request);
  }

  switch (`${request.method} ${url.pathname}`) {
    case "GET /health":
      return Response.json({ ok: true, env: env.APP_ENV });
  }

  const session = await getAuth().api.getSession({ headers: request.headers });
  if (!session) return Response.json({ error: "unauthorized" }, { status: 401 });
  const user = session.user;

  switch (`${request.method} ${url.pathname}`) {
    case "GET /me":
      return getMe(env, user);
    case "PATCH /me/profile":
      return updateProfile(request, env, user);
    case "PATCH /me/preferences":
      return updatePreferences(request, env, user);
    case "POST /me/onboarding/complete":
      return completeOnboarding(env, user);
    case "GET /me/avatar":
      return getAvatar(env, user);
    case "PUT /me/avatar":
      return putAvatar(request, env, user);
    case "DELETE /me/avatar":
      return deleteAvatar(env, user);
    case "GET /me/saved":
      return listSaved(env, user);
    case "POST /me/reading-events":
      return recordReading(request, env, user);
    case "GET /me/streak":
      return getStreak(url, env, user);
    case "GET /plans":
      return listPlans(env, user);
    case "GET /scripture/translations":
      return listTranslations(env);
    case "GET /scripture/books":
      return listBooks(env);
    case "GET /scripture/search":
      return search(url, env);
  }

  const saved = savedPath.exec(url);
  if (saved) {
    const ref = decodeURIComponent(saved.pathname.groups.ref!);
    if (request.method === "PUT") return savePassage(env, user, ref);
    if (request.method === "DELETE") return unsavePassage(env, user, ref);
  }
  const step = planStepPath.exec(url);
  if (step && request.method === "POST") {
    return completePlanStep(env, user, step.pathname.groups.id!, Number(step.pathname.groups.position));
  }
  const start = planStartPath.exec(url);
  if (start && request.method === "POST") return startPlan(env, user, start.pathname.groups.id!);
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
