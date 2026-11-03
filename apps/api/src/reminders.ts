// Trial-ending reminder. Scroll the Bible's paywall promises a "Trial reminder", and its #2 complaint is being
// charged without one. Ours comes from the server, which knows each trial's real end date and whether it was
// already cancelled (a local notification scheduled at purchase can't know either). See docs/trial-reminder.md.
import { ENTITLEMENT } from "./billing";
import { Tracker } from "./events";
import { type Alert, apnsJwt, type PushDevice, pushConfigured, sendPush } from "./push";

const HOUR = 3_600_000;
const MIN_HOURS_LEFT = 12; // a reminder later than this is too late to be useful
const URGENT_HOURS = 30; // under this, send even during quiet hours
const QUIET = { from: 21, to: 9 }; // local time
export const MANAGE_SUBSCRIPTIONS_URL = "https://apps.apple.com/account/subscriptions";

/** How long before the trial ends to remind (TRIAL_REMINDER_LEAD_HOURS, default 48: day 5 of a 7-day trial). */
export function leadHours(env: Env): number {
  const n = Number(env.TRIAL_REMINDER_LEAD_HOURS);
  return Number.isFinite(n) && n >= MIN_HOURS_LEFT ? n : 48;
}

/** For GET /me and /me/entitlements: what the app shows on Home and in Settings → Subscription. */
export function trialInfo(env: Env, endsAt: number | null, willRenew: boolean) {
  if (!endsAt) return null;
  return {
    endsAt,
    convertsToPaid: willRenew, // false once cancelled: access continues until endsAt, no charge
    remindFrom: endsAt - leadHours(env) * HOUR, // show the in-app notice from here (if convertsToPaid)
    manageUrl: MANAGE_SUBSCRIPTIONS_URL,
  };
}

const PLAN: Record<string, string> = {
  "biblescroll.plus.yearly": "a yearly plan",
  "biblescroll.plus.weekly": "a weekly plan",
};

/** The notification. No price: the App Store price depends on the country; the app shows it from StoreKit. */
export function reminderAlert(endsAt: number, productId: string | null, timeZone: string, now: number): Alert {
  const date = new Intl.DateTimeFormat("en-US", { timeZone, weekday: "long", month: "short", day: "numeric" }).format(endsAt);
  const days = localDay(endsAt, timeZone) - localDay(now, timeZone);
  const when = days <= 0 ? "today" : days === 1 ? "tomorrow" : `in ${days} days`;
  const plan = PLAN[productId ?? ""] ?? "a paid plan";
  return {
    title: `Your free trial ends ${when}`,
    body: `Her Crown Plus becomes ${plan} on ${date}. To avoid being charged, cancel before then in Settings → Subscriptions.`,
    link: "hercrown://settings/subscription",
    collapseId: `trial-${endsAt}`,
  };
}

function localDay(ms: number, timeZone: string): number {
  const [y, m, d] = new Intl.DateTimeFormat("en-CA", { timeZone, year: "numeric", month: "2-digit", day: "2-digit" })
    .format(ms).split("-").map(Number);
  return Date.UTC(y!, m! - 1, d!) / (24 * HOUR);
}

function localHour(ms: number, timeZone: string): number {
  return Number(new Intl.DateTimeFormat("en-US", { timeZone, hour: "numeric", hourCycle: "h23" }).format(ms));
}

interface DueTrial {
  user_id: string;
  ends_at: number;
  original_transaction_id: string | null;
  product_id: string | null;
  environment: string | null;
}

/**
 * Runs from the Cron Trigger (every 15 minutes). Reminds each trial that converts to paid within the lead time,
 * once, at a decent local hour. Trials without a registered device get only the in-app notice (`trialInfo`).
 */
export async function sendTrialReminders(env: Env, now = Date.now(), ctx?: Pick<ExecutionContext, "waitUntil">) {
  const summary = { due: 0, sent: 0, waiting: 0, noDevice: 0 };
  if (!pushConfigured(env)) {
    console.log("reminders: APNs not configured; trials get the in-app notice only");
    return summary;
  }
  const due = await env.DB.prepare(
    `SELECT e.user_id, e.current_period_end AS ends_at, e.original_transaction_id, e.product_id, e.environment
     FROM entitlements e
     WHERE e.entitlement = ?1 AND e.status = 'trialing' AND e.will_renew = 1
       AND e.current_period_end > ?2 AND e.current_period_end <= ?3
       AND NOT EXISTS (SELECT 1 FROM trial_reminders r WHERE r.user_id = e.user_id AND r.trial_ends_at = e.current_period_end)
     ORDER BY e.current_period_end LIMIT 200`,
  ).bind(ENTITLEMENT, now + MIN_HOURS_LEFT * HOUR, now + leadHours(env) * HOUR).all<DueTrial>();
  summary.due = due.results.length;
  if (summary.due === 0) return summary;

  const jwt = await apnsJwt(env, now);
  for (const trial of due.results) {
    const devices = (await env.DB.prepare("SELECT token, environment, time_zone FROM push_devices WHERE user_id = ?1")
      .bind(trial.user_id).all<PushDevice>()).results;
    if (devices.length === 0) {
      summary.noDevice++;
      continue; // checked again next run, in case notifications get turned on
    }
    const timeZone = devices.find((d) => d.time_zone)?.time_zone ?? "UTC";
    const hoursLeft = (trial.ends_at - now) / HOUR;
    const hour = localHour(now, timeZone);
    if (hoursLeft > URGENT_HOURS && (hour >= QUIET.from || hour < QUIET.to)) {
      summary.waiting++;
      continue;
    }

    const alert = reminderAlert(trial.ends_at, trial.product_id, timeZone, now);
    const results = await Promise.all(devices.map((d) => sendPush(env, jwt, d, alert)));
    const gone = devices.filter((_, i) => results[i] === "gone").map((d) => d.token);
    if (gone.length) {
      await env.DB.batch(gone.map((token) => env.DB.prepare("DELETE FROM push_devices WHERE token = ?1").bind(token)));
    }
    const sent = results.filter((r) => r === "sent").length;
    if (sent === 0) continue; // Apple busy or every token stale: try again next run
    await env.DB.prepare(
      `INSERT OR IGNORE INTO trial_reminders (user_id, trial_ends_at, original_transaction_id, devices, sent_at)
       VALUES (?1, ?2, ?3, ?4, ?5)`,
    ).bind(trial.user_id, trial.ends_at, trial.original_transaction_id, sent, now).run();
    summary.sent++;
    new Tracker(env, ctx).track("trial_reminder_sent", {
      product_id: trial.product_id, devices: sent, hours_left: Math.round(hoursLeft),
    }, { userId: trial.user_id, id: `trial_reminder_sent:${trial.user_id}:${trial.ends_at}`, sandbox: trial.environment === "SANDBOX" });
  }
  console.log("reminders:", JSON.stringify(summary));
  return summary;
}
