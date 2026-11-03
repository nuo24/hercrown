import { env } from "cloudflare:workers";
import { beforeEach, describe, expect, it } from "vitest";
import { isPremium, verifyWebhook } from "../src/billing";
import { moveUserData } from "../src/users";
import { api, grantPremium, signInGuest } from "./helpers";

const SECRET = "whsec_dGVzdC13ZWJob29rLXNlY3JldC0xMjM0NTY3ODkw";
const DAY = 86_400_000;

/** Signs a payload exactly like Superwall (Svix / Standard Webhooks). */
async function signed(body: string, id = crypto.randomUUID(), timestamp = Math.floor(Date.now() / 1000), secret = SECRET) {
  const key = await crypto.subtle.importKey("raw", Uint8Array.from(atob(secret.slice(6)), (c) => c.charCodeAt(0)),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const mac = new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${id}.${timestamp}.${body}`)));
  return { "svix-id": id, "svix-timestamp": String(timestamp), "svix-signature": `v1,${btoa(String.fromCharCode(...mac))}` };
}

let n = 0;
function event(type: string, appUserId: string, data: Record<string, unknown> = {}, timestamp = Date.now() + n++) {
  return JSON.stringify({
    object: "event", type, projectId: 1, applicationId: 1, timestamp,
    data: {
      id: `${crypto.randomUUID()}:${type}`, name: type, cancelReason: null, periodType: "NORMAL", store: "APP_STORE",
      environment: "PRODUCTION", productId: "biblescroll.plus.yearly", transactionId: "t1", originalTransactionId: `otx-${appUserId}`,
      originalAppUserId: appUserId, expirationAt: Date.now() + 365 * DAY, purchasedAt: Date.now(), ...data,
    },
  });
}

async function deliver(body: string, headers?: Record<string, string>) {
  const res = await api("/webhooks/superwall", { method: "POST", body, headers: headers ?? (await signed(body)) });
  return { status: res.status, body: await res.json<any>() };
}

let token: string;
let userId: string;
beforeEach(async () => ({ token, userId } = await signInGuest()));
const membership = async () => (await (await api("/me/entitlements", { token })).json<any>());

describe("webhook signature", () => {
  it("accepts a correctly signed delivery and rejects everything else", async () => {
    const body = event("initial_purchase", userId);
    expect((await deliver(body, {})).status).toBe(401); // no headers
    expect((await deliver(body, await signed(body, "id-1", undefined, "whsec_d3Jvbmctc2VjcmV0"))).status).toBe(401); // wrong secret
    expect((await deliver(body + " ", await signed(body))).status).toBe(401); // body changed after signing
    const old = await signed(body, "id-2", Math.floor(Date.now() / 1000) - 600);
    expect((await deliver(body, old)).status).toBe(401); // older than 5 minutes
    expect((await membership()).premium).toBe(false);
    expect((await deliver(body)).status).toBe(200);
    expect((await membership()).premium).toBe(true);
  });

  it("accepts any matching signature among several (secret rotation)", async () => {
    const body = "{}";
    const headers = await signed(body, "id-rot");
    headers["svix-signature"] = `v1,bm90LXRoZS1yaWdodC1vbmU= ${headers["svix-signature"]}`;
    expect(await verifyWebhook(SECRET, new Headers(headers), body)).toBe(true);
  });
});

describe("subscription lifecycle", () => {
  it("trial → renewal → turn off auto-renew → expire", async () => {
    await deliver(event("initial_purchase", userId, { periodType: "TRIAL", expirationAt: Date.now() + 7 * DAY }));
    expect(await membership()).toMatchObject({ premium: true, subscription: { status: "trialing", isTrial: true, willRenew: true } });

    await deliver(event("renewal", userId));
    expect(await membership()).toMatchObject({ premium: true, subscription: { status: "active", isTrial: false } });

    await deliver(event("cancellation", userId, { cancelReason: "UNSUBSCRIBE" }));
    expect(await membership()).toMatchObject({ premium: true, subscription: { status: "active", willRenew: false } });

    await deliver(event("expiration", userId, { expirationAt: Date.now() - 1000 }));
    expect(await membership()).toMatchObject({ premium: false, subscription: { status: "expired" } });
  });

  it("keeps access during a billing problem, and ends it on refund", async () => {
    await deliver(event("initial_purchase", userId));
    await deliver(event("billing_issue", userId, { expirationAt: Date.now() - DAY }));
    expect(await membership()).toMatchObject({ premium: true, subscription: { status: "grace" } });

    await deliver(event("cancellation", userId, { cancelReason: "CUSTOMER_SUPPORT" }));
    expect(await membership()).toMatchObject({ premium: false, subscription: { status: "refunded" } });
  });

  it("processes a redelivered webhook only once", async () => {
    const body = event("initial_purchase", userId);
    const headers = await signed(body, "same-delivery");
    expect((await deliver(body, headers)).body.applied).toBe(true);
    expect((await deliver(body, headers)).body).toMatchObject({ ok: true, duplicate: true });
  });

  it("ignores an older event that arrives late", async () => {
    const t = Date.now();
    await deliver(event("expiration", userId, { expirationAt: t - 1000 }, t));
    await deliver(event("renewal", userId, {}, t - 60_000)); // happened earlier, delivered later
    expect((await membership()).subscription.status).toBe("expired");
  });

  it("marks sandbox purchases (App Review uses sandbox)", async () => {
    await deliver(event("initial_purchase", userId, { environment: "SANDBOX" }));
    expect(await membership()).toMatchObject({ premium: true, subscription: { sandbox: true } });
  });

  it("parks events it can't match to a user and grants nothing", async () => {
    const res = await deliver(event("initial_purchase", "$SuperwallAlias:ABC"));
    expect(res.body).toMatchObject({ ok: true, matched: false, applied: false });
    const parked = await env.DB.prepare("SELECT count(*) AS n FROM unmatched_store_events WHERE app_user_id = '$SuperwallAlias:ABC'").first<any>();
    expect(parked.n).toBe(1);
  });

  it("follows the subscription after a guest links an account", async () => {
    await deliver(event("initial_purchase", userId, { originalTransactionId: "otx-link" }));
    const account = await signInGuest(); // stands in for the Apple account
    await moveUserData(env, userId, account.userId);
    // Later renewals still name the old guest id, but carry the same original transaction.
    await deliver(event("renewal", userId, { originalTransactionId: "otx-link", productId: "biblescroll.plus.weekly" }));
    const res = await (await api("/me/entitlements", { token: account.token })).json<any>();
    expect(res).toMatchObject({ premium: true, subscription: { productId: "biblescroll.plus.weekly" } });
  });
});

describe("Premium gating", () => {
  it("shows plans to everyone but needs Plus to start them", async () => {
    const list = await (await api("/plans", { token })).json<any>();
    expect(list.locked).toBe(true);
    expect(list.plans).toHaveLength(3);

    const blocked = await api("/plans/quiet/start", { method: "POST", body: "{}", token });
    expect(blocked.status).toBe(403);
    expect(await blocked.json()).toMatchObject({ error: "premium_required" });
    expect((await api("/plans/quiet/steps/0/complete", { method: "POST", body: "{}", token })).status).toBe(403);

    await grantPremium(userId);
    expect((await (await api("/plans", { token })).json<any>()).locked).toBe(false);
    expect((await api("/plans/quiet/start", { method: "POST", body: "{}", token })).status).toBe(200);
  });

  it("keeps reading, saving and streaks free", async () => {
    expect((await api("/scripture/kjv/PSA/23", { token })).status).toBe(200);
    expect((await api("/me/saved/PSA.23.1", { method: "PUT", token })).status).toBe(200);
    const reading = { events: [{ id: "free-read-1", localDay: "2026-11-01", timeZone: "UTC" }] };
    expect((await api("/me/reading-events", { method: "POST", body: JSON.stringify(reading), token })).status).toBe(200);
  });

  it("reports membership in GET /me", async () => {
    await grantPremium(userId, "trialing");
    const me = await (await api("/me", { token })).json<any>();
    expect(me.membership).toMatchObject({ premium: true, subscription: { status: "trialing", isTrial: true } });
  });
});

describe("isPremium", () => {
  const row = (status: any, end: number | null) =>
    ({ status, current_period_end: end, product_id: null, will_renew: 1, period_type: null, source: "app_store", environment: null });
  const now = Date.now();
  it("respects period ends and the 16-day grace period", () => {
    expect(isPremium(null)).toBe(false);
    expect(isPremium(row("active", now + DAY), now)).toBe(true);
    expect(isPremium(row("active", now - 1), now)).toBe(false); // missed expiration webhook: still ends on time
    expect(isPremium(row("trialing", null), now)).toBe(true);
    expect(isPremium(row("grace", now - 10 * DAY), now)).toBe(true);
    expect(isPremium(row("grace", now - 17 * DAY), now)).toBe(false);
    expect(isPremium(row("expired", now + DAY), now)).toBe(false);
    expect(isPremium(row("refunded", now + DAY), now)).toBe(false);
  });
});
