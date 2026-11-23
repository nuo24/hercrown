import { entitlementFor } from "./billing";
import type { Tracker } from "./events";

export const GIFT_DELAY_MS = 86_400_000;

export async function scheduleGift(env: Env, userId: string, tracker: Tracker, now = Date.now()) {
  if ((await entitlementFor(env, userId)).premium) return Response.json({ scheduled: false });
  const inserted = await env.DB.prepare(`INSERT INTO gift_offers (user_id, declined_at) VALUES (?1, ?2)
    ON CONFLICT(user_id) DO NOTHING RETURNING declined_at`).bind(userId, now).first();
  if (inserted) tracker.track("mystery_gift_scheduled");
  return Response.json({ scheduled: inserted !== null });
}

export async function giftStatus(env: Env, userId: string, now = Date.now()) {
  const row = await env.DB.prepare("SELECT declined_at, shown_at FROM gift_offers WHERE user_id = ?1")
    .bind(userId).first<{ declined_at: number; shown_at: number | null }>();
  const due = row != null && row.shown_at == null && row.declined_at <= now - GIFT_DELAY_MS
    && !(await entitlementFor(env, userId)).premium;
  return Response.json({ due });
}

export async function claimGift(env: Env, userId: string, now = Date.now()) {
  if ((await entitlementFor(env, userId)).premium) return Response.json({ available: false });
  // Atomic across devices. Reads and unavailable StoreKit products never consume the invitation.
  const claimed = await env.DB.prepare(`UPDATE gift_offers SET shown_at = ?2
    WHERE user_id = ?1 AND shown_at IS NULL AND declined_at <= ?3
      AND NOT EXISTS (SELECT 1 FROM entitlements WHERE user_id = ?1 AND entitlement = 'plus'
        AND status IN ('trialing', 'active', 'grace') AND (current_period_end IS NULL OR current_period_end > ?2))
    RETURNING shown_at`).bind(userId, now, now - GIFT_DELAY_MS).first();
  return Response.json({ available: claimed !== null });
}
