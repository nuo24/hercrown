// Settings → Contact & Support: a real request with a reference the person can quote, stored and emailed to the team
// inbox (SUPPORT_INBOX) when email is set up. Message contents are never logged.
import { emailConfigured, escapeHtml, sendEmail } from "./email";
import type { Tracker } from "./events";
import { badRequest, HttpError, oneOf, readJson } from "./http";
import type { SessionUser } from "./profile";

export const SUPPORT_CATEGORIES = ["Account", "Subscription & billing", "Bible & translations", "Study tools", "Something isn't working", "Feedback", "Other"] as const;
const CONTACT = ["email", "in_app"] as const;
const DAILY_LIMIT = 5;
const EMAIL = /^[^\s@]{1,64}@[^\s@]{1,255}\.[^\s@]{2,}$/;

/** "BS-7K2QH9XA": easy to read out loud (no 0/O, 1/I). */
function reference(): string {
  const alphabet = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ";
  const bytes = crypto.getRandomValues(new Uint8Array(8));
  return `BS-${[...bytes].map((b) => alphabet[b % alphabet.length]).join("")}`;
}

/** POST /me/support { category, message, contactEmail?, contactPreference?, appVersion? } → 201 { id, status } */
export async function createSupportRequest(request: Request, env: Env, ctx: ExecutionContext, user: SessionUser & { email?: string }, tracker: Tracker) {
  const body = await readJson(request);
  const category = oneOf(body, "category", SUPPORT_CATEGORIES);
  if (!category) throw badRequest(`category must be one of: ${SUPPORT_CATEGORIES.join(", ")}`);
  const message = typeof body.message === "string" ? body.message.trim() : "";
  if (!message || message.length > 5000) throw badRequest("message must be 1–5000 characters");
  const contactEmail = typeof body.contactEmail === "string" && body.contactEmail.trim() ? body.contactEmail.trim() : null;
  if (contactEmail && (!EMAIL.test(contactEmail) || contactEmail.length > 254)) throw badRequest("contactEmail must be an email address");
  const contactPreference = oneOf(body, "contactPreference", CONTACT) ?? (contactEmail ? "email" : "in_app");
  const appVersion = typeof body.appVersion === "string" ? body.appVersion.slice(0, 32) : request.headers.get("x-app-version")?.slice(0, 32) ?? null;

  const recent = await env.DB.prepare("SELECT count(*) AS n FROM support_requests WHERE user_id = ?1 AND created_at > ?2")
    .bind(user.id, Date.now() - 86_400_000).first<{ n: number }>();
  if ((recent?.n ?? 0) >= DAILY_LIMIT) throw new HttpError(429, "rate_limited", "You've sent several messages today. We'll reply to those first.");

  const id = reference();
  const t = Date.now();
  await env.DB.prepare(
    `INSERT INTO support_requests (id, user_id, category, message, contact_email, contact_preference, app_version, status, created_at, updated_at)
     VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, 'received', ?8, ?8)`,
  ).bind(id, user.id, category, message, contactEmail, contactPreference, appVersion, t).run();
  tracker.track("support_sent", { category });

  if (emailConfigured(env) && env.SUPPORT_INBOX) {
    ctx.waitUntil((async () => {
      try {
        const lines = [`Reference: ${id}`, `Category: ${category}`, `From user: ${user.id}`, `Reply to: ${contactEmail ?? "in app only"}`, `App version: ${appVersion ?? "unknown"}`, "", message];
        await sendEmail(env, {
          to: env.SUPPORT_INBOX, subject: `[${id}] ${category}`, text: lines.join("\n"),
          html: `<pre style="font: 14px/1.5 -apple-system, sans-serif; white-space: pre-wrap">${escapeHtml(lines.join("\n"))}</pre>`,
          ...(contactEmail ? { replyTo: contactEmail } : {}),
        });
        await env.DB.prepare("UPDATE support_requests SET delivered_at = ?2 WHERE id = ?1").bind(id, Date.now()).run();
      } catch (err) {
        console.error(`support: couldn't email ${id}`, err instanceof Error ? err.message : err); // stored; the team can still see it
      }
    })());
  }
  return Response.json({ id, status: "received", createdAt: t }, { status: 201 });
}

/** GET /me/support: her requests and their status. */
export async function listSupportRequests(env: Env, user: SessionUser) {
  const rows = await env.DB.prepare(
    "SELECT id, category, message, status, created_at, updated_at FROM support_requests WHERE user_id = ?1 ORDER BY created_at DESC LIMIT 50",
  ).bind(user.id).all<{ id: string; category: string; message: string; status: string; created_at: number; updated_at: number }>();
  return Response.json({
    categories: SUPPORT_CATEGORIES,
    requests: rows.results.map((r) => ({ id: r.id, category: r.category, message: r.message, status: r.status, createdAt: r.created_at, updatedAt: r.updated_at })),
  });
}
