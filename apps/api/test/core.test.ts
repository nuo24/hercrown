import { env } from "cloudflare:workers";
import { beforeEach, describe, expect, it } from "vitest";
import { BOOKS, normalizeRef } from "../src/refs";
import { api, grantPremium, signInGuest } from "./helpers";

let token: string;
let userId: string;
beforeEach(async () => ({ token, userId } = await signInGuest()));

const json = (body: unknown) => ({ body: JSON.stringify(body), token });
const patch = (path: string, body: unknown) => api(path, { method: "PATCH", ...json(body) });
const post = (path: string, body: unknown = {}) => api(path, { method: "POST", ...json(body) });

describe("GET /me", () => {
  it("returns defaults for a brand-new guest", async () => {
    const me = await (await api("/me", { token })).json<any>();
    expect(me).toEqual({
      user: { id: userId, isAnonymous: true, email: null },
      profile: { displayName: null, bio: null, avatarUrl: null },
      preferences: {
        intention: null, familiarity: null, topics: [], routine: null, remindersEnabled: false,
        reminderTime: "08:00", timeZone: null, appearance: "dark", gradient: null,
      },
      onboarding: { completed: false, completedAt: null, version: null },
      membership: { premium: false, subscription: null },
    });
  });
});

describe("profile", () => {
  it("updates name and bio, trimming whitespace", async () => {
    const res = await patch("/me/profile", { displayName: "  Ada ", bio: "Making a little room." });
    expect(await res.json()).toMatchObject({ displayName: "Ada", bio: "Making a little room." });
    // Partial update keeps the other field.
    expect(await (await patch("/me/profile", { bio: null })).json()).toMatchObject({ displayName: "Ada", bio: null });
  });

  it("enforces the prototype's limits", async () => {
    expect((await patch("/me/profile", { displayName: "" })).status).toBe(400);
    expect((await patch("/me/profile", { displayName: "x".repeat(41) })).status).toBe(400);
    expect((await patch("/me/profile", { bio: "x".repeat(181) })).status).toBe(400);
    expect((await patch("/me/profile", { displayName: 5 })).status).toBe(400);
    expect((await api("/me/profile", { method: "PATCH", body: "not json", token })).status).toBe(400);
  });
});

describe("avatar", () => {
  const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3, 4]);
  const png = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const upload = (bytes: Uint8Array, type = "image/jpeg") =>
    api("/me/avatar", { method: "PUT", body: bytes, headers: { "content-type": type }, token });

  it("uploads, serves privately, replaces and removes", async () => {
    const first = await (await upload(jpeg)).json<any>();
    expect(first.avatarUrl).toMatch(/^\/me\/avatar\?v=\d+$/);
    const firstKey = (await env.DB.prepare("SELECT avatar_key FROM profiles WHERE user_id = ?1").bind(userId).first<any>()).avatar_key;

    const served = await api("/me/avatar", { token });
    expect(served.status).toBe(200);
    expect(served.headers.get("content-type")).toBe("image/jpeg");
    expect(new Uint8Array(await served.arrayBuffer())).toEqual(jpeg);
    expect((await api("/me/avatar")).status).toBe(401); // not public

    await upload(png, "image/png");
    expect(await env.FILES.get(firstKey)).toBeNull(); // old file removed on replace
    expect((await api("/me/avatar", { token })).headers.get("content-type")).toBe("image/png");

    expect(await (await api("/me/avatar", { method: "DELETE", token })).json()).toMatchObject({ avatarUrl: null });
    expect((await api("/me/avatar", { token })).status).toBe(404);
  });

  it("rejects files that are not JPG, PNG or WebP, whatever the header says", async () => {
    const res = await upload(new TextEncoder().encode("<svg></svg>"), "image/jpeg");
    expect(res.status).toBe(415);
    expect((await upload(new Uint8Array())).status).toBe(400);
  });

  it("rejects photos over 10 MB", async () => {
    const big = new Uint8Array(10 * 1024 * 1024 + 1);
    big.set(jpeg);
    expect((await upload(big)).status).toBe(413);
  });
});

describe("preferences and onboarding", () => {
  it("saves onboarding answers and settings", async () => {
    const res = await patch("/me/preferences", {
      intention: "Find encouragement",
      familiarity: "A little familiar",
      topics: ["Hope", "Peace", "Hope"],
      routine: "5 minutes",
      remindersEnabled: true,
      reminderTime: "07:30",
      timeZone: "America/Chicago",
      appearance: "light",
      gradient: { colors: ["#e4eddf", "#e0edf5", "#eadff0"], third: false, intensity: 100, spread: 49, angle: 165 },
    });
    expect(res.status).toBe(200);
    expect(await res.json()).toMatchObject({
      topics: ["Peace", "Hope"], // deduped, canonical order
      remindersEnabled: true,
      reminderTime: "07:30",
      gradient: { spread: 49, angle: 165 },
    });
  });

  it("clears a skipped answer with null and leaves other fields alone", async () => {
    await patch("/me/preferences", { intention: "Find encouragement", routine: "2 minutes" });
    const prefs = await (await patch("/me/preferences", { intention: null })).json<any>();
    expect(prefs).toMatchObject({ intention: null, routine: "2 minutes" });
  });

  it("rejects values outside the onboarding options", async () => {
    for (const body of [
      { intention: "Something else" },
      { topics: ["Peace", "Money"] },
      { topics: "Peace" },
      { routine: "1 hour" },
      { reminderTime: "25:00" },
      { timeZone: "Mars/Olympus" },
      { appearance: "sepia" },
      { remindersEnabled: "yes" },
      { gradient: { colors: ["red"], third: false, intensity: 100, spread: 49, angle: 165 } },
    ]) {
      expect((await patch("/me/preferences", body)).status, JSON.stringify(body)).toBe(400);
    }
  });

  it("completes onboarding once, and Settings edits never reset it", async () => {
    const first = await (await post("/me/onboarding/complete")).json<any>();
    expect(first).toMatchObject({ completed: true, version: 2 });
    const again = await (await post("/me/onboarding/complete")).json<any>();
    expect(again.completedAt).toBe(first.completedAt);

    await patch("/me/preferences", { topics: ["Faith"], appearance: "light", onboardingCompletedAt: null, onboarding_completed_at: null });
    const me = await (await api("/me", { token })).json<any>();
    expect(me.onboarding).toMatchObject({ completed: true, completedAt: first.completedAt });
  });
});

describe("saved passages", () => {
  it("saves idempotently, accepts prototype ids and unsaves", async () => {
    await api("/me/saved/PSA.23.1", { method: "PUT", token });
    await api("/me/saved/ps23", { method: "PUT", token }); // same passage via alias
    const { saved } = await (await api("/me/saved/JER.29.11", { method: "PUT", token })).json<any>();
    expect(saved.map((s: any) => s.ref).sort()).toEqual(["JER.29.11", "PSA.23.1"]);

    const after = await (await api("/me/saved/ps23", { method: "DELETE", token })).json<any>();
    expect(after.saved.map((s: any) => s.ref)).toEqual(["JER.29.11"]);
    expect((await (await api("/me/saved", { token })).json<any>()).saved).toHaveLength(1);
  });

  it("rejects malformed and impossible references", async () => {
    for (const ref of ["PSA.151.1", "XYZ.1.1", "PSA.23", "psalm23", "PSA.23.5-2", "zz99"]) {
      expect((await api(`/me/saved/${ref}`, { method: "PUT", token })).status, ref).toBe(400);
    }
  });

  it("keeps each user's saves separate", async () => {
    await api("/me/saved/PSA.23.1", { method: "PUT", token });
    const other = await signInGuest();
    expect((await (await api("/me/saved", { token: other.token })).json<any>()).saved).toEqual([]);
  });
});

describe("reading events and streak", () => {
  const event = (id: string, localDay: string) => ({ id, localDay, timeZone: "America/Chicago" });

  it("records days, ignores retried uploads and computes the streak", async () => {
    const body = { events: [event("evt-00000001", "2026-10-31"), event("evt-00000002", "2026-11-01")], today: "2026-11-01" };
    await post("/me/reading-events", body);
    const res = await post("/me/reading-events", body); // retry
    expect((await res.json<any>()).streak).toMatchObject({ current: 2, best: 2, readToday: true });
    expect((await env.DB.prepare("SELECT count(*) AS n FROM reading_events WHERE user_id = ?1").bind(userId).first<any>()).n).toBe(2);

    // Two readings on the same day still count once.
    await post("/me/reading-events", { events: [event("evt-00000003", "2026-11-01")] });
    const streak = (await (await api("/me/streak?today=2026-11-02", { token })).json<any>()).streak;
    expect(streak).toMatchObject({ current: 2, readToday: false });
    expect((await (await api("/me/streak?today=2026-11-03", { token })).json<any>()).streak.current).toBe(0);
  });

  it("stores the passage and plan context", async () => {
    await post("/me/reading-events", { events: [{ ...event("evt-ctx-0001", "2026-11-01"), ref: "ps23", planId: "quiet", planStep: 0 }] });
    const row = await env.DB.prepare("SELECT ref, plan_id, plan_step FROM reading_events WHERE id = 'evt-ctx-0001'").first();
    expect(row).toEqual({ ref: "PSA.23.1", plan_id: "quiet", plan_step: 0 });
  });

  it("rejects future, invalid and malformed events", async () => {
    const future = new Date(Date.now() + 3 * 86_400_000).toISOString().slice(0, 10);
    for (const events of [
      [event("evt-future-1", future)],
      [event("evt-bad-day1", "2026-02-30")],
      [event("short", "2026-11-01")],
      [{ id: "evt-no-tz-01", localDay: "2026-11-01" }],
      [],
      Array.from({ length: 101 }, (_, i) => event(`evt-many-${String(i).padStart(4, "0")}`, "2026-11-01")),
    ]) {
      expect((await post("/me/reading-events", { events })).status).toBe(400);
    }
    expect((await api("/me/streak?today=nope", { token })).status).toBe(400);
  });

  it("uses the saved time zone when the client doesn't send today", async () => {
    await patch("/me/preferences", { timeZone: "Pacific/Kiritimati" });
    const { streak } = await (await api("/me/streak", { token })).json<any>();
    const kiritimatiToday = new Intl.DateTimeFormat("en-CA", { timeZone: "Pacific/Kiritimati" }).format(new Date());
    expect(streak.week.at(-1).day).toBe(kiritimatiToday);
  });
});

describe("reading plans", () => {
  beforeEach(() => grantPremium(userId));

  it("lists the three plans with their passages", async () => {
    const { plans, activePlanId } = await (await api("/plans", { token })).json<any>();
    expect(plans.map((p: any) => [p.id, p.days])).toEqual([["quiet", 5], ["peace", 3], ["strength", 3]]);
    expect(plans[0].steps.map((s: any) => s.ref)).toEqual(["PSA.23.1", "PRO.3.5", "MAT.11.28", "PSA.119.105", "PSA.107.1"]);
    expect(activePlanId).toBeNull();
  });

  it("starts, resumes and completes a plan", async () => {
    const started = await (await post("/plans/peace/start")).json<any>();
    expect(started.progress).toMatchObject({ nextPosition: 0, completedSteps: 0, completedAt: null });

    let plan = await (await post("/plans/peace/steps/0/complete")).json<any>();
    expect(plan.progress.nextPosition).toBe(1);
    plan = await (await post("/plans/peace/steps/2/complete")).json<any>(); // out of order
    expect(plan.progress.nextPosition).toBe(1);
    plan = await (await post("/plans/peace/steps/2/complete")).json<any>(); // repeat is harmless
    expect(plan.progress.completedSteps).toBe(2);

    plan = await (await post("/plans/peace/steps/1/complete")).json<any>();
    expect(plan.progress).toMatchObject({ nextPosition: null, completedSteps: 3 });
    expect(plan.progress.completedAt).toEqual(expect.any(Number));
    expect(plan.steps.every((s: any) => s.completedAt)).toBe(true);
  });

  it("tracks the active plan for Discover", async () => {
    await post("/plans/quiet/start");
    await post("/plans/strength/start");
    expect((await (await api("/plans", { token })).json<any>()).activePlanId).toBe("strength");
    await post("/plans/quiet/steps/0/complete");
    expect((await (await api("/plans", { token })).json<any>()).activePlanId).toBe("quiet");
  });

  it("completing a step starts the plan automatically", async () => {
    const plan = await (await post("/plans/strength/steps/0/complete")).json<any>();
    expect(plan.progress).toMatchObject({ nextPosition: 1, completedSteps: 1 });
  });

  it("404s unknown plans and 400s out-of-range steps", async () => {
    expect((await api("/plans/nope", { token })).status).toBe(404);
    expect((await post("/plans/nope/start")).status).toBe(404);
    expect((await post("/plans/peace/steps/3/complete")).status).toBe(400);
    expect((await post("/plans/peace/steps/-1/complete")).status).toBe(400);
    expect((await post("/plans/peace/steps/abc/complete")).status).toBe(400);
  });
});

describe("references", () => {
  it("has the full 66-book canon with 1,189 chapters", () => {
    expect(BOOKS).toHaveLength(66);
    expect(BOOKS.reduce((n, b) => n + b[3], 0)).toBe(1189);
  });

  it("normalizes ranges and rejects out-of-bounds chapters", () => {
    expect(normalizeRef("MAT.11.28-30")).toBe("MAT.11.28-30");
    expect(normalizeRef("MAT.11.28-28")).toBe("MAT.11.28");
    expect(normalizeRef("PSA.023.001")).toBe("PSA.23.1");
    expect(normalizeRef("JUD.2.1")).toBeNull();
    expect(normalizeRef("PSA.0.1")).toBeNull();
  });
});
