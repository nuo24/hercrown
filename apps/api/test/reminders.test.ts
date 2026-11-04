import { env } from "cloudflare:workers";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { EventRow } from "../src/events";
import { apnsJwt } from "../src/push";
import { reminderAlert, sendTrialReminders } from "../src/reminders";
import { moveUserData } from "../src/users";
import { api, signInGuest } from "./helpers";

const HOUR = 3_600_000;
const DAY = 24 * HOUR;
const token = (n: number) => n.toString(16).padStart(64, "a");

// Every test runs at its own "now", a month apart, so trials from other tests (storage is shared in a file) are never due.
let now = Date.UTC(2027, 0, 4, 15, 0); // a Monday, 15:00 UTC
let user: { token: string; userId: string };
let pushes: { url: string; headers: Headers; body: any }[];
let apns: (url: string) => Response;
beforeEach(async () => {
  now += 30 * DAY;
  user = await signInGuest();
  pushes = [];
  apns = () => new Response(null, { status: 200 });
  vi.spyOn(globalThis, "fetch").mockImplementation(async (input, init) => {
    const url = String(input);
    if (!url.includes("push.apple.com")) throw new Error(`unexpected fetch ${url}`);
    pushes.push({ url, headers: new Headers(init?.headers), body: JSON.parse(String(init?.body)) });
    return apns(url);
  });
});
afterEach(() => vi.restoreAllMocks());

async function startTrial(userId: string, endsInHours: number, opts: { willRenew?: number; product?: string; status?: string } = {}) {
  await env.DB.prepare(
    `INSERT OR REPLACE INTO entitlements (user_id, entitlement, source, product_id, status, current_period_end, original_transaction_id,
       updated_at, will_renew, period_type, environment, last_event_at)
     VALUES (?1, 'plus', 'app_store', ?2, ?3, ?4, ?5, 1, ?6, 'TRIAL', 'PRODUCTION', 1)`,
  ).bind(userId, opts.product ?? "hercrown.plus.yearly", opts.status ?? "trialing", now + endsInHours * HOUR,
    `otx-${userId}`, opts.willRenew ?? 1).run();
  return now + endsInHours * HOUR;
}

async function addDevice(t: string, n: number, timeZone = "UTC", environment = "production") {
  const res = await api("/me/devices", { method: "PUT", token: t, body: JSON.stringify({ token: token(n), environment, timeZone }) });
  expect(res.status).toBe(200);
}

const reminded = (userId: string) => env.DB.prepare("SELECT * FROM trial_reminders WHERE user_id = ?1").bind(userId).all();

describe("device registration", () => {
  it("registers, moves between accounts, and unregisters", async () => {
    await addDevice(user.token, 1);
    const other = await signInGuest();
    await addDevice(other.token, 1); // same phone, different account → moves
    const owner = await env.DB.prepare("SELECT user_id FROM push_devices WHERE token = ?1").bind(token(1)).first<{ user_id: string }>();
    expect(owner!.user_id).toBe(other.userId);
    expect((await api(`/me/devices/${token(1)}`, { method: "DELETE", token: other.token })).status).toBe(204);
    expect(await env.DB.prepare("SELECT 1 FROM push_devices WHERE token = ?1").bind(token(1)).first()).toBeNull();
  });

  it("rejects bad tokens and environments, ignores unknown time zones", async () => {
    const put = (body: unknown) => api("/me/devices", { method: "PUT", token: user.token, body: JSON.stringify(body) });
    expect((await put({ token: "nope" })).status).toBe(400);
    expect((await put({ token: token(2), environment: "beta" })).status).toBe(400);
    expect((await put({ token: token(2), timeZone: "Mars/Olympus" })).status).toBe(200);
    const row = await env.DB.prepare("SELECT time_zone FROM push_devices WHERE token = ?1").bind(token(2)).first<{ time_zone: string | null }>();
    expect(row!.time_zone).toBeNull();
  });

  it("follows a guest who signs in", async () => {
    await addDevice(user.token, 3);
    const account = await signInGuest();
    await moveUserData(env, user.userId, account.userId);
    const owner = await env.DB.prepare("SELECT user_id FROM push_devices WHERE token = ?1").bind(token(3)).first<{ user_id: string }>();
    expect(owner!.user_id).toBe(account.userId);
  });
});

describe("in-app trial notice", () => {
  it("tells the app when the trial ends, when to show the notice, and where to cancel", async () => {
    const endsAt = await startTrial(user.userId, 5 * 24);
    const me = await (await api("/me/entitlements", { token: user.token })).json<any>();
    expect(me.subscription.trial).toEqual({
      endsAt, convertsToPaid: true, remindFrom: endsAt - 48 * HOUR, manageUrl: "https://apps.apple.com/account/subscriptions",
    });
  });

  it("says a cancelled trial won't charge, and shows nothing for paid plans", async () => {
    await startTrial(user.userId, 40, { willRenew: 0 });
    expect((await (await api("/me/entitlements", { token: user.token })).json<any>()).subscription.trial.convertsToPaid).toBe(false);
    await startTrial(user.userId, 40, { status: "active" });
    expect((await (await api("/me/entitlements", { token: user.token })).json<any>()).subscription.trial).toBeNull();
  });
});

describe("the reminder push", () => {
  it("goes out once, 2 days before the trial converts, to every device", async () => {
    const endsAt = await startTrial(user.userId, 40);
    await addDevice(user.token, 10, "America/New_York");
    await addDevice(user.token, 11, "America/New_York", "sandbox");

    expect(await sendTrialReminders(env, now)).toMatchObject({ due: 1, sent: 1 });
    expect(pushes.map((p) => p.url).sort()).toEqual([
      `https://api.push.apple.com/3/device/${token(10)}`,
      `https://api.sandbox.push.apple.com/3/device/${token(11)}`,
    ]);
    const [push] = pushes;
    expect(push!.headers.get("apns-topic")).toBe("com.hercrown.app");
    expect(push!.headers.get("apns-push-type")).toBe("alert");
    expect(push!.headers.get("authorization")).toMatch(/^bearer ey/);
    expect(push!.body.aps.alert.title).toBe("Your free trial ends in 2 days");
    expect(push!.body.aps.alert.body).toContain("becomes a yearly plan on");
    expect(push!.body.aps.alert.body).toContain("cancel before then in Settings");
    expect(push!.body.link).toBe("hercrown://settings/subscription");

    const rows = (await reminded(user.userId)).results as any[];
    expect(rows).toEqual([expect.objectContaining({ trial_ends_at: endsAt, devices: 2 })]);

    pushes = [];
    expect(await sendTrialReminders(env, now + HOUR)).toMatchObject({ due: 0 });
    expect(pushes).toHaveLength(0);
  });

  it("waits until the lead time, and skips cancelled trials", async () => {
    await startTrial(user.userId, 72);
    await addDevice(user.token, 20);
    expect((await sendTrialReminders(env, now)).due).toBe(0);
    await startTrial(user.userId, 40, { willRenew: 0 });
    expect((await sendTrialReminders(env, now)).due).toBe(0);
    expect(pushes).toHaveLength(0);
  });

  it("holds during quiet hours unless the trial is about to end", async () => {
    await startTrial(user.userId, 40);
    await addDevice(user.token, 30, "Asia/Tokyo"); // 15:00 UTC = midnight in Tokyo
    expect(await sendTrialReminders(env, now)).toMatchObject({ due: 1, waiting: 1, sent: 0 });
    expect(pushes).toHaveLength(0);
    expect(await sendTrialReminders(env, now + 12 * HOUR)).toMatchObject({ sent: 1 }); // under 30h left: send anyway
  });

  it("without a device, sends nothing and checks again later", async () => {
    await startTrial(user.userId, 40);
    expect(await sendTrialReminders(env, now)).toMatchObject({ due: 1, noDevice: 1, sent: 0 });
    await addDevice(user.token, 40);
    expect(await sendTrialReminders(env, now + HOUR)).toMatchObject({ sent: 1 });
  });

  it("forgets dead tokens and retries when Apple is busy", async () => {
    await startTrial(user.userId, 40);
    await addDevice(user.token, 50);
    apns = () => Response.json({ reason: "Unregistered" }, { status: 410 });
    expect((await sendTrialReminders(env, now)).sent).toBe(0);
    expect(await env.DB.prepare("SELECT 1 FROM push_devices WHERE token = ?1").bind(token(50)).first()).toBeNull();

    await addDevice(user.token, 51);
    apns = () => Response.json({ reason: "ServiceUnavailable" }, { status: 503 });
    expect((await sendTrialReminders(env, now)).sent).toBe(0);
    expect((await reminded(user.userId)).results).toHaveLength(0);
    apns = () => new Response(null, { status: 200 });
    expect((await sendTrialReminders(env, now + HOUR)).sent).toBe(1);
  });

  it("records a trial_reminder_sent event", async () => {
    const rows: EventRow[] = [];
    vi.spyOn(env.EVENTS, "send").mockImplementation(async (body) => (rows.push(body as EventRow), { metadata: {} } as QueueSendResponse));
    const endsAt = await startTrial(user.userId, 40, { product: "hercrown.plus.weekly" });
    await addDevice(user.token, 60);
    await sendTrialReminders(env, now);
    await vi.waitFor(() => expect(rows.some((r) => r.event === "trial_reminder_sent")).toBe(true));
    const event = rows.find((r) => r.event === "trial_reminder_sent")!;
    expect(event.event_id).toBe(`trial_reminder_sent:${user.userId}:${endsAt}`);
    expect(JSON.parse(event.props)).toEqual({ product_id: "hercrown.plus.weekly", devices: 1, hours_left: 40 });
  });

  it("does nothing without an APNs key (the in-app notice still works)", async () => {
    await startTrial(user.userId, 40);
    await addDevice(user.token, 70);
    expect(await sendTrialReminders({ ...env, APNS_PRIVATE_KEY: "" } as Env, now)).toMatchObject({ due: 0, sent: 0 });
    expect(pushes).toHaveLength(0);
  });
});

describe("the message", () => {
  const monday = Date.UTC(2027, 0, 4, 15, 0);
  it("names the day in the person's time zone", () => {
    const alert = reminderAlert(monday + 2 * DAY, "hercrown.plus.weekly", "America/Los_Angeles", monday);
    expect(alert).toMatchObject({
      title: "Your free trial ends in 2 days",
      body: "Her Crown Plus becomes a weekly plan on Wednesday, Jan 6. To avoid being charged, cancel before then in Settings → Subscriptions.",
    });
    expect(reminderAlert(monday + 20 * HOUR, null, "UTC", monday).title).toBe("Your free trial ends tomorrow");
    expect(reminderAlert(monday + 5 * HOUR, null, "UTC", monday).title).toBe("Your free trial ends today");
    expect(reminderAlert(monday + 10 * HOUR, null, "Asia/Tokyo", monday).title).toBe("Your free trial ends today"); // 00:00 → 10:00 Tuesday
  });

  it("signs the APNs token with the team id and key id", async () => {
    const jwt = await apnsJwt(env, monday);
    const [h, p, sig] = jwt.split(".");
    const decode = (s: string) => JSON.parse(atob(s.replace(/-/g, "+").replace(/_/g, "/")));
    expect(decode(h!)).toEqual({ alg: "ES256", typ: "JWT", kid: "APNSKEY123" });
    expect(decode(p!)).toEqual({ iss: "TEAM123456", iat: monday / 1000 });
    const der = Uint8Array.from(atob(env.TEST_APP_STORE_PUBLIC_KEY.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "")), (c) => c.charCodeAt(0));
    const key = await crypto.subtle.importKey("spki", der, { name: "ECDSA", namedCurve: "P-256" }, false, ["verify"]);
    const raw = Uint8Array.from(atob(sig!.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(sig!.length / 4) * 4, "=")), (c) => c.charCodeAt(0));
    expect(await crypto.subtle.verify({ name: "ECDSA", hash: "SHA-256" }, key, raw, new TextEncoder().encode(`${h}.${p}`))).toBe(true);
  });
});
