import { env } from "cloudflare:workers";
import { afterEach, describe, expect, it, vi } from "vitest";
import { checkHealth, sendHealthAlerts } from "../src/alerts";

afterEach(() => vi.restoreAllMocks());
const withTinybird = (errors: number) => {
  vi.spyOn(globalThis, "fetch").mockImplementation(async (input) => {
    expect(String(input)).toContain("/v0/sql?q=");
    return Response.json({ data: [{ n: errors }] });
  });
  return { ...env, TINYBIRD_READ_TOKEN: "p.read" } as unknown as Env;
};

describe("health alerts", () => {
  it("stays quiet when things are healthy", async () => {
    expect(await checkHealth(withTinybird(3), Date.now())).toEqual([]);
  });

  it("flags error spikes, AI spend and unmatched purchases, emailing each once per hour", async () => {
    const now = Date.now();
    await env.DB.batch([
      env.DB.prepare("INSERT INTO usage_ledger (id, user_id, feature, units, cost_micros, created_at) VALUES ('a1', 'u', 'study_explain', 1, 2500000, ?1)").bind(now - 60_000),
      env.DB.prepare("INSERT INTO unmatched_store_events (id, app_user_id, original_transaction_id, type, payload, received_at) VALUES ('w1', 'ghost', 'otx', 'initial_purchase', '{}', ?1)").bind(now - 60_000),
    ]);
    const sent: any[] = [];
    vi.spyOn(env.EMAIL, "send").mockImplementation(async (m: any) => (sent.push(m), { messageId: "x" }));
    const e = withTinybird(40);
    const alerts = await sendHealthAlerts(e, now);
    expect(alerts.map((a) => a.key)).toEqual(["errors", "ai_spend", "unmatched_purchases"]);
    expect(sent.map((m) => m.subject)).toEqual([
      "[Her Crown dev] 40 errors in the last hour",
      "[Her Crown dev] AI spend $2.50 in the last hour",
      "[Her Crown dev] 1 purchase event(s) not matched to an account",
    ]);
    expect(sent[0].to).toBe("team@biblescroll.test"); // SUPPORT_INBOX when ALERT_INBOX is empty
    await sendHealthAlerts(e, now + 60_000); // same hour: no repeat emails
    expect(sent).toHaveLength(3);
  });

  it("skips the error check without a Tinybird read token", async () => {
    const fetchSpy = vi.spyOn(globalThis, "fetch");
    expect((await checkHealth(env, Date.now() + 10 * 3_600_000)).find((a) => a.key === "errors")).toBeUndefined();
    expect(fetchSpy).not.toHaveBeenCalled();
  });
});
