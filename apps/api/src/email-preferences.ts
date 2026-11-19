import type { Tracker } from "./events";
import { badRequest, HttpError, readJson } from "./http";
import type { SessionUser } from "./profile";

export const EMAIL_CONSENT_VERSION = "updates-2026-11-19";

export async function getEmailPreferences(env: Env, user: SessionUser) {
  const row = await env.DB.prepare("SELECT subscribed FROM email_preferences WHERE user_id = ?1")
    .bind(user.id).first<{ subscribed: number }>();
  return Response.json({ subscribed: row?.subscribed === 1 });
}

export async function updateEmailPreferences(request: Request, env: Env, user: SessionUser, tracker: Tracker) {
  const body = await readJson(request);
  if (typeof body.subscribed !== "boolean") throw badRequest("subscribed must be a boolean");
  // Use only the verified identity email; never accept an arbitrary mailing address here.
  const identity = await env.DB.prepare('SELECT email, emailVerified, isAnonymous FROM "user" WHERE id = ?1')
    .bind(user.id).first<{ email: string; emailVerified: number; isAnonymous: number }>();
  if (!identity || identity.isAnonymous || !identity.emailVerified || identity.email.endsWith(".invalid")) {
    throw new HttpError(403, "verified_email_required", "Sign in with Apple before choosing email updates.");
  }
  await env.DB.prepare(`INSERT INTO email_preferences (user_id, subscribed, consent_version, updated_at)
    VALUES (?1, ?2, ?3, ?4) ON CONFLICT(user_id) DO UPDATE SET
    subscribed = excluded.subscribed, consent_version = excluded.consent_version, updated_at = excluded.updated_at`)
    .bind(user.id, body.subscribed ? 1 : 0, EMAIL_CONSENT_VERSION, Date.now()).run();
  tracker.track("email_preference_updated", { subscribed: body.subscribed });
  return Response.json({ subscribed: body.subscribed });
}
