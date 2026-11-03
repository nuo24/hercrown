import { env } from "cloudflare:workers";
import { describe, expect, it } from "vitest";
import { moveUserData } from "../src/users";
import { api, signInGuest } from "./helpers";

const count = async (sql: string, ...params: unknown[]) =>
  (await env.DB.prepare(sql).bind(...params).first<{ n: number }>())!.n;

describe("health and sessions", () => {
  it("serves /health without a session", async () => {
    const res = await api("/health");
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ ok: true, env: "dev" });
  });

  it("rejects /me without a token", async () => {
    expect((await api("/me")).status).toBe(401);
    expect((await api("/me", { token: "not-a-real-token" })).status).toBe(401);
  });

  it("signs in a guest and authenticates with the bearer token", async () => {
    const { token, userId } = await signInGuest();
    const res = await api("/me", { token });
    expect(res.status).toBe(200);
    expect(await res.json()).toMatchObject({ user: { id: userId, isAnonymous: true, email: null } });
  });

  it("does not let a guest sign in anonymously again", async () => {
    const { token } = await signInGuest();
    const res = await api("/api/auth/sign-in/anonymous", { method: "POST", body: "{}", token });
    expect(res.status).toBe(400);
  });

  it("returns JSON 404 for unknown routes", async () => {
    const { token } = await signInGuest();
    const res = await api("/nope", { token });
    expect(res.status).toBe(404);
    expect(await res.json()).toEqual({ error: "not_found" });
  });
});

describe("account deletion", () => {
  it("deletes a guest and everything stored for them, including R2 files", async () => {
    const { token, userId } = await signInGuest();
    const key = `avatars/${userId}.jpg`;
    await env.FILES.put(key, "jpeg-bytes");
    await env.DB.batch([
      env.DB.prepare("INSERT INTO profiles (user_id, display_name, avatar_key, updated_at) VALUES (?1, 'Ada', ?2, 1)").bind(userId, key),
      env.DB.prepare("INSERT INTO preferences (user_id, updated_at) VALUES (?1, 1)").bind(userId),
      env.DB.prepare("INSERT INTO saved_passages VALUES (?1, 'PSA.23.1', 1)").bind(userId),
      env.DB.prepare("INSERT INTO reading_events VALUES ('ev-del', ?1, '2026-11-02', 'UTC', 1, NULL, NULL, NULL, 1)").bind(userId),
      env.DB.prepare("INSERT INTO entitlements VALUES (?1, 'plus', 'app_store', 'p', 'active', 9, 'otx', 1)").bind(userId),
      env.DB.prepare("INSERT INTO usage_ledger VALUES ('u-del', ?1, 'insight', 1, 10, 1)").bind(userId),
    ]);

    const res = await api("/api/auth/delete-anonymous-user", { method: "POST", body: "{}", token });
    expect(res.status).toBe(200);

    for (const table of ["profiles", "preferences", "saved_passages", "reading_events", "entitlements", "usage_ledger", "session"]) {
      const col = table === "session" ? '"userId"' : "user_id";
      expect(await count(`SELECT count(*) AS n FROM ${table} WHERE ${col} = ?1`, userId), table).toBe(0);
    }
    expect(await count('SELECT count(*) AS n FROM "user" WHERE id = ?1', userId)).toBe(0);
    expect(await env.FILES.get(key)).toBeNull();
    expect((await api("/me", { token })).status).toBe(401);
  });
});

describe("guest → account merge", () => {
  it("unions saves, reading and plans; keeps account preferences; carries over purchases", async () => {
    const guest = (await signInGuest()).userId;
    const account = (await signInGuest()).userId; // stands in for the Apple-linked account
    await env.FILES.put("avatars/guest.jpg", "g");
    await env.FILES.put("avatars/account.jpg", "a");

    await env.DB.batch([
      // Guest: did onboarding on this phone, saved two passages, read two days, bought Plus.
      env.DB.prepare(`INSERT INTO preferences (user_id, intention, topics, routine, onboarding_version, onboarding_completed_at, updated_at)
                      VALUES (?1, 'Find encouragement', '["Peace","Hope"]', '5 minutes', 2, 500, 1)`).bind(guest),
      env.DB.prepare("INSERT INTO profiles (user_id, display_name, bio, avatar_key, updated_at) VALUES (?1, 'Guest name', 'guest bio', 'avatars/guest.jpg', 1)").bind(guest),
      env.DB.prepare("INSERT INTO saved_passages VALUES (?1, 'PSA.23.1', 1), (?1, 'JER.29.11', 2)").bind(guest),
      env.DB.prepare(`INSERT INTO reading_events VALUES ('g1', ?1, '2026-11-01', 'UTC', 1, NULL, NULL, NULL, 1),
                                                        ('g2', ?1, '2026-11-02', 'UTC', 2, NULL, NULL, NULL, 2)`).bind(guest),
      env.DB.prepare("INSERT INTO plan_progress VALUES (?1, 'quiet', 100, 3, NULL, 1)").bind(guest),
      env.DB.prepare("INSERT INTO plan_step_completions VALUES (?1, 'quiet', 0, 1), (?1, 'quiet', 1, 1), (?1, 'quiet', 2, 1)").bind(guest),
      env.DB.prepare("INSERT INTO entitlements VALUES (?1, 'plus', 'app_store', 'biblescroll.plus.yearly', 'trialing', 2000, 'otx-guest', 1)").bind(guest),
      env.DB.prepare("INSERT INTO support_requests (id, user_id, category, message, created_at, updated_at) VALUES ('sr1', ?1, 'help', 'hi', 1, 1)").bind(guest),

      // Account: existing user from another device with their own name, avatar and settings.
      env.DB.prepare(`INSERT INTO preferences (user_id, intention, topics, appearance, onboarding_version, onboarding_completed_at, updated_at)
                      VALUES (?1, 'Grow closer to God', '[]', 'light', 2, 300, 1)`).bind(account),
      env.DB.prepare("INSERT INTO profiles (user_id, display_name, avatar_key, updated_at) VALUES (?1, 'Account name', 'avatars/account.jpg', 1)").bind(account),
      env.DB.prepare("INSERT INTO saved_passages VALUES (?1, 'PSA.23.1', 5), (?1, 'PRO.3.5', 6)").bind(account),
      env.DB.prepare("INSERT INTO reading_events VALUES ('a1', ?1, '2026-11-02', 'UTC', 3, NULL, NULL, NULL, 3)").bind(account),
      env.DB.prepare("INSERT INTO plan_progress VALUES (?1, 'quiet', 50, 1, NULL, 1)").bind(account),
      env.DB.prepare("INSERT INTO plan_step_completions VALUES (?1, 'quiet', 0, 1)").bind(account),
    ]);

    await moveUserData(env, guest, account);

    const saved = await env.DB.prepare("SELECT ref FROM saved_passages WHERE user_id = ?1 ORDER BY ref").bind(account).all();
    expect(saved.results.map((r) => r.ref)).toEqual(["JER.29.11", "PRO.3.5", "PSA.23.1"]);

    expect(await count("SELECT count(DISTINCT local_day) AS n FROM reading_events WHERE user_id = ?1", account)).toBe(2);
    expect(await count("SELECT count(*) AS n FROM reading_events WHERE user_id = ?1", account)).toBe(3);

    const prefs = await env.DB.prepare("SELECT * FROM preferences WHERE user_id = ?1").bind(account).first();
    expect(prefs).toMatchObject({
      intention: "Grow closer to God", // account wins
      topics: '["Peace","Hope"]', // account had none, guest fills in
      routine: "5 minutes",
      appearance: "light",
      onboarding_completed_at: 300, // earliest completion kept
    });

    const profile = await env.DB.prepare("SELECT * FROM profiles WHERE user_id = ?1").bind(account).first();
    expect(profile).toMatchObject({ display_name: "Account name", bio: "guest bio", avatar_key: "avatars/account.jpg" });
    expect(await env.FILES.get("avatars/guest.jpg")).toBeNull(); // superseded guest avatar removed
    expect(await env.FILES.get("avatars/account.jpg")).not.toBeNull();

    const plan = await env.DB.prepare("SELECT * FROM plan_progress WHERE user_id = ?1").bind(account).first();
    expect(plan).toMatchObject({ started_at: 50, current_position: 3 });
    expect(await count("SELECT count(*) AS n FROM plan_step_completions WHERE user_id = ?1", account)).toBe(3);

    const ent = await env.DB.prepare("SELECT * FROM entitlements WHERE user_id = ?1").bind(account).first();
    expect(ent).toMatchObject({ status: "trialing", original_transaction_id: "otx-guest" });

    expect(await count("SELECT count(*) AS n FROM support_requests WHERE user_id = ?1", account)).toBe(1);

    for (const table of ["preferences", "profiles", "saved_passages", "reading_events", "plan_progress", "plan_step_completions", "entitlements", "support_requests"]) {
      expect(await count(`SELECT count(*) AS n FROM ${table} WHERE user_id = ?1`, guest), table).toBe(0);
    }
  });

  it("keeps the account's entitlement when it runs longer than the guest's", async () => {
    const guest = (await signInGuest()).userId;
    const account = (await signInGuest()).userId;
    await env.DB.batch([
      env.DB.prepare("INSERT INTO entitlements VALUES (?1, 'plus', 'app_store', 'weekly', 'expired', 100, 'otx-g', 1)").bind(guest),
      env.DB.prepare("INSERT INTO entitlements VALUES (?1, 'plus', 'app_store', 'yearly', 'active', 9000, 'otx-a', 1)").bind(account),
    ]);
    await moveUserData(env, guest, account);
    const ent = await env.DB.prepare("SELECT * FROM entitlements WHERE user_id = ?1").bind(account).first();
    expect(ent).toMatchObject({ product_id: "yearly", status: "active", current_period_end: 9000 });
  });
});
