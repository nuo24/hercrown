import { env } from "cloudflare:workers";
import { createExecutionContext, createMessageBatch, getQueueResult } from "cloudflare:test";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { billingEvent, normalizeEvent } from "../src/billing";
import { deliverEvents, type EventRow, linkPerson, Tracker } from "../src/events";
import { api, deliverWebhook, grantPremium, signInGuest } from "./helpers";

const DAY = 86_400_000;
const INSTALL = "0b7e9a52-3c1d-4e8f-9a6b-2d4c8e1f0a35";
const APP = { "x-install-id": INSTALL, "x-app-version": "1.0 (12)", "x-platform": "iOS", "x-build": "appstore" };

/** Captures everything queued for Tinybird. */
function captureEvents() {
  const rows: EventRow[] = [];
  const queued = { metadata: {} } as QueueSendResponse & QueueSendBatchResponse;
  vi.spyOn(env.EVENTS, "send").mockImplementation(async (body) => (rows.push(body as EventRow), queued));
  vi.spyOn(env.EVENTS, "sendBatch").mockImplementation(async (messages) => {
    for (const m of messages) rows.push(m.body as EventRow);
    return queued;
  });
  return rows;
}

/** Events are queued after the response (waitUntil), so wait for them. */
async function waitForEvent(rows: EventRow[], name: string, count = 1) {
  await vi.waitFor(() => expect(rows.filter((r) => r.event === name).length).toBeGreaterThanOrEqual(count), { timeout: 2000 });
  return rows.filter((r) => r.event === name);
}

const send = (events: unknown[], token?: string, headers: Record<string, string> = APP) =>
  api("/events", { method: "POST", body: JSON.stringify({ events }), token, headers });

let rows: EventRow[];
let token: string;
let userId: string;
beforeEach(async () => {
  ({ token, userId } = await signInGuest());
  rows = captureEvents();
});
afterEach(() => vi.restoreAllMocks());

describe("POST /events (from the app)", () => {
  it("queues listed events with the app's context and the person id", async () => {
    const id = crypto.randomUUID();
    const res = await send([{ id, name: "paywall_viewed", at: Date.now() - 1000, props: { placement: "onboarding_complete", variant: "A" } }], token);
    expect(res.status).toBe(202);
    expect(await res.json()).toEqual({ accepted: 1, rejected: [] });
    expect(rows).toHaveLength(1);
    expect(rows[0]).toMatchObject({
      event_id: id, event: "paywall_viewed", source: "ios", person_id: userId, install_id: INSTALL,
      app_version: "1.0 (12)", platform: "ios", environment: "dev", sandbox: 0,
    });
    expect(JSON.parse(rows[0]!.props)).toEqual({ placement: "onboarding_complete", variant: "A" });
    expect(rows[0]!.timestamp).toMatch(/^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d{3}$/);
  });

  it("works before sign-in, for app_opened", async () => {
    const res = await send([{ id: crypto.randomUUID(), name: "app_opened" }]);
    expect(res.status).toBe(202);
    expect(rows[0]).toMatchObject({ event: "app_opened", person_id: null, install_id: INSTALL });
  });

  it("refuses purchase and other server-only events, bad ids and stale events; keeps the rest", async () => {
    const res = await send([
      { id: crypto.randomUUID(), name: "trial_started", props: { product_id: "biblescroll.plus.yearly" } },
      { id: crypto.randomUUID(), name: "subscription_started" },
      { id: crypto.randomUUID(), name: "onboarding_completed" },
      { id: "not-a-uuid", name: "paywall_declined" },
      { id: crypto.randomUUID(), name: "paywall_declined", at: Date.now() - 40 * DAY },
      { id: crypto.randomUUID(), name: "decline_offer_viewed", at: Date.now() + DAY, props: { placement: "transaction_abandon" } },
    ], token);
    expect(await res.json()).toEqual({
      accepted: 1,
      rejected: [
        { index: 0, reason: "unknown_event" }, { index: 1, reason: "unknown_event" }, { index: 2, reason: "unknown_event" },
        { index: 3, reason: "invalid_id" }, { index: 4, reason: "too_old" },
      ],
    });
    expect(rows.map((r) => r.event)).toEqual(["decline_offer_viewed"]);
    expect(Date.parse(rows[0]!.timestamp + "Z")).toBeLessThanOrEqual(Date.now()); // future clock clamped
  });

  it("keeps only the listed props, with the right types", async () => {
    await send([{
      id: crypto.randomUUID(), name: "onboarding_step",
      props: { step: "topics", index: 3, email: "a@b.co", name: "Hannah", topics: ["anxiety"], extra: { x: 1 } },
    }], token);
    expect(JSON.parse(rows[0]!.props)).toEqual({ step: "topics", index: 3 });
    await send([{ id: crypto.randomUUID(), name: "onboarding_step", props: { step: 4, index: "4" } }], token);
    expect(JSON.parse(rows[1]!.props)).toEqual({});
  });

  it("marks TestFlight and debug builds as sandbox", async () => {
    await send([{ id: crypto.randomUUID(), name: "app_opened" }], token, { ...APP, "x-build": "testflight" });
    expect(rows[0]!.sandbox).toBe(1);
  });

  it("rejects malformed batches", async () => {
    expect((await send([], token)).status).toBe(400);
    expect((await send(Array.from({ length: 51 }, () => ({ id: crypto.randomUUID(), name: "app_opened" })), token)).status).toBe(400);
    expect((await api("/events", { method: "POST", body: "nope", token })).status).toBe(400);
    expect(rows).toHaveLength(0);
  });
});

describe("server events", () => {
  it("counts onboarding completion once per person", async () => {
    await api("/me/onboarding/complete", { method: "POST", token, headers: APP });
    const [first] = await waitForEvent(rows, "onboarding_completed");
    expect(first).toMatchObject({ event_id: `onboarding_completed:${userId}`, person_id: userId, install_id: INSTALL, source: "api" });
    await api("/me/onboarding/complete", { method: "POST", token });
    await new Promise((r) => setTimeout(r, 50));
    expect(rows.filter((r) => r.event === "onboarding_completed")).toHaveLength(1);
  });

  it("emits feature events without Scripture references", async () => {
    await grantPremium(userId);
    await api("/me/saved/PSA.23.1", { method: "PUT", token });
    await api("/me/reading-events", {
      method: "POST", token,
      body: JSON.stringify({ events: [{ id: "read-psa-23-x", localDay: "2026-11-02", timeZone: "UTC", ref: "PSA.23.1" }] }),
    });
    await api("/plans/peace/start", { method: "POST", token });
    await waitForEvent(rows, "plan_started");
    await waitForEvent(rows, "passage_read");
    await waitForEvent(rows, "passage_saved");
    expect(JSON.stringify(rows)).not.toMatch(/PSA|Psalm/);
  });

  it("does not emit when the action failed", async () => {
    await api("/plans/peace/start", { method: "POST", token }); // no Plus → 403
    await new Promise((r) => setTimeout(r, 50));
    expect(rows.filter((r) => r.event === "plan_started")).toHaveLength(0);
  });

  it("sends server errors as error events", async () => {
    const tracker = new Tracker(env);
    const request = new Request("http://x/me");
    await tracker.emit("error", { source: "api", route: "/me", message: "boom" });
    tracker.error(request, new URL(request.url), new Error("kaput"));
    const errors = await waitForEvent(rows, "error", 2);
    expect(JSON.parse(errors[1]!.props)).toMatchObject({ source: "api", method: "GET", route: "/me", message: "Error: kaput" });
  });
});

describe("billing events (from verified webhooks only)", () => {
  const v2 = (type: string, appUserId: string, eventData: Record<string, unknown> = {}, storeEventId = `${crypto.randomUUID()}:${type}`) => ({
    id: `evt_${crypto.randomUUID()}`, api_version: "2026-09-22", type, occurred_at: Date.now(), project_id: "1",
    app_user_id: appUserId,
    event_data: {
      id: storeEventId, name: type, store: "APP_STORE", environment: "PRODUCTION", transaction_id: `t-${crypto.randomUUID()}`,
      original_transaction_id: `otx-a-${appUserId}`, product_id: "biblescroll.plus.yearly", period_type: "NORMAL",
      expiration_at: Date.now() + 365 * DAY, price: 29.99, proceeds: 25.49, ...eventData,
    },
    subscription: { is_active: true, will_renew: true },
    subscriber: { app_user_id: appUserId, aliases: [appUserId] },
  });

  it("trial start → conversion, once each, attributed to the person, with no profile data", async () => {
    await api("/me/profile", { method: "PATCH", token, body: JSON.stringify({ displayName: "Hannah" }) });
    await api("/me/preferences", { method: "PATCH", token, body: JSON.stringify({ intention: "peace" }) });

    const trial = v2("initial_purchase", userId, { period_type: "TRIAL", price: 0, proceeds: 0 });
    await deliverWebhook(trial);
    await deliverWebhook({ ...trial, id: `evt_${crypto.randomUUID()}` }); // same store event, delivered again
    const [started] = await waitForEvent(rows, "trial_started");
    expect(started).toMatchObject({ event_id: `trial_started:otx-a-${userId}`, person_id: userId, source: "api", sandbox: 0 });
    expect(JSON.parse(started!.props)).toEqual({
      product_id: "biblescroll.plus.yearly", period_type: "TRIAL", store: "APP_STORE", price: 0, proceeds: 0,
    });

    await deliverWebhook(v2("renewal", userId, { is_trial_conversion: true }));
    const [converted] = await waitForEvent(rows, "trial_converted");
    expect(converted).toMatchObject({ event_id: `trial_converted:otx-a-${userId}`, person_id: userId });
    expect(JSON.parse(converted!.props)).toMatchObject({ price: 29.99, proceeds: 25.49 });

    await deliverWebhook(v2("renewal", userId));
    await waitForEvent(rows, "subscription_renewed");

    // Two deliveries with different svix ids → two rows with one event_id; Tinybird keeps one.
    const ids = rows.filter((r) => r.event === "trial_started").map((r) => r.event_id);
    expect(new Set(ids).size).toBe(1);
    expect(JSON.stringify(rows)).not.toMatch(/Hannah|peace/);
  });

  it("the decline offer, refunds and sandbox purchases", async () => {
    await deliverWebhook(v2("initial_purchase", userId, {
      product_id: "biblescroll.plus.yearly.offer", period_type: "INTRO", price: 19.99, proceeds: 16.99, environment: "SANDBOX",
    }));
    const [started] = await waitForEvent(rows, "subscription_started");
    expect(started).toMatchObject({ sandbox: 1 });
    expect(JSON.parse(started!.props)).toMatchObject({ product_id: "biblescroll.plus.yearly.offer", period_type: "INTRO" });

    await deliverWebhook(v2("refund", userId, { price: -19.99, proceeds: -16.99, transaction_id: "t-refund-1" }));
    const [refund] = await waitForEvent(rows, "refunded");
    expect(refund!.event_id).toBe("refunded:t-refund-1");
  });

  it("the same store event has the same id in webhook V1 and V2", () => {
    const v1 = normalizeEvent({ type: "initial_purchase", timestamp: 1, data: {
      id: "abc:initial_purchase", periodType: "TRIAL", originalTransactionId: "otx-9", originalAppUserId: "u", isTrialConversion: false,
    } })!;
    const v2e = normalizeEvent(v2("initial_purchase", "u", { id: "abc:initial_purchase", period_type: "TRIAL", original_transaction_id: "otx-9" }))!;
    expect(billingEvent(v1, "superwall:1")!.id).toBe("trial_started:otx-9");
    expect(billingEvent(v2e, "superwall:2")!.id).toBe("trial_started:otx-9");
    const cancel1 = normalizeEvent({ type: "cancellation", timestamp: 1, data: { id: "def:cancellation" } })!;
    expect(billingEvent(cancel1, "superwall:3")!.id).toBe("subscription_cancelled:def:cancellation");
  });

  it("records an unmatched purchase without a person", async () => {
    await deliverWebhook(v2("initial_purchase", "someone-we-dont-know", { period_type: "TRIAL" }));
    const [started] = await waitForEvent(rows, "trial_started");
    expect(started!.person_id).toBeNull();
  });
});

describe("restore outcomes", () => {
  it("records what happened, including Apple being unavailable", async () => {
    vi.spyOn(globalThis, "fetch").mockImplementation(async () => Response.json({ errorCode: 4040010 }, { status: 404 }));
    await api("/me/restore", { method: "POST", token, body: JSON.stringify({ transactionId: "2000000000000001" }) });
    const [done] = await waitForEvent(rows, "restore_completed");
    expect(JSON.parse(done!.props)).toEqual({ restored: false, reason: "not_found", transferred: false, already_active: false });

    vi.spyOn(globalThis, "fetch").mockImplementation(async () => new Response("down", { status: 503 }));
    const res = await api("/me/restore", { method: "POST", token, body: JSON.stringify({ transactionId: "2000000000000001" }) });
    expect(res.status).toBe(503);
    const [failed] = await waitForEvent(rows, "restore_failed");
    expect(JSON.parse(failed!.props)).toEqual({ error: "restore_unavailable" });
  });
});

describe("one person across a guest → account link", () => {
  it("a new account continues the guest's analytics id", async () => {
    const account = await signInGuest(); // stands in for the Apple account created by the link
    await linkPerson(env, userId, account.userId, true);
    await api("/me/onboarding/complete", { method: "POST", token: account.token });
    const [done] = await waitForEvent(rows, "onboarding_completed");
    expect(done).toMatchObject({ person_id: userId, event_id: `onboarding_completed:${userId}` });
  });

  it("an existing account keeps its id and records the alias", async () => {
    const account = await signInGuest();
    await linkPerson(env, userId, account.userId, false);
    const [linked] = await waitForEvent(rows, "account_linked");
    expect(linked).toMatchObject({ person_id: account.userId });
    expect(JSON.parse(linked!.props)).toEqual({ previous_person_id: userId });
  });

  it("the id is deleted with the account", async () => {
    const account = await signInGuest();
    await linkPerson(env, userId, account.userId, true);
    expect(await api("/api/auth/delete-user", { method: "POST", token: account.token, body: "{}" }).then((r) => r.status)).toBe(200);
    expect(await env.DB.prepare("SELECT 1 FROM analytics_ids WHERE user_id = ?1").bind(account.userId).first()).toBeNull();
  });
});

describe("delivery to Tinybird", () => {
  const row = (event: string): EventRow => new Tracker(env).row(event, crypto.randomUUID(), 0, 0, "p1", "api", {});
  const run = async (status: number | "throw", token = "p.test-token") => {
    const fetchSpy = vi.spyOn(globalThis, "fetch").mockImplementation(async () => {
      if (status === "throw") throw new Error("network");
      return new Response("{}", { status });
    });
    const batch = createMessageBatch<EventRow>("bible-scroll-events-dev", [
      { id: "m1", timestamp: new Date(), attempts: 1, body: row("app_opened") },
      { id: "m2", timestamp: new Date(), attempts: 1, body: row("paywall_viewed") },
    ]);
    const ctx = createExecutionContext();
    await deliverEvents(batch, { ...env, TINYBIRD_TOKEN: token, TINYBIRD_HOST: "https://api.tinybird.test" } as unknown as Env);
    return { result: await getQueueResult(batch, ctx), fetchSpy };
  };

  it("posts NDJSON with the token and acknowledges", async () => {
    const { result, fetchSpy } = await run(202);
    expect(result.ackAll).toBe(true);
    const [url, init] = fetchSpy.mock.calls[0]!;
    expect(String(url)).toBe("https://api.tinybird.test/v0/events?name=events");
    expect((init!.headers as Record<string, string>).authorization).toBe("Bearer p.test-token");
    const lines = String(init!.body).split("\n").map((l) => JSON.parse(l));
    expect(lines.map((l) => l.event)).toEqual(["app_opened", "paywall_viewed"]);
  });

  it("retries outages, rate limits and auth errors; drops rows Tinybird rejects", async () => {
    for (const status of [500, 429, 401, "throw"] as const) {
      const { result } = await run(status);
      expect(result.retryBatch.retry, String(status)).toBe(true);
      vi.restoreAllMocks();
    }
    const { result } = await run(400);
    expect(result.ackAll).toBe(true);
  });

  it("logs and drops without a token (local dev)", async () => {
    const { result, fetchSpy } = await run(202, "");
    expect(result.ackAll).toBe(true);
    expect(fetchSpy).not.toHaveBeenCalled();
  });
});
