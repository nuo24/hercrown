// Membership: Superwall webhooks → `entitlements`, the only source of truth for Premium (ai-app-playbook chapter 07).
// Reading is free; Premium unlocks plans and study tools (docs/decisions/0003).
import { HttpError } from "./http";

export const ENTITLEMENT = "plus";
const GRACE_MS = 16 * 86_400_000; // App Store billing grace period, at most 16 days

// ── Signature (Standard Webhooks / Svix, as used by Superwall) ─────────────

const b64 = (bytes: Uint8Array) => btoa(String.fromCharCode(...bytes));
const fromB64 = (s: string) => Uint8Array.from(atob(s), (c) => c.charCodeAt(0));

/** HMAC-SHA256 over `${svix-id}.${svix-timestamp}.${rawBody}` with the base64 secret after `whsec_`; ±5 minutes. */
export async function verifyWebhook(secret: string, headers: Headers, body: string, now = Date.now()): Promise<boolean> {
  const id = headers.get("svix-id"), timestamp = headers.get("svix-timestamp"), signatures = headers.get("svix-signature");
  if (!secret || !id || !timestamp || !signatures) return false;
  const seconds = Number(timestamp);
  if (!Number.isFinite(seconds) || Math.abs(now / 1000 - seconds) > 300) return false;

  let keyBytes: Uint8Array;
  try {
    keyBytes = fromB64(secret.startsWith("whsec_") ? secret.slice(6) : secret);
  } catch {
    return false;
  }
  const key = await crypto.subtle.importKey("raw", keyBytes, { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const mac = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${id}.${timestamp}.${body}`));
  const expected = new TextEncoder().encode(b64(new Uint8Array(mac)));

  return signatures.split(" ").some((entry) => {
    const [version, signature] = entry.split(",");
    const given = new TextEncoder().encode(signature ?? "");
    return version === "v1" && given.byteLength === expected.byteLength && crypto.subtle.timingSafeEqual(given, expected);
  });
}

// ── Webhook ─────────────────────────────────────────────────────────────────

interface SuperwallEvent {
  type: string;
  timestamp: number;
  data: {
    id?: string;
    name?: string;
    appUserId?: string;
    originalAppUserId?: string;
    cancelReason?: string | null;
    periodType?: "TRIAL" | "INTRO" | "NORMAL";
    store?: "APP_STORE" | "PLAY_STORE" | "STRIPE";
    environment?: "PRODUCTION" | "SANDBOX";
    productId?: string;
    originalTransactionId?: string;
    expirationAt?: number | null;
  };
}

type Status = "trialing" | "active" | "grace" | "expired" | "refunded";

/** How each Superwall event changes the entitlement. `null` = record nothing (event doesn't affect access). */
function transition(e: SuperwallEvent): { status?: Status; willRenew?: boolean } | null {
  const live: Status = e.data.periodType === "TRIAL" ? "trialing" : "active";
  switch (e.type) {
    case "initial_purchase":
    case "renewal":
    case "uncancellation":
    case "non_renewing_purchase":
      return { status: live, willRenew: e.type !== "non_renewing_purchase" };
    case "product_change":
      return { status: live };
    case "cancellation":
      // Auto-renew turned off: access continues until expiry. A refund (customer support) ends it now.
      return /CUSTOMER_SUPPORT|REFUND/i.test(e.data.cancelReason ?? "") ? { status: "refunded", willRenew: false } : { willRenew: false };
    case "billing_issue":
      return { status: "grace" };
    case "expiration":
      return { status: "expired", willRenew: false };
    default:
      return null; // e.g. subscription_paused (Android only)
  }
}

const SOURCES = { APP_STORE: "app_store", PLAY_STORE: "play", STRIPE: "stripe" } as const;

/** The app identifies users to Superwall with our user id. After a guest links an account, the
 *  original transaction id finds the account the entitlement was moved to. */
async function resolveUser(env: Env, e: SuperwallEvent): Promise<string | null> {
  const otx = e.data.originalTransactionId;
  if (otx) {
    const owner = await env.DB.prepare("SELECT user_id FROM entitlements WHERE original_transaction_id = ?1 ORDER BY updated_at DESC LIMIT 1")
      .bind(otx).first<{ user_id: string }>();
    if (owner) return owner.user_id;
  }
  for (const candidate of [e.data.appUserId, e.data.originalAppUserId]) {
    if (!candidate || candidate.startsWith("$SuperwallAlias:")) continue;
    const user = await env.DB.prepare('SELECT id FROM "user" WHERE id = ?1').bind(candidate).first();
    if (user) return candidate;
  }
  return null;
}

export async function handleSuperwallWebhook(request: Request, env: Env): Promise<Response> {
  const body = await request.text();
  if (!(await verifyWebhook(env.SUPERWALL_WEBHOOK_SECRET, request.headers, body))) {
    return Response.json({ error: "invalid_signature" }, { status: 401 });
  }
  const deliveryId = `superwall:${request.headers.get("svix-id")}`;
  const seen = await env.DB.prepare("SELECT 1 FROM webhook_events WHERE id = ?1").bind(deliveryId).first();
  if (seen) return Response.json({ ok: true, duplicate: true });

  let event: SuperwallEvent;
  try {
    event = JSON.parse(body);
    if (typeof event.type !== "string" || !event.data || typeof event.data !== "object") throw new Error();
  } catch {
    return Response.json({ error: "invalid_payload" }, { status: 400 });
  }

  const t = Date.now();
  const markSeen = env.DB.prepare("INSERT INTO webhook_events (id, source, type, received_at) VALUES (?1, 'superwall', ?2, ?3)")
    .bind(deliveryId, event.type, t);
  const change = transition(event);
  const userId = change ? await resolveUser(env, event) : null;

  const writes: D1PreparedStatement[] = [markSeen];
  if (change && !userId) {
    writes.push(env.DB.prepare(
      `INSERT OR IGNORE INTO unmatched_store_events (id, app_user_id, original_transaction_id, type, payload, received_at)
       VALUES (?1, ?2, ?3, ?4, ?5, ?6)`,
    ).bind(deliveryId, event.data.appUserId ?? event.data.originalAppUserId ?? null, event.data.originalTransactionId ?? null, event.type, body, t));
  } else if (change && userId) {
    const eventAt = Number(event.timestamp) || t;
    // Insert, or update only if this event is not older than the last one applied.
    writes.push(env.DB.prepare(
      `INSERT INTO entitlements (user_id, entitlement, source, product_id, status, current_period_end, original_transaction_id,
         updated_at, will_renew, period_type, environment, last_event_at)
       VALUES (?1, ?2, ?3, ?4, COALESCE(?5, 'active'), ?6, ?7, ?8, COALESCE(?9, 1), ?10, ?11, ?12)
       ON CONFLICT (user_id, entitlement) DO UPDATE SET
         source = excluded.source,
         product_id = COALESCE(excluded.product_id, entitlements.product_id),
         status = COALESCE(?5, entitlements.status),
         current_period_end = COALESCE(excluded.current_period_end, entitlements.current_period_end),
         original_transaction_id = COALESCE(excluded.original_transaction_id, entitlements.original_transaction_id),
         will_renew = COALESCE(?9, entitlements.will_renew),
         period_type = COALESCE(excluded.period_type, entitlements.period_type),
         environment = COALESCE(excluded.environment, entitlements.environment),
         updated_at = excluded.updated_at,
         last_event_at = excluded.last_event_at
       WHERE excluded.last_event_at >= entitlements.last_event_at`,
    ).bind(
      userId, ENTITLEMENT, SOURCES[event.data.store ?? "APP_STORE"] ?? "app_store", event.data.productId ?? null,
      change.status ?? null, event.data.expirationAt ?? null, event.data.originalTransactionId ?? null, t,
      change.willRenew === undefined ? null : change.willRenew ? 1 : 0, event.data.periodType ?? null,
      event.data.environment ?? null, eventAt,
    ));
  }

  try {
    await env.DB.batch(writes);
  } catch (err) {
    if (String(err).includes("UNIQUE constraint failed: webhook_events.id")) return Response.json({ ok: true, duplicate: true });
    throw err; // 500 → Superwall retries
  }
  return Response.json({ ok: true, applied: Boolean(change && userId), matched: Boolean(userId) });
}

// ── Reading entitlements ────────────────────────────────────────────────────

interface EntitlementRow {
  status: Status;
  product_id: string | null;
  current_period_end: number | null;
  will_renew: number;
  period_type: string | null;
  source: string;
  environment: string | null;
}

export function isPremium(row: EntitlementRow | null, now = Date.now()): boolean {
  if (!row) return false;
  const end = row.current_period_end;
  if (row.status === "trialing" || row.status === "active") return end === null || end > now;
  if (row.status === "grace") return end === null || end + GRACE_MS > now;
  return false;
}

export async function entitlementFor(env: Env, userId: string) {
  const row = await env.DB.prepare(
    `SELECT status, product_id, current_period_end, will_renew, period_type, source, environment
     FROM entitlements WHERE user_id = ?1 AND entitlement = ?2`,
  ).bind(userId, ENTITLEMENT).first<EntitlementRow>();
  return {
    premium: isPremium(row),
    subscription: row
      ? {
          status: row.status,
          productId: row.product_id,
          expiresAt: row.current_period_end,
          willRenew: row.will_renew === 1,
          isTrial: row.status === "trialing",
          store: row.source,
          sandbox: row.environment === "SANDBOX",
        }
      : null,
  };
}

/** The only Premium check. Clients show the paywall when they get `premium_required`. */
export async function requirePremium(env: Env, userId: string) {
  if (!(await entitlementFor(env, userId)).premium) {
    throw new HttpError(403, "premium_required", "This needs Bible Scroll Plus");
  }
}
