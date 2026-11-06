import { env } from "cloudflare:workers";
import { describe, expect, it } from "vitest";
import { APPLE_STATUS, type AppleSubscription } from "../src/appstore";
import { canReceiveCancellationOffer, recordOfferDecline, reserveReturnOffer } from "../src/return-offers";
import { api, grantPremium, signInGuest } from "./helpers";

const staging = { ...env, APP_ENV: "staging", DB: env.DB } as Env;
const now = Date.now();
const decline = () => new Request("http://localhost/me/return-offer/impression", {
  method: "POST", body: JSON.stringify({ kind: "decline" }),
});

describe("sandbox return offer", () => {
  it("recognizes a canceled paid plan before or after expiration without mistaking a billing failure for cancellation", () => {
    const paid: AppleSubscription = {
      status: APPLE_STATUS.ACTIVE,
      transaction: {
        transactionId: "100", originalTransactionId: "100", bundleId: "com.hercrown.app",
        productId: "hercrown.plus.weekly", expiresDate: now + 1_000,
      },
      renewal: { autoRenewStatus: 0 },
    };
    expect(canReceiveCancellationOffer(paid, now)).toBe(true);
    expect(canReceiveCancellationOffer({ ...paid, renewal: { autoRenewStatus: 1 } }, now)).toBe(false);
    const expired = { ...paid, status: APPLE_STATUS.EXPIRED };
    expect(canReceiveCancellationOffer({ ...expired, renewal: { autoRenewStatus: 0, expirationIntent: 1 } }, now + 2_000)).toBe(true);
    expect(canReceiveCancellationOffer({ ...expired, renewal: { autoRenewStatus: 0, expirationIntent: 2 } }, now + 2_000)).toBe(false);
    expect(canReceiveCancellationOffer({ ...paid, transaction: { ...paid.transaction, offerIdentifier: "trial_return_1999" } }, now)).toBe(false);
  });

  it("requires a main paywall decline and a grace period, with an atomic rolling account limit", async () => {
    const { userId } = await signInGuest();
    const reserve = async (at: number) => (await reserveReturnOffer(decline(), staging, userId, at)).json();
    expect(await reserve(now)).toEqual({ available: false });
    await recordOfferDecline(staging, userId, now);
    expect(await reserve(now + 20 * 60_000 - 1)).toEqual({ available: false });
    const first = now + 20 * 60_000;
    expect(await Promise.all([reserve(first), reserve(first)])).toEqual(expect.arrayContaining([
      { available: true }, { available: false },
    ]));
    expect(await reserve(first + 86_399_999)).toEqual({ available: false });
    expect(await reserve(first + 86_400_000)).toEqual({ available: true });
  });

  it("suppresses the decline offer for active Plus members and trial offers without an Apple transaction", async () => {
    const { userId } = await signInGuest();
    await recordOfferDecline(staging, userId, now);
    await grantPremium(userId);
    expect(await (await reserveReturnOffer(decline(), staging, userId, now + 20 * 60_000)).json()).toEqual({ available: false });
    const trial = new Request("http://localhost/me/return-offer/impression", { method: "POST", body: '{"kind":"trial"}' });
    expect(await (await reserveReturnOffer(trial, staging, userId)).json()).toEqual({ available: false });
  });

  it("keeps the offer endpoints closed outside staging", async () => {
    const { token } = await signInGuest();
    expect((await api("/me/return-offer/decline", { method: "POST", token })).status).toBe(404);
    expect((await api("/me/return-offer/impression", { method: "POST", token, body: '{"kind":"decline"}' })).status).toBe(404);
  });
});
