import { env } from "cloudflare:workers";
import { beforeEach, describe, expect, it } from "vitest";
import { api, signInGuest } from "./helpers";

let token: string, userId: string;
beforeEach(async () => ({ token, userId } = await signInGuest()));
const setPreference = (subscribed: unknown, extra = {}) => api("/me/email-preferences", {
  method: "PUT", token, body: JSON.stringify({ subscribed, ...extra }),
});

describe("email-list consent", () => {
  it("requires authentication and never opts guests or new accounts in automatically", async () => {
    expect((await api("/me/email-preferences")).status).toBe(401);
    expect(await (await api("/me/email-preferences", { token })).json()).toEqual({ subscribed: false });
    expect((await setPreference(true)).status).toBe(403);
    expect(await env.DB.prepare("SELECT count(*) AS n FROM email_preferences").first()).toEqual({ n: 0 });
  });
  it("uses the verified sign-in email, supports withdrawal, isolates accounts and cascades deletion", async () => {
    await env.DB.prepare('UPDATE user SET isAnonymous = 0, emailVerified = 1, email = ?1 WHERE id = ?2')
      .bind("relay@example.test", userId).run();
    expect((await setPreference("yes")).status).toBe(400);
    expect((await setPreference(true, { email: "injected@example.test" })).status).toBe(200);
    expect(await (await api("/me/email-preferences", { token })).json()).toEqual({ subscribed: true });
    const email = await env.DB.prepare(`SELECT u.email FROM email_preferences p JOIN user u ON u.id=p.user_id
      WHERE p.subscribed=1 AND u.emailVerified=1 AND u.isAnonymous=0`).all();
    expect(email.results).toEqual([{ email: "relay@example.test" }]);
    const other = await signInGuest();
    expect(await (await api("/me/email-preferences", { token: other.token })).json()).toEqual({ subscribed: false });
    await setPreference(false);
    expect(await (await api("/me/email-preferences", { token })).json()).toEqual({ subscribed: false });
    await setPreference(true);
    expect((await api("/api/auth/delete-user", { method: "POST", token, body: "{}" })).status).toBe(200);
    expect(await env.DB.prepare("SELECT count(*) AS n FROM email_preferences WHERE user_id=?1").bind(userId).first()).toEqual({ n: 0 });
  });
});
