// Hourly health checks (ai-app-playbook chapter 08): error spikes (Tinybird), AI spend (usage_ledger) and purchases that
// couldn't be matched to an account (unmatched_store_events). Each problem emails ALERT_INBOX (default SUPPORT_INBOX)
// at most once per hour; without email set up it's logged to Workers Observability instead.
import { emailConfigured, sendEmail } from "./email";

const HOUR = 3_600_000;

export interface Alert { key: string; subject: string; detail: string }

async function errorsLastHour(env: Env): Promise<number | null> {
  if (!env.TINYBIRD_READ_TOKEN) return null;
  const sql = `SELECT count() AS n FROM events WHERE event = 'error' AND environment = '${env.APP_ENV}' AND timestamp > now() - INTERVAL 1 HOUR FORMAT JSON`;
  try {
    const res = await fetch(`${env.TINYBIRD_HOST}/v0/sql?q=${encodeURIComponent(sql)}`, {
      headers: { authorization: `Bearer ${env.TINYBIRD_READ_TOKEN}` }, signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok) return null;
    return Number(((await res.json()) as { data?: { n: number | string }[] }).data?.[0]?.n ?? 0);
  } catch {
    return null;
  }
}

/** What's wrong right now (empty when healthy). */
export async function checkHealth(env: Env, now = Date.now()): Promise<Alert[]> {
  const alerts: Alert[] = [];
  const since = now - HOUR;

  const errors = await errorsLastHour(env);
  const maxErrors = Number(env.ALERT_ERRORS_PER_HOUR) || 25;
  if (errors !== null && errors >= maxErrors) {
    alerts.push({ key: "errors", subject: `${errors} errors in the last hour`, detail: `Errors (app and server) in the last hour: ${errors} (alert at ${maxErrors}). See the Tinybird errors endpoint and Workers Observability logs.` });
  }

  const spend = await env.DB.prepare("SELECT coalesce(sum(cost_micros), 0) AS micros, count(*) AS calls FROM usage_ledger WHERE created_at > ?1")
    .bind(since).first<{ micros: number; calls: number }>();
  const maxSpend = Number(env.ALERT_AI_USD_PER_HOUR) || 2;
  const usd = (spend?.micros ?? 0) / 1_000_000;
  if (usd >= maxSpend) {
    alerts.push({ key: "ai_spend", subject: `AI spend $${usd.toFixed(2)} in the last hour`, detail: `${spend!.calls} AI calls cost $${usd.toFixed(2)} in the last hour (alert at $${maxSpend}). Check usage_ledger by user for abuse; lower STUDY_DAILY_LIMIT if needed.` });
  }

  const unmatched = await env.DB.prepare("SELECT count(*) AS n FROM unmatched_store_events WHERE received_at > ?1").bind(since).first<{ n: number }>();
  if ((unmatched?.n ?? 0) > 0) {
    alerts.push({ key: "unmatched_purchases", subject: `${unmatched!.n} purchase event(s) not matched to an account`, detail: `Superwall sent ${unmatched!.n} purchase event(s) in the last hour for users we don't know. Usually the app didn't call Superwall.identify(userId:) after sign-in. Rows are in unmatched_store_events.` });
  }
  return alerts;
}

/** Runs from the Cron Trigger once an hour. */
export async function sendHealthAlerts(env: Env, now = Date.now()): Promise<Alert[]> {
  const alerts = await checkHealth(env, now);
  const hour = Math.floor(now / HOUR);
  const inbox = env.ALERT_INBOX || env.SUPPORT_INBOX;
  for (const alert of alerts) {
    const dedupe = `alert:${alert.key}:${hour}`;
    if (await env.KV.get(dedupe)) continue;
    await env.KV.put(dedupe, "1", { expirationTtl: 2 * 3600 });
    console.error(`ALERT [${env.APP_ENV}] ${alert.subject}: ${alert.detail}`);
    if (emailConfigured(env) && inbox) {
      try {
        await sendEmail(env, { to: inbox, subject: `[Her Crown ${env.APP_ENV}] ${alert.subject}`, text: alert.detail });
      } catch (err) {
        console.error("alerts: email failed", err instanceof Error ? err.message : err);
      }
    }
  }
  return alerts;
}
