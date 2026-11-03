// Push notifications through Apple Push Notification service (APNs), plus the app's device registration.
// APNs needs HTTP/2: deployed Workers negotiate it through Cloudflare's proxy; `wrangler dev` can't reach APNs.
import { badRequest, readJson } from "./http";
import { es256Jwt } from "./jwt";
import type { SessionUser } from "./profile";

const HOST = { production: "https://api.push.apple.com", sandbox: "https://api.sandbox.push.apple.com" } as const;
export type PushEnvironment = keyof typeof HOST;

const TOKEN = /^[0-9a-f]{64,200}$/i;

export function pushConfigured(env: Env) {
  return Boolean(env.APNS_KEY_ID && env.APNS_PRIVATE_KEY && env.APPLE_TEAM_ID);
}

/** Provider token: ES256 with the APNs key; Apple accepts it for an hour (we make one per batch). */
export async function apnsJwt(env: Env, now = Date.now()): Promise<string> {
  return es256Jwt(env.APNS_PRIVATE_KEY, { kid: env.APNS_KEY_ID }, { iss: env.APPLE_TEAM_ID, iat: Math.floor(now / 1000) });
}

export interface PushDevice {
  token: string;
  environment: PushEnvironment;
  time_zone: string | null;
}

export interface Alert {
  title: string;
  body: string;
  /** Where the app should go when the notification is tapped. */
  link: string;
  /** Identical ids replace each other on the phone instead of stacking. */
  collapseId: string;
}

/** sent · gone (token no longer valid: forget it) · retry (Apple busy) · failed (our request or key is wrong). */
export type PushResult = "sent" | "gone" | "retry" | "failed";

export async function sendPush(env: Env, jwt: string, device: PushDevice, alert: Alert): Promise<PushResult> {
  let res: Response;
  try {
    res = await fetch(`${HOST[device.environment]}/3/device/${device.token}`, {
      method: "POST",
      headers: {
        authorization: `bearer ${jwt}`,
        "apns-topic": env.APPLE_APP_BUNDLE_IDENTIFIER,
        "apns-push-type": "alert",
        "apns-priority": "10",
        "apns-collapse-id": alert.collapseId,
        "content-type": "application/json",
      },
      body: JSON.stringify({ aps: { alert: { title: alert.title, body: alert.body }, sound: "default" }, link: alert.link }),
      signal: AbortSignal.timeout(10_000),
    });
  } catch (err) {
    console.error("push: APNs unreachable", err);
    return "retry";
  }
  if (res.ok) return "sent";
  const reason = ((await res.json().catch(() => ({}))) as { reason?: string }).reason ?? "";
  if (res.status === 410 || reason === "BadDeviceToken" || reason === "Unregistered" || reason === "DeviceTokenNotForTopic") return "gone";
  if (res.status === 429 || res.status >= 500) return "retry";
  console.error(`push: APNs refused (${res.status} ${reason})`);
  return "failed";
}

// ── Device registration (the app) ───────────────────────────────────────────

/**
 * PUT /me/devices { token: hex APNs token, environment: "production" | "sandbox", timeZone: IANA }
 * Call after notification permission is granted and on every launch (tokens change). Moves the token to this
 * account if another account had it (the phone changed hands or the guest signed in).
 */
export async function registerDevice(request: Request, env: Env, user: SessionUser) {
  const body = await readJson(request);
  const token = typeof body.token === "string" ? body.token.trim().toLowerCase() : "";
  if (!TOKEN.test(token)) throw badRequest("token must be the APNs device token in hex");
  const environment = body.environment ?? "production";
  if (environment !== "production" && environment !== "sandbox") throw badRequest("environment must be production or sandbox");
  const timeZone = typeof body.timeZone === "string" && validTimeZone(body.timeZone) ? body.timeZone : null;
  const t = Date.now();
  await env.DB.prepare(
    `INSERT INTO push_devices (token, user_id, environment, time_zone, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, ?5)
     ON CONFLICT (token) DO UPDATE SET user_id = ?2, environment = ?3, time_zone = COALESCE(?4, push_devices.time_zone), updated_at = ?5`,
  ).bind(token, user.id, environment, timeZone, t).run();
  return Response.json({ registered: true });
}

/** DELETE /me/devices/:token: notifications turned off, or signing out. */
export async function unregisterDevice(env: Env, user: SessionUser, token: string) {
  await env.DB.prepare("DELETE FROM push_devices WHERE token = ?1 AND user_id = ?2").bind(token.toLowerCase(), user.id).run();
  return new Response(null, { status: 204 });
}

export function validTimeZone(tz: string): boolean {
  if (tz.length > 64) return false;
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: tz });
    return true;
  } catch {
    return false;
  }
}
