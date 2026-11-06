import { APPLE_STATUS, subscriptionStatuses, type AppleSubscription } from "./appstore";
import { ENTITLEMENT, entitlementFor } from "./billing";
import { badRequest, HttpError, notFound, readJson } from "./http";
import { es256Jwt } from "./jwt";

const DAY_MS = 86_400_000;
// Offer on a subsequent open, with at least twenty minutes for free reading.
const SANDBOX_DECLINE_GRACE_MS = 20 * 60_000;
const YEARLY = "hercrown.plus.yearly";
const RETURN_OFFER_ID = "trial_return_1999";

function stagingOnly(env: Env) {
  if (env.APP_ENV !== "staging") throw notFound("Offer unavailable");
}

export async function recordOfferDecline(env: Env, userId: string, now = Date.now()) {
  stagingOnly(env);
  if (!(await entitlementFor(env, userId)).premium) {
    await env.DB.prepare(`
      INSERT INTO return_offers (user_id, declined_at) VALUES (?1, ?2)
      ON CONFLICT (user_id) DO UPDATE SET declined_at = COALESCE(return_offers.declined_at, excluded.declined_at)
    `).bind(userId, now).run();
  }
  return Response.json({ ok: true });
}

export async function reserveReturnOffer(request: Request, env: Env, userId: string, now = Date.now()) {
  stagingOnly(env);
  const { kind } = await readJson(request);
  if (kind !== "trial" && kind !== "decline") throw badRequest("Unknown offer kind");
  const existing = await env.DB.prepare("SELECT declined_at, shown_at FROM return_offers WHERE user_id = ?1")
    .bind(userId).first<{ declined_at: number | null; shown_at: number | null }>();
  const cutoff = now - SANDBOX_DECLINE_GRACE_MS;
  const cooldown = now - DAY_MS;
  const unavailable = () => Response.json({ available: false });
  if (existing?.shown_at != null && existing.shown_at > cooldown) return unavailable();
  if (kind === "decline") {
    if (existing?.declined_at == null || existing.declined_at > cutoff || (await entitlementFor(env, userId)).premium) {
      return unavailable();
    }
  } else if (!(await eligibleCancellation(env, userId, now))) {
    return unavailable();
  }

  // One conditional write: concurrent opens on two phones cannot both reserve an impression.
  const reserved = await env.DB.prepare(`
    INSERT INTO return_offers (user_id, shown_at) VALUES (?1, ?2)
    ON CONFLICT (user_id) DO UPDATE SET shown_at = excluded.shown_at
      WHERE return_offers.shown_at IS NULL OR return_offers.shown_at <= ?3
    RETURNING shown_at
  `).bind(userId, now, cooldown).first();
  return Response.json({ available: reserved !== null });
}

export function canReceiveCancellationOffer({ status, transaction, renewal }: AppleSubscription, now: number) {
  if (renewal?.autoRenewStatus !== 0 || transaction.revocationDate != null ||
      transaction.offerIdentifier === RETURN_OFFER_ID || transaction.expiresDate == null) return false;
  if (status === APPLE_STATUS.ACTIVE) return transaction.expiresDate > now;
  // Apple expiration intent 1 means the subscriber canceled auto-renewal.
  return status === APPLE_STATUS.EXPIRED && transaction.expiresDate <= now && renewal.expirationIntent === 1;
}

async function eligibleCancellation(env: Env, userId: string, now = Date.now()) {
  const row = await env.DB.prepare(
    "SELECT original_transaction_id FROM entitlements WHERE user_id = ?1 AND entitlement = ?2 AND environment = 'SANDBOX'",
  ).bind(userId, ENTITLEMENT).first<{ original_transaction_id: string | null }>();
  const originalId = row?.original_transaction_id;
  const result = originalId ? await subscriptionStatuses(env, originalId) : null;
  if (result?.environment !== "sandbox" || result.bundleId !== env.APPLE_APP_BUNDLE_IDENTIFIER) return undefined;
  const products = env.PLUS_PRODUCT_IDS.split(",").map((product) => product.trim());
  return result.subscriptions.find((subscription) => {
    const tx = subscription.transaction;
    return tx.originalTransactionId === originalId && products.includes(tx.productId) &&
      canReceiveCancellationOffer(subscription, now);
  })?.transaction;
}

export async function signTrialReturnOffer(env: Env, userId: string) {
  stagingOnly(env);
  const transaction = await eligibleCancellation(env, userId);
  if (!transaction) throw new HttpError(403, "offer_ineligible", "This offer is unavailable for your subscription.");
  const token = await es256Jwt(env.APP_STORE_PRIVATE_KEY, { kid: env.APP_STORE_KEY_ID }, {
    iss: env.APP_STORE_ISSUER_ID, bid: env.APPLE_APP_BUNDLE_IDENTIFIER, aud: "promotional-offer",
    iat: Math.floor(Date.now() / 1000), nonce: crypto.randomUUID(), productId: YEARLY,
    offerIdentifier: RETURN_OFFER_ID, transactionId: transaction.transactionId,
  });
  return Response.json({ token }, { headers: { "Cache-Control": "no-store" } });
}
