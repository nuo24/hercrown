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
