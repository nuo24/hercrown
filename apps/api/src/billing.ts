// Membership: Superwall webhooks → `entitlements`, the only source of truth for Premium (ai-app-playbook chapter 07).
// Reading is free; Premium unlocks plans and study tools (docs/decisions/0003).
import { type Props, type ServerEvent, Tracker } from "./events";
import { HttpError } from "./http";
import { trialInfo } from "./reminders";

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

/** A Superwall event in one shape, whichever webhook format delivered it. */
export interface StoreEvent {
  type: string;
  occurredAt: number;
  userIds: string[]; // app user id first, then original id and aliases
  isRefund: boolean;
  periodType: "TRIAL" | "INTRO" | "NORMAL" | null;
  store: "APP_STORE" | "PLAY_STORE" | "STRIPE" | null;
  environment: "PRODUCTION" | "SANDBOX" | null;
  productId: string | null;
  originalTransactionId: string | null;
  expirationAt: number | null;
  willRenew: boolean | null; // V2 subscription snapshot, when present
  storeEventId: string | null; // the same store event has the same id in V1 and V2 ("<uuid>:renewal")
  transactionId: string | null;
  isTrialConversion: boolean;
  price: number | null; // USD, negative for refunds
  proceeds: number | null; // USD after store commission and taxes
}

type Json = Record<string, any>;
const str = (v: unknown) => (typeof v === "string" && v ? v : null);
const num = (v: unknown) => (typeof v === "number" && Number.isFinite(v) ? v : null);

/**
 * V2 (current default): `event_data` snake_case + `subscription`/`subscriber` snapshots, `occurred_at`, separate `refund` event.
 * V1 (legacy): `data` camelCase, `timestamp`, refunds are `cancellation` with `isRefund: true`.
 */
export function normalizeEvent(payload: Json): StoreEvent | null {
  if (!payload || typeof payload !== "object" || typeof payload.type !== "string") return null;
  const v2 = payload.event_data && typeof payload.event_data === "object" ? (payload.event_data as Json) : null;
  if (v2) {
    const sub = (payload.subscription ?? {}) as Json;
    const subscriber = (payload.subscriber ?? {}) as Json;
    return {
      type: payload.type,
      occurredAt: num(payload.occurred_at) ?? Date.now(),
      userIds: [payload.app_user_id, subscriber.app_user_id, subscriber.original_app_user_id, ...(subscriber.aliases ?? [])]
        .map(str).filter((x): x is string => Boolean(x)),
      isRefund: payload.type === "refund" || v2.is_refund === true,
      periodType: str(v2.period_type) as StoreEvent["periodType"],
      store: str(v2.store) as StoreEvent["store"],
      environment: str(v2.environment) as StoreEvent["environment"],
      productId: str(v2.new_product_id) ?? str(v2.product_id),
      originalTransactionId: str(v2.original_transaction_id),
      expirationAt: num(v2.expiration_at) ?? num(sub.expires_at),
      willRenew: typeof sub.will_renew === "boolean" ? sub.will_renew : null,
      storeEventId: str(v2.id),
      transactionId: str(v2.transaction_id),
      isTrialConversion: v2.is_trial_conversion === true,
      price: num(v2.price),
      proceeds: num(v2.proceeds),
    };
  }
  const d = payload.data;
  if (!d || typeof d !== "object") return null;
  return {
    type: payload.type,
    occurredAt: num(payload.timestamp) ?? Date.now(),
    userIds: [d.appUserId, d.originalAppUserId].map(str).filter((x): x is string => Boolean(x)),
    isRefund: d.isRefund === true,
    periodType: str(d.periodType) as StoreEvent["periodType"],
    store: str(d.store) as StoreEvent["store"],
    environment: str(d.environment) as StoreEvent["environment"],
    productId: str(d.newProductId) ?? str(d.productId),
    originalTransactionId: str(d.originalTransactionId),
    expirationAt: num(d.expirationAt),
    willRenew: null,
    storeEventId: str(d.id),
    transactionId: str(d.transactionId),
    isTrialConversion: d.isTrialConversion === true,
    price: num(d.price),
    proceeds: num(d.proceeds),
  };
}

type Status = "trialing" | "active" | "grace" | "expired" | "refunded";

/** How each event changes the entitlement. `null` = record nothing (event doesn't affect access). */
export function transition(e: StoreEvent): { status?: Status; willRenew?: boolean } | null {
  if (e.isRefund) return { status: "refunded", willRenew: false };
  const live: Status = e.periodType === "TRIAL" ? "trialing" : "active";
  const renew = (fallback: boolean) => e.willRenew ?? fallback;
  switch (e.type) {
    case "initial_purchase":
    case "renewal":
    case "uncancellation":
      return { status: live, willRenew: renew(true) };
    case "non_renewing_purchase":
      return { status: live, willRenew: false };
    case "product_change":
      return { status: live };
    case "cancellation": // auto-renew turned off: access continues until expiry
      return { willRenew: false };
    case "billing_issue":
      return { status: "grace" };
    case "expiration":
      return { status: "expired", willRenew: false };
    default:
      return null; // e.g. subscription_paused (Android only)
  }
}

const SOURCES = { APP_STORE: "app_store", PLAY_STORE: "play", STRIPE: "stripe" } as const;

/** Owner by original transaction first (follows guest links and restores), then the ids Superwall knows. */
async function resolveUser(env: Env, e: StoreEvent): Promise<string | null> {
  if (e.originalTransactionId) {
    const owner = await env.DB.prepare("SELECT user_id FROM entitlements WHERE original_transaction_id = ?1 ORDER BY updated_at DESC LIMIT 1")
      .bind(e.originalTransactionId).first<{ user_id: string }>();
    if (owner) return owner.user_id;
  }
  for (const candidate of e.userIds) {
    if (candidate.startsWith("$SuperwallAlias:")) continue;
    const user = await env.DB.prepare('SELECT id FROM "user" WHERE id = ?1').bind(candidate).first();
    if (user) return candidate;
  }
  return null;
}

/**
 * The analytics event for a verified store event. Milestones get ids that make them count once per subscription
 * (trial_started:<original transaction>), whichever webhook version or retry delivered them. Only product and money
 * fields: nothing from the person's profile or reading.
 */
export function billingEvent(e: StoreEvent, deliveryId: string): { name: ServerEvent; id: string; props: Props } | null {
  const props: Props = {
    product_id: e.productId, period_type: e.periodType, store: e.store, price: e.price, proceeds: e.proceeds,
  };
  const once = (name: ServerEvent, key: string | null) => ({ name, id: `${name}:${key ?? e.storeEventId ?? deliveryId}`, props });
  const each = (name: ServerEvent) => ({ name, id: `${name}:${e.storeEventId ?? deliveryId}`, props });
  if (e.isRefund) return once("refunded", e.transactionId);
  switch (e.type) {
    case "initial_purchase":
      return e.periodType === "TRIAL"
        ? once("trial_started", e.originalTransactionId)
        : once("subscription_started", e.originalTransactionId);
    case "renewal":
      return e.isTrialConversion ? once("trial_converted", e.originalTransactionId) : once("subscription_renewed", e.transactionId);
    case "cancellation":
      return each("subscription_cancelled");
    case "uncancellation":
      return each("subscription_uncancelled");
    case "billing_issue":
      return each("billing_issue");
    case "expiration":
      return each("subscription_expired");
    case "product_change":
      return each("subscription_product_changed");
  }
  return null;
}

export async function handleSuperwallWebhook(request: Request, env: Env, ctx?: Pick<ExecutionContext, "waitUntil">): Promise<Response> {
  const body = await request.text();
  if (!(await verifyWebhook(env.SUPERWALL_WEBHOOK_SECRET, request.headers, body))) {
    return Response.json({ error: "invalid_signature" }, { status: 401 });
  }
  const deliveryId = `superwall:${request.headers.get("svix-id")}`;
  const seen = await env.DB.prepare("SELECT 1 FROM webhook_events WHERE id = ?1").bind(deliveryId).first();
  if (seen) return Response.json({ ok: true, duplicate: true });

  let event: StoreEvent | null = null;
  try {
    event = normalizeEvent(JSON.parse(body));
  } catch {
    // fall through
  }
  if (!event) return Response.json({ error: "invalid_payload" }, { status: 400 });

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
    ).bind(deliveryId, event.userIds[0] ?? null, event.originalTransactionId, event.type, body, t));
  } else if (change && userId) {
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
      userId, ENTITLEMENT, SOURCES[event.store ?? "APP_STORE"] ?? "app_store", event.productId,
      change.status ?? null, event.expirationAt, event.originalTransactionId, t,
      change.willRenew === undefined ? null : change.willRenew ? 1 : 0, event.periodType,
      event.environment, event.occurredAt,
    ));
  }

  try {
    await env.DB.batch(writes);
  } catch (err) {
    if (String(err).includes("UNIQUE constraint failed: webhook_events.id")) return Response.json({ ok: true, duplicate: true });
    throw err; // 500 → Superwall retries
  }

  const analytics = billingEvent(event, deliveryId);
  if (analytics) {
    new Tracker(env, ctx).track(analytics.name, analytics.props, {
      id: analytics.id, at: event.occurredAt, userId, sandbox: event.environment === "SANDBOX",
    });
  }
  return Response.json({ ok: true, applied: Boolean(change && userId), matched: Boolean(userId) });
}

// ── Reading entitlements ────────────────────────────────────────────────────

export interface EntitlementRow {
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
          trial: row.status === "trialing" ? trialInfo(env, row.current_period_end, row.will_renew === 1) : null,
        }
      : null,
  };
}

/** The only Premium check. Clients show the paywall when they get `premium_required`. */
export async function requirePremium(env: Env, userId: string) {
  if (!(await entitlementFor(env, userId)).premium) {
    throw new HttpError(403, "premium_required", "This needs Her Crown Plus");
  }
}
