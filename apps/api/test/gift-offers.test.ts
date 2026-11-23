import { env } from "cloudflare:workers";
import { beforeEach, describe, expect, it } from "vitest";
import { claimGift, giftStatus, GIFT_DELAY_MS, scheduleGift } from "../src/gift-offers";
import { Tracker } from "../src/events";
import { api, signInGuest } from "./helpers";

let token: string, userId: string;
const now = 1_800_000_000_000;
beforeEach(async () => ({ token, userId } = await signInGuest()));

describe("next-day gift invitation", () => {
  it("requires authentication and has nothing to claim without a decline", async () => {
    for (const path of ["/me/gift-offer", "/me/gift-offer/claim", "/me/gift-offer/decline"]) {
      expect((await api(path, { method: path.endsWith("gift-offer") ? "GET" : "POST" })).status).toBe(401);
    }
    expect(await (await giftStatus(env, userId, now)).json()).toEqual({ due: false });
    expect(await (await claimGift(env, userId, now)).json()).toEqual({ available: false });
  });
  it("waits a full 24 hours, does not restart the clock and consumes no impression on a read", async () => {
    const tracker = new Tracker(env); tracker.userId = userId;
    await scheduleGift(env, userId, tracker, now);
    await scheduleGift(env, userId, tracker, now + 1000);
    expect(await (await giftStatus(env, userId, now + GIFT_DELAY_MS - 1)).json()).toEqual({ due: false });
    expect(await (await claimGift(env, userId, now + GIFT_DELAY_MS - 1)).json()).toEqual({ available: false });
    expect(await (await giftStatus(env, userId, now + GIFT_DELAY_MS)).json()).toEqual({ due: true });
    expect(await (await giftStatus(env, userId, now + GIFT_DELAY_MS)).json()).toEqual({ due: true });
    const claims = await Promise.all([claimGift(env, userId, now + GIFT_DELAY_MS), claimGift(env, userId, now + GIFT_DELAY_MS)]);
    const values = await Promise.all(claims.map(r => r.json() as Promise<{available: boolean}>));
    expect(values.filter(x => x.available)).toHaveLength(1);
    expect(await (await giftStatus(env, userId, now + 10 * GIFT_DELAY_MS)).json()).toEqual({ due: false });
    await scheduleGift(env, userId, tracker, now + 10 * GIFT_DELAY_MS);
    expect(await (await claimGift(env, userId, now + 20 * GIFT_DELAY_MS)).json()).toEqual({ available: false });
  });
  it("excludes accounts that subscribed after declining and isolates another account", async () => {
    const tracker = new Tracker(env); tracker.userId = userId;
    await scheduleGift(env, userId, tracker, Date.now() - GIFT_DELAY_MS);
    await env.DB.prepare(`INSERT INTO entitlements
      (user_id, entitlement, source, product_id, status, current_period_end, original_transaction_id, updated_at)
      VALUES (?1,'plus','app_store','hercrown.plus.yearly','active',?2,'gift-test-transaction',?3)`)
      .bind(userId, Date.now() + GIFT_DELAY_MS, Date.now()).run();
    expect(await (await giftStatus(env, userId)).json()).toEqual({ due: false });
    expect(await (await claimGift(env, userId)).json()).toEqual({ available: false });
    const other = await signInGuest();
    expect(await (await giftStatus(env, other.userId)).json()).toEqual({ due: false });
  });
  it("removes its account state when the account is deleted", async () => {
    await scheduleGift(env, userId, new Tracker(env), now);
    expect((await api("/api/auth/delete-anonymous-user", { method: "POST", token, body: "{}" })).status).toBe(200);
    expect(await env.DB.prepare("SELECT count(*) AS n FROM gift_offers WHERE user_id=?1").bind(userId).first()).toEqual({ n: 0 });
  });
});
