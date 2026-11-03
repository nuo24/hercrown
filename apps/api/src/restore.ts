// Restore Purchases: re-attach a verified App Store subscription to the current user
// (after a reinstall, on a new device, or after signing in). See docs/restore-purchases.md.
import { APPLE_STATUS, subscriptionStatuses, type AppleSubscription } from "./appstore";
import { ENTITLEMENT, entitlementFor, isPremium, type EntitlementRow } from "./billing";
import { badRequest, HttpError, readJson } from "./http";
import type { SessionUser } from "./profile";

type Status = "trialing" | "active" | "grace" | "expired" | "refunded";
export type RestoreReason = "not_found" | "wrong_app" | "no_plus_subscription" | "expired" | "billing_retry" | "revoked";

const TRANSACTION_ID = /^\d{1,32}$/; // App Store transaction ids are numeric strings

export function plusProductIds(env: Env) {
  return new Set(env.PLUS_PRODUCT_IDS.split(",").map((s) => s.trim()).filter(Boolean));
}

/** Apple's view of one subscription → our entitlement status. */
export function entitlementState(sub: AppleSubscription, now = Date.now()): { status: Status; periodEnd: number | null; reason?: RestoreReason } {
  const t = sub.transaction;
  if (sub.status === APPLE_STATUS.REVOKED || t.revocationDate) return { status: "refunded", periodEnd: t.expiresDate ?? null, reason: "revoked" };
  if (sub.status === APPLE_STATUS.GRACE) {
    return { status: "grace", periodEnd: sub.renewal?.gracePeriodExpiresDate ?? t.expiresDate ?? null };
  }
  if (sub.status === APPLE_STATUS.ACTIVE && (t.expiresDate ?? Infinity) > now) {
    const trial = t.offerType === 1 && t.offerDiscountType === "FREE_TRIAL";
    return { status: trial ? "trialing" : "active", periodEnd: t.expiresDate ?? null };
  }
  // Billing retry without a grace period means no access until Apple collects payment.
  const reason = sub.status === APPLE_STATUS.BILLING_RETRY ? "billing_retry" : "expired";
  return { status: "expired", periodEnd: t.expiresDate ?? null, reason };
}

const rank = (s: Status) => ({ active: 4, trialing: 4, grace: 3, expired: 1, refunded: 0 })[s];

/**
 * POST /me/restore  { "transactionId": "<StoreKit Transaction.id or originalID>" }
 * 200 → { restored, reason?, transferred, alreadyActive?, membership }   (business outcomes, including "nothing to restore")
 * 400 bad id · 429 too many attempts · 503 App Store unreachable or restore not configured (safe to retry)
 */
export async function restorePurchases(request: Request, env: Env, user: SessionUser) {
  const { success } = await env.RESTORE_LIMITER.limit({ key: user.id });
  if (!success) throw new HttpError(429, "rate_limited", "Too many restore attempts. Try again in a minute.");

  const body = await readJson(request);
  const transactionId = typeof body.transactionId === "string" ? body.transactionId.trim() : "";
  if (!TRANSACTION_ID.test(transactionId)) throw badRequest("transactionId must be an App Store transaction id");

  const outcome = (restored: boolean, extra: { reason?: RestoreReason; transferred?: boolean; alreadyActive?: boolean } = {}) =>
    entitlementFor(env, user.id).then((membership) => Response.json({ restored, transferred: false, ...extra, membership }));

  const result = await subscriptionStatuses(env, transactionId);
  if (!result) return outcome(false, { reason: "not_found" });
  if (result.bundleId !== env.APPLE_APP_BUNDLE_IDENTIFIER) {
    console.error("Restore for another app's transaction", result.bundleId);
    return outcome(false, { reason: "wrong_app" });
  }

  // The customer's Plus subscription(s); prefer one that grants access, then the latest expiry.
  const products = plusProductIds(env);
  const candidates = result.subscriptions
    .filter((s) => s.transaction.bundleId === env.APPLE_APP_BUNDLE_IDENTIFIER && products.has(s.transaction.productId))
    .map((s) => ({ sub: s, state: entitlementState(s) }))
    .sort((a, b) => rank(b.state.status) - rank(a.state.status) || (b.state.periodEnd ?? 0) - (a.state.periodEnd ?? 0));
  const best = candidates[0];
  if (!best) return outcome(false, { reason: "no_plus_subscription" });

  const premium = isPremium({
    status: best.state.status, current_period_end: best.state.periodEnd, product_id: null, will_renew: 0,
    period_type: null, source: "app_store", environment: null,
  });
  if (!premium) return outcome(false, { reason: best.state.reason ?? "expired" });

  const t = best.sub.transaction;
  const now = Date.now();

  // Already covered by a different subscription that runs at least as long (e.g. a second Apple ID): change nothing.
  const own = await env.DB.prepare(
    `SELECT status, current_period_end, original_transaction_id, product_id, will_renew, period_type, source, environment
     FROM entitlements WHERE user_id = ?1 AND entitlement = ?2`,
  ).bind(user.id, ENTITLEMENT).first<EntitlementRow & { original_transaction_id: string | null }>();
  if (own && own.original_transaction_id !== t.originalTransactionId && isPremium(own, now)
    && (own.current_period_end ?? Infinity) >= (best.state.periodEnd ?? Infinity)) {
    return outcome(true, { alreadyActive: true });
  }

  const previousOwners = await env.DB.prepare(
    "SELECT user_id FROM entitlements WHERE original_transaction_id = ?1 AND user_id <> ?2",
  ).bind(t.originalTransactionId, user.id).all<{ user_id: string }>();

  const environment = t.environment === "Sandbox" || result.environment === "sandbox" ? "SANDBOX" : "PRODUCTION";
  const willRenew = best.sub.renewal?.autoRenewStatus === 0 ? 0 : 1;
  await env.DB.batch([
    // A subscription belongs to one Apple ID; the account restoring it now becomes its owner.
    env.DB.prepare("DELETE FROM entitlements WHERE original_transaction_id = ?1 AND user_id <> ?2").bind(t.originalTransactionId, user.id),
    ...previousOwners.results.map((p) => env.DB.prepare(
      `INSERT INTO entitlement_transfers (id, original_transaction_id, from_user_id, to_user_id, reason, created_at)
       VALUES (?1, ?2, ?3, ?4, 'restore', ?5)`,
    ).bind(crypto.randomUUID(), t.originalTransactionId, p.user_id, user.id, now)),
    // Apple's answer is current, so it replaces whatever we had (last_event_at = now: older webhooks can't undo it).
    env.DB.prepare(
      `INSERT INTO entitlements (user_id, entitlement, source, product_id, status, current_period_end, original_transaction_id,
         updated_at, will_renew, period_type, environment, last_event_at)
       VALUES (?1, ?2, 'app_store', ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?7)
       ON CONFLICT (user_id, entitlement) DO UPDATE SET
         source = 'app_store', product_id = excluded.product_id, status = excluded.status,
         current_period_end = excluded.current_period_end, original_transaction_id = excluded.original_transaction_id,
         updated_at = excluded.updated_at, will_renew = excluded.will_renew, period_type = excluded.period_type,
         environment = excluded.environment, last_event_at = MAX(entitlements.last_event_at, excluded.last_event_at)`,
    ).bind(
      user.id, ENTITLEMENT, t.productId, best.state.status, best.state.periodEnd, t.originalTransactionId, now,
      willRenew, best.state.status === "trialing" ? "TRIAL" : "NORMAL", environment,
    ),
  ]);

  return outcome(true, { transferred: previousOwners.results.length > 0 });
}
