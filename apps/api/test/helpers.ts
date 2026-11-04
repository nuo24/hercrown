import { exports } from "cloudflare:workers";

export const BASE = "http://localhost:8787";

export function api(path: string, init: RequestInit & { token?: string } = {}) {
  const headers = new Headers(init.headers);
  if (init.token) headers.set("authorization", `Bearer ${init.token}`);
  if (init.body && !headers.has("content-type")) headers.set("content-type", "application/json");
  return exports.default.fetch(new Request(`${BASE}${path}`, { ...init, headers }));
}

/** Signs in as a new guest and returns the bearer token and user id. */
export async function signInGuest() {
  const res = await api("/api/auth/sign-in/anonymous", { method: "POST", body: "{}" });
  if (res.status !== 200) throw new Error(`guest sign-in failed: ${res.status} ${await res.text()}`);
  const token = res.headers.get("set-auth-token");
  if (!token) throw new Error("no set-auth-token header");
  const { user } = await res.json<{ user: { id: string } }>();
  return { token, userId: user.id };
}

/** Gives a user an active Plus subscription, as a verified webhook would. */
export async function grantPremium(userId: string, status = "active", periodEnd = Date.now() + 365 * 86_400_000) {
  const { env } = await import("cloudflare:workers");
  await env.DB.prepare(
    `INSERT OR REPLACE INTO entitlements (user_id, entitlement, source, product_id, status, current_period_end, updated_at)
     VALUES (?1, 'plus', 'app_store', 'hercrown.plus.yearly', ?2, ?3, 1)`,
  ).bind(userId, status, periodEnd).run();
}

export const WEBHOOK_SECRET = "whsec_dGVzdC13ZWJob29rLXNlY3JldC0xMjM0NTY3ODkw";

/** Signs a payload exactly like Superwall (Svix / Standard Webhooks). */
export async function signedHeaders(body: string, id = crypto.randomUUID(), timestamp = Math.floor(Date.now() / 1000), secret = WEBHOOK_SECRET) {
  const key = await crypto.subtle.importKey("raw", Uint8Array.from(atob(secret.slice(6)), (c) => c.charCodeAt(0)),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const mac = new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${id}.${timestamp}.${body}`)));
  return { "svix-id": id, "svix-timestamp": String(timestamp), "svix-signature": `v1,${btoa(String.fromCharCode(...mac))}` };
}

/** Delivers a signed webhook to /webhooks/superwall. */
export async function deliverWebhook(payload: unknown) {
  const body = JSON.stringify(payload);
  const res = await api("/webhooks/superwall", { method: "POST", body, headers: await signedHeaders(body) });
  return { status: res.status, body: await res.json<any>() };
}
