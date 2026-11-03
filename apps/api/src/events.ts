// Product analytics and errors: clients and the Worker → Cloudflare Queue → Tinybird Events API (ai-app-playbook chapter 08).
// What each event means, and what every funnel rate is divided by: docs/analytics.md.
//
// Privacy: events carry a pseudonymous person id, never names, emails, onboarding answers, notes or verse references.
// Purchases are counted only from verified store webhooks, never from what the app says happened.

import { badRequest, HttpError, readJson } from "./http";

export const DATASOURCE = "events";

/** One row of the Tinybird `events` data source (tinybird/datasources/events.datasource). */
export interface EventRow {
  event_id: string; // client UUID, or a deterministic server id so retries and duplicate webhooks collapse
  event: string;
  timestamp: string; // UTC "YYYY-MM-DD hh:mm:ss.sss": when it happened
  received_at: string;
  environment: string; // APP_ENV: dev | staging | production
  sandbox: 0 | 1; // store sandbox purchase, or an app build that isn't from the App Store
  source: "api" | "ios";
  person_id: string | null;
  install_id: string | null;
  app_version: string | null;
  platform: string | null;
  country: string | null;
  props: string; // JSON object
}

export type Props = Record<string, string | number | boolean | null | undefined>;

/** Events the server emits. Clients can't send these. */
export type ServerEvent =
  | "onboarding_completed"
  | "trial_started" | "trial_converted" | "subscription_started" | "subscription_renewed"
  | "subscription_cancelled" | "subscription_uncancelled" | "subscription_product_changed"
  | "billing_issue" | "subscription_expired" | "refunded"
  | "restore_completed" | "restore_failed"
  | "account_linked"
  | "passage_read" | "passage_saved" | "plan_started" | "plan_step_completed"
  | "trial_reminder_sent"
  | "ai_call" | "study_viewed" | "study_reported"
  | "error";

type Kind = "string" | "number" | "boolean";
const PAYWALL: Record<string, Kind> = { placement: "string", paywall_id: "string", variant: "string", experiment_id: "string" };

/** Events the app may send to POST /events, with the only props kept for each. */
export const CLIENT_EVENTS: Record<string, Record<string, Kind>> = {
  app_opened: {},
  onboarding_step: { step: "string", index: "number" },
  paywall_viewed: PAYWALL,
  paywall_declined: PAYWALL,
  decline_offer_viewed: PAYWALL,
  decline_offer_declined: PAYWALL,
  purchase_started: { ...PAYWALL, product_id: "string" }, // the tap; the purchase itself comes from the store webhook
  purchase_failed: { ...PAYWALL, product_id: "string", reason: "string" },
  restore_tapped: {},
  push_permission: { granted: "boolean", placement: "string" },
  trial_notice_viewed: { placement: "string" }, // the in-app "trial ends soon" notice (home or settings)
  manage_subscription_tapped: { placement: "string" },
  error: { message: "string", stack: "string", screen: "string" },
};

const MAX_BATCH = 50;
const MAX_TEXT = 200;
const MAX_STACK = 4000;
const MAX_AGE_MS = 30 * 86_400_000; // queued offline for longer than this: dropped
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const VERSION = /^[\w.+\-() ]{1,32}$/;
const BUILDS = ["appstore", "testflight", "debug"] as const;

export const timestamp = (ms: number) => new Date(ms).toISOString().replace("T", " ").replace("Z", "");

// ── Identity ────────────────────────────────────────────────────────────────

/** A person's analytics id: their first user id, kept when a guest links Sign in with Apple. */
export async function personIdFor(env: Env, userId: string): Promise<string> {
  const row = await env.DB.prepare("SELECT person_id FROM analytics_ids WHERE user_id = ?1").bind(userId).first<{ person_id: string }>();
  return row?.person_id ?? userId;
}

/**
 * Called when a guest links an account. A brand-new account continues the guest's analytics id, so
 * onboarding → paywall → trial stays one person. An account that already existed keeps its own id;
 * an `account_linked` event records that the guest id belongs to it.
 */
export async function linkPerson(env: Env, guestId: string, accountId: string, accountIsNew: boolean): Promise<void> {
  const guestPerson = await personIdFor(env, guestId);
  if (accountIsNew) {
    await env.DB.prepare("INSERT OR REPLACE INTO analytics_ids (user_id, person_id) VALUES (?1, ?2)").bind(accountId, guestPerson).run();
    return;
  }
  await new Tracker(env).emit("account_linked", { previous_person_id: guestPerson }, { userId: accountId });
}

// ── Request context ─────────────────────────────────────────────────────────

/** Sent by the app on every request: X-Install-Id (UUID), X-App-Version, X-Platform, X-Build (appstore | testflight | debug). */
export interface RequestContext {
  installId: string | null;
  appVersion: string | null;
  platform: string | null;
  country: string | null;
  sandbox: boolean;
}

const NO_CONTEXT: RequestContext = { installId: null, appVersion: null, platform: null, country: null, sandbox: false };

export function requestContext(request: Request): RequestContext {
  const h = request.headers;
  const installId = h.get("x-install-id");
  const version = h.get("x-app-version");
  const platform = h.get("x-platform")?.toLowerCase() ?? null;
  const build = h.get("x-build")?.toLowerCase();
  const country = (request as Request & { cf?: { country?: string } }).cf?.country;
  return {
    installId: installId && UUID.test(installId) ? installId.toLowerCase() : null,
    appVersion: version && VERSION.test(version) ? version : null,
    platform: platform && /^[a-z]{2,16}$/.test(platform) ? platform : null,
    country: typeof country === "string" && /^[A-Z]{2}$/.test(country) ? country : null,
    sandbox: build !== undefined && BUILDS.includes(build as never) && build !== "appstore",
  };
}

// ── Emitting ────────────────────────────────────────────────────────────────

export interface TrackOptions {
  /** Deterministic id (given the person id) so the same fact counts once, however often it's reported. */
  id?: string | ((personId: string | null) => string);
  at?: number;
  userId?: string | null; // defaults to the request's signed-in user
  sandbox?: boolean;
}

/** Per-request event emitter. Analytics never fails a request: errors are logged and dropped. */
export class Tracker {
  userId: string | null = null;

  constructor(
    readonly env: Env,
    readonly ctx?: Pick<ExecutionContext, "waitUntil">,
    readonly context: RequestContext = NO_CONTEXT,
  ) {}

  /** Queues the event after the response is sent. */
  track(event: ServerEvent, props: Props = {}, opts: TrackOptions = {}): void {
    const sent = this.emit(event, props, opts);
    if (this.ctx) this.ctx.waitUntil(sent);
  }

  /** Queues the event now; resolves once it is queued (or failed and was logged). */
  async emit(event: ServerEvent, props: Props = {}, opts: TrackOptions = {}): Promise<void> {
    try {
      const userId = opts.userId !== undefined ? opts.userId : this.userId;
      const personId = userId ? await personIdFor(this.env, userId) : null;
      const now = Date.now();
      const id = typeof opts.id === "function" ? opts.id(personId) : opts.id ?? crypto.randomUUID();
      await this.env.EVENTS.send(this.row(event, id, opts.at ?? now, now, personId, "api", props, opts.sandbox));
    } catch (err) {
      console.error("analytics: could not queue", event, err);
    }
  }

  row(event: string, id: string, at: number, now: number, personId: string | null, source: EventRow["source"], props: Props, sandbox?: boolean): EventRow {
    return {
      event_id: id,
      event,
      timestamp: timestamp(at),
      received_at: timestamp(now),
      environment: this.env.APP_ENV,
      sandbox: (sandbox ?? this.context.sandbox) ? 1 : 0,
      source,
      person_id: personId,
      install_id: this.context.installId,
      app_version: this.context.appVersion,
      platform: this.context.platform,
      country: this.context.country,
      props: JSON.stringify(props, (_k, v) => (v === undefined ? null : v)),
    };
  }

  /** Server error → `error` event, alongside every other event (no separate error tracker). */
  error(request: Request, url: URL, err: unknown): void {
    this.track("error", {
      source: "api",
      method: request.method,
      route: url.pathname,
      message: String(err).slice(0, MAX_TEXT * 5),
      stack: err instanceof Error ? err.stack?.slice(0, MAX_STACK) : undefined,
    });
  }
}

// ── POST /events (from the app) ─────────────────────────────────────────────

/**
 * Body: { events: [{ id: UUID, name, at?: ms, props?: {} }] } (1–50). Works before sign-in (app_opened), so it's
 * rate-limited by user or IP. Unknown events, bad ids and unlisted props are dropped and reported back; the app
 * shouldn't resend those. A 2xx means the accepted events are queued; anything else, keep them and retry later.
 */
export async function receiveEvents(request: Request, tracker: Tracker): Promise<Response> {
  const { env } = tracker;
  const key = tracker.userId ?? request.headers.get("cf-connecting-ip") ?? "unknown";
  const { success } = await env.EVENTS_LIMITER.limit({ key });
  if (!success) throw new HttpError(429, "rate_limited", "Too many event batches. Try again in a minute.");

  const body = await readJson(request);
  const events = body.events;
  if (!Array.isArray(events) || events.length === 0) throw badRequest("events must be a non-empty array");
  if (events.length > MAX_BATCH) throw badRequest(`At most ${MAX_BATCH} events per request`);

  const now = Date.now();
  const personId = tracker.userId ? await personIdFor(env, tracker.userId) : null;
  const rows: EventRow[] = [];
  const rejected: { index: number; reason: string }[] = [];
  events.forEach((raw, index) => {
    const e = (raw && typeof raw === "object" ? raw : {}) as Record<string, unknown>;
    const spec = typeof e.name === "string" && Object.hasOwn(CLIENT_EVENTS, e.name) ? CLIENT_EVENTS[e.name]! : null;
    if (!spec) return rejected.push({ index, reason: "unknown_event" });
    if (typeof e.id !== "string" || !UUID.test(e.id)) return rejected.push({ index, reason: "invalid_id" });
    let at = typeof e.at === "number" && Number.isFinite(e.at) ? e.at : now;
    if (at < now - MAX_AGE_MS) return rejected.push({ index, reason: "too_old" });
    at = Math.min(at, now); // device clocks run fast
    rows.push(tracker.row(e.name as string, e.id.toLowerCase(), at, now, personId, "ios", cleanProps(e.props, spec)));
  });

  if (rows.length > 0) await env.EVENTS.sendBatch(rows.map((row) => ({ body: row })));
  return Response.json({ accepted: rows.length, rejected }, { status: 202 });
}

function cleanProps(raw: unknown, spec: Record<string, Kind>): Props {
  const props: Props = {};
  if (!raw || typeof raw !== "object") return props;
  for (const [key, kind] of Object.entries(spec)) {
    const value = (raw as Record<string, unknown>)[key];
    if (typeof value !== kind) continue;
    if (kind === "number" && !Number.isFinite(value)) continue;
    props[key] = typeof value === "string" ? value.slice(0, key === "stack" ? MAX_STACK : MAX_TEXT) : (value as number | boolean);
  }
  return props;
}

// ── Queue consumer → Tinybird ───────────────────────────────────────────────

/**
 * Posts a batch as NDJSON to the Tinybird Events API with a write-only token. Without TINYBIRD_TOKEN (local dev)
 * events are logged and dropped. Rate limits, outages and auth errors are retried (up to max_retries); rows
 * Tinybird can't accept are logged and dropped, since retrying won't fix them.
 */
export async function deliverEvents(batch: MessageBatch<EventRow>, env: Env): Promise<void> {
  if (!env.TINYBIRD_TOKEN) {
    console.log(`analytics: ${batch.messages.length} event(s) not sent (TINYBIRD_TOKEN not set):`,
      batch.messages.map((m) => m.body.event).join(", "));
    batch.ackAll();
    return;
  }
  const body = batch.messages.map((m) => JSON.stringify(m.body)).join("\n");
  let res: Response;
  try {
    res = await fetch(`${env.TINYBIRD_HOST}/v0/events?name=${DATASOURCE}`, {
      method: "POST",
      headers: { authorization: `Bearer ${env.TINYBIRD_TOKEN}`, "content-type": "application/x-ndjson" },
      body,
      signal: AbortSignal.timeout(10_000),
    });
  } catch (err) {
    console.error("analytics: Tinybird unreachable", err);
    batch.retryAll({ delaySeconds: 30 });
    return;
  }
  if (res.ok) {
    batch.ackAll();
    return;
  }
  const detail = (await res.text()).slice(0, 500);
  if (res.status === 401 || res.status === 403 || res.status === 429 || res.status >= 500) {
    console.error(`analytics: Tinybird ${res.status}, retrying`, detail);
    batch.retryAll({ delaySeconds: 60 });
    return;
  }
  console.error(`analytics: Tinybird rejected ${batch.messages.length} event(s): ${res.status}`, detail);
  batch.ackAll();
}
