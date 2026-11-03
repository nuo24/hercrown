import { env } from "cloudflare:workers";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { appStoreJwt, decodeJws, subscriptionStatuses } from "../src/appstore";
import { deleteUserData } from "../src/users";
import { api, deliverWebhook, signInGuest } from "./helpers";

const DAY = 86_400_000;
const BUNDLE = "com.biblescroll.app";
const PROD = "https://api.storekit.apple.com";
const SANDBOX = "https://api.storekit-sandbox.apple.com";

// ── Fake App Store ──────────────────────────────────────────────────────────

const b64url = (v: unknown) => btoa(JSON.stringify(v)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
const jws = (payload: unknown) => `${b64url({ alg: "ES256", x5c: [] })}.${b64url(payload)}.sig`;

interface FakeSub {
  status: number;
  otx?: string;
  productId?: string;
  bundleId?: string;
  expiresDate?: number;
  trial?: boolean;
  autoRenew?: 0 | 1;
  revocationDate?: number;
  graceEnd?: number;
  environment?: "Production" | "Sandbox";
}

function statusResponse(subs: FakeSub[], bundleId = BUNDLE, environment = "Production") {
  return Response.json({
    environment,
    bundleId,
    data: [{
      subscriptionGroupIdentifier: "21000000",
      lastTransactions: subs.map((s) => ({
        originalTransactionId: s.otx ?? OTX,
        status: s.status,
        signedTransactionInfo: jws({
          transactionId: "2000000000000099", originalTransactionId: s.otx ?? OTX,
          bundleId: s.bundleId ?? BUNDLE, productId: s.productId ?? "biblescroll.plus.yearly",
          type: "Auto-Renewable Subscription", expiresDate: s.expiresDate ?? Date.now() + 300 * DAY,
          revocationDate: s.revocationDate, environment: s.environment ?? environment,
          ...(s.trial ? { offerType: 1, offerDiscountType: "FREE_TRIAL" } : {}),
        }),
        signedRenewalInfo: jws({ autoRenewStatus: s.autoRenew ?? 1, gracePeriodExpiresDate: s.graceEnd }),
      })),
    }],
  });
}

/** Routes App Store calls: `prod`/`sandbox` give the response for each environment (default 404 = unknown there). */
function fakeAppStore(routes: { prod?: () => Response; sandbox?: () => Response }) {
  const notFound = () => Response.json({ errorCode: 4040010, errorMessage: "Transaction id not found." }, { status: 404 });
  return vi.spyOn(globalThis, "fetch").mockImplementation(async (input) => {
    const url = String(input instanceof Request ? input.url : input);
    if (url.startsWith(PROD)) return (routes.prod ?? notFound)();
    if (url.startsWith(SANDBOX)) return (routes.sandbox ?? notFound)();
    throw new Error(`unexpected fetch ${url}`);
  });
}

// ── Helpers ─────────────────────────────────────────────────────────────────

let token: string;
let userId: string;
let OTX: string; // each test gets its own Apple subscription (test storage is shared within this file)
beforeEach(async () => {
  ({ token, userId } = await signInGuest());
  OTX = String(3_000_000_000_000_000 + Math.floor(Math.random() * 1e9));
});
afterEach(() => vi.restoreAllMocks());

async function restore(transactionId: unknown = OTX, as = token) {
  const res = await api("/me/restore", { method: "POST", body: JSON.stringify({ transactionId }), token: as });
  return { status: res.status, body: await res.json<any>() };
}

const entitlementRows = (otx: string) =>
  env.DB.prepare("SELECT user_id, status FROM entitlements WHERE original_transaction_id = ?1").bind(otx).all<any>();

// ── Tests ───────────────────────────────────────────────────────────────────

describe("App Store Server API requests", () => {
  it("signs an ES256 JWT with the documented claims", async () => {
    const jwt = await appStoreJwt(env, Date.UTC(2026, 10, 3) );
    const [h, p, sig] = jwt.split(".");
    expect(decodeJws<any>(`x.${h}.x`)).toEqual({ alg: "ES256", kid: "TESTKEY123", typ: "JWT" });
    const claims = decodeJws<any>(jwt);
    expect(claims).toMatchObject({ iss: "test-issuer-0000", aud: "appstoreconnect-v1", bid: BUNDLE });
    expect(claims.exp - claims.iat).toBeLessThanOrEqual(3600);

    const pem = env.TEST_APP_STORE_PUBLIC_KEY.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
    const key = await crypto.subtle.importKey("spki", Uint8Array.from(atob(pem), (c) => c.charCodeAt(0)),
      { name: "ECDSA", namedCurve: "P-256" }, false, ["verify"]);
    const raw = Uint8Array.from(atob(sig.replace(/-/g, "+").replace(/_/g, "/").padEnd(88, "=")), (c) => c.charCodeAt(0));
    const ok = await crypto.subtle.verify({ name: "ECDSA", hash: "SHA-256" }, key, raw, new TextEncoder().encode(`${h}.${p}`));
    expect(ok).toBe(true);
  });

  it("sends the JWT to Apple's subscription status endpoint", async () => {
    const spy = fakeAppStore({ prod: () => statusResponse([{ status: 1 }]) });
    await restore();
    const [url, init] = spy.mock.calls[0] as [string, RequestInit];
    expect(url).toBe(`${PROD}/inApps/v1/subscriptions/${OTX}`);
    expect(new Headers(init.headers).get("authorization")).toMatch(/^Bearer [\w-]+\.[\w-]+\.[\w-]+$/);
  });
});

describe("restoring", () => {
  it("restores an active yearly subscription", async () => {
    fakeAppStore({ prod: () => statusResponse([{ status: 1, autoRenew: 0 }]) });
    const { status, body } = await restore();
    expect(status).toBe(200);
    expect(body).toMatchObject({
      restored: true, transferred: false,
      membership: { premium: true, subscription: { status: "active", productId: "biblescroll.plus.yearly", willRenew: false, sandbox: false } },
    });
  });

  it("restores a free trial as a trial", async () => {
    fakeAppStore({ prod: () => statusResponse([{ status: 1, trial: true, expiresDate: Date.now() + 5 * DAY }]) });
    expect((await restore()).body.membership.subscription).toMatchObject({ status: "trialing", isTrial: true });
  });

  it("falls back to the sandbox (App Review / TestFlight) and marks it", async () => {
    fakeAppStore({ sandbox: () => statusResponse([{ status: 1 }], BUNDLE, "Sandbox") });
    expect((await restore()).body).toMatchObject({ restored: true, membership: { subscription: { sandbox: true } } });
  });

  it("ignores the sandbox when it isn't allowed", async () => {
    fakeAppStore({ sandbox: () => statusResponse([{ status: 1 }], BUNDLE, "Sandbox") });
    expect(await subscriptionStatuses({ ...env, APP_STORE_ALLOW_SANDBOX: "false" } as unknown as Env, "2000000000000001")).toBeNull();
  });

  it("keeps access during Apple's billing grace period", async () => {
    fakeAppStore({ prod: () => statusResponse([{ status: 4, expiresDate: Date.now() - DAY, graceEnd: Date.now() + 5 * DAY }]) });
    expect((await restore()).body).toMatchObject({ restored: true, membership: { premium: true, subscription: { status: "grace" } } });
  });

  it("explains why there is nothing to restore", async () => {
    const cases: [FakeSub[] | null, string, string?][] = [
      [null, "not_found"],
      [[{ status: 2, expiresDate: Date.now() - DAY }], "expired"],
      [[{ status: 3, expiresDate: Date.now() - DAY }], "billing_retry"],
      [[{ status: 5, revocationDate: Date.now() - DAY }], "revoked"],
      [[{ status: 1, productId: "com.other.product" }], "no_plus_subscription"],
      [[{ status: 1 }], "wrong_app", "com.someone.else"],
    ];
    for (const [subs, reason, bundle] of cases) {
      vi.restoreAllMocks();
      fakeAppStore({ prod: subs ? () => statusResponse(subs, bundle ?? BUNDLE) : undefined });
      const { status, body } = await restore();
      expect(status, reason).toBe(200);
      expect(body, reason).toMatchObject({ restored: false, reason, membership: { premium: false } });
    }
  });

  it("picks the subscription that grants access when Apple returns several", async () => {
    fakeAppStore({ prod: () => statusResponse([
      { status: 2, otx: "2000000000000005", expiresDate: Date.now() - DAY },
      { status: 1, otx: "2000000000000006", productId: "biblescroll.plus.weekly", expiresDate: Date.now() + 6 * DAY },
    ]) });
    expect((await restore()).body.membership.subscription.productId).toBe("biblescroll.plus.weekly");
  });

  it("is safe to repeat", async () => {
    fakeAppStore({ prod: () => statusResponse([{ status: 1 }]) });
    await restore();
    const again = await restore();
    expect(again.body).toMatchObject({ restored: true, transferred: false });
    expect((await entitlementRows(OTX)).results).toEqual([{ user_id: userId, status: "active" }]);
  });
});

describe("ownership", () => {
  it("moves the subscription to the account that restores it, and later webhooks follow", async () => {
    const otx = "2000000000000777";
    const original = await signInGuest(); // e.g. the old install
    fakeAppStore({ prod: () => statusResponse([{ status: 1, otx }]) });
    await restore(otx, original.token);

    const { body } = await restore(otx); // new install, same Apple ID
    expect(body).toMatchObject({ restored: true, transferred: true, membership: { premium: true } });
    expect((await api("/me/entitlements", { token: original.token }).then((r) => r.json<any>())).premium).toBe(false);
    expect((await entitlementRows(otx)).results).toEqual([{ user_id: userId, status: "active" }]);
    const log = await env.DB.prepare("SELECT from_user_id, to_user_id FROM entitlement_transfers WHERE original_transaction_id = ?1").bind(otx).all();
    expect(log.results).toEqual([{ from_user_id: original.userId, to_user_id: userId }]);

    // Superwall still knows the old user id, but the original transaction routes later events here.
    vi.restoreAllMocks();
    const res = await deliverWebhook({
      id: "evt_after_restore", type: "cancellation", occurred_at: Date.now() + 1000, app_user_id: original.userId,
      event_data: { name: "cancellation", store: "APP_STORE", environment: "PRODUCTION", original_transaction_id: otx, product_id: "biblescroll.plus.yearly", period_type: "NORMAL" },
      subscription: { will_renew: false, is_active: true },
    });
    expect(res.body).toMatchObject({ applied: true });
    const mine = await api("/me/entitlements", { token }).then((r) => r.json<any>());
    expect(mine).toMatchObject({ premium: true, subscription: { willRenew: false } });
    expect((await api("/me/entitlements", { token: original.token }).then((r) => r.json<any>())).premium).toBe(false);
  });

  it("doesn't replace a different subscription that already runs longer", async () => {
    await env.DB.prepare(
      `INSERT INTO entitlements (user_id, entitlement, source, product_id, status, current_period_end, original_transaction_id, updated_at)
       VALUES (?1, 'plus', 'app_store', 'biblescroll.plus.yearly', 'active', ?2, '2000000000000888', 1)`,
    ).bind(userId, Date.now() + 200 * DAY).run();
    const other = await signInGuest();
    await env.DB.prepare(
      `INSERT INTO entitlements (user_id, entitlement, source, product_id, status, current_period_end, original_transaction_id, updated_at)
       VALUES (?1, 'plus', 'app_store', 'biblescroll.plus.weekly', 'active', ?2, '2000000000000999', 1)`,
    ).bind(other.userId, Date.now() + 5 * DAY).run();

    fakeAppStore({ prod: () => statusResponse([{ status: 1, otx: "2000000000000999", productId: "biblescroll.plus.weekly", expiresDate: Date.now() + 5 * DAY }]) });
    expect((await restore("2000000000000999")).body).toMatchObject({ restored: true, alreadyActive: true, transferred: false });
    expect((await entitlementRows("2000000000000999")).results).toEqual([{ user_id: other.userId, status: "active" }]); // untouched
    expect((await entitlementRows("2000000000000888")).results).toEqual([{ user_id: userId, status: "active" }]);
  });

  it("removes transfer history when an account is deleted", async () => {
    const original = await signInGuest();
    fakeAppStore({ prod: () => statusResponse([{ status: 1, otx: "2000000000000555" }]) });
    await restore("2000000000000555", original.token);
    await restore("2000000000000555");
    await deleteUserData(env, userId);
    const left = await env.DB.prepare("SELECT count(*) AS n FROM entitlement_transfers WHERE to_user_id = ?1").bind(userId).first<any>();
    expect(left.n).toBe(0);
  });
});

describe("failures", () => {
  it("rejects malformed transaction ids without calling Apple", async () => {
    const spy = fakeAppStore({});
    for (const id of ["", "abc", "12-34", 12345, "1".repeat(33)]) expect((await restore(id)).status, String(id)).toBe(400);
    expect(spy).not.toHaveBeenCalled();
  });

  it("returns a retryable 503 when Apple is unreachable, busy or rejects our key", async () => {
    for (const fail of [() => { throw new TypeError("network"); }, () => new Response("busy", { status: 503 }), () => new Response("", { status: 401 })]) {
      vi.restoreAllMocks();
      fakeAppStore({ prod: fail as () => Response });
      const { status, body } = await restore();
      expect(status).toBe(503);
      expect(body.error).toBe("restore_unavailable");
    }
  });

  it("returns 503 when restore isn't configured", async () => {
    await expect(subscriptionStatuses({ ...env, APP_STORE_KEY_ID: "" }, "1")).rejects.toMatchObject({ status: 503 });
  });

  it("limits attempts per account", async () => {
    fakeAppStore({ prod: () => statusResponse([{ status: 1 }]) });
    const statuses = [];
    for (let i = 0; i < 12; i++) statuses.push((await restore()).status);
    expect(statuses.slice(0, 10).every((s) => s === 200)).toBe(true);
    expect(statuses.at(-1)).toBe(429);
  });
});
