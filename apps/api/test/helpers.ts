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
     VALUES (?1, 'plus', 'app_store', 'biblescroll.plus.yearly', ?2, ?3, 1)`,
  ).bind(userId, status, periodEnd).run();
}
