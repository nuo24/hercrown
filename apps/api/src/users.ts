// Moving a guest's data to a linked account, and removing a user's data on deletion.

const now = () => Date.now();

/**
 * Merge rules when a guest (`from`) links to an account (`to`):
 * - Saved passages, reading events, plan completions: union. Streaks dedupe by local day.
 * - Preferences and profile: the account's existing values win; the guest only fills blanks.
 *   Onboarding completion is never lost (earliest completion is kept).
 * - Plan progress: furthest position, earliest start, earliest completion.
 * - Entitlements: moved, keeping whichever period ends later, so a guest purchase carries over.
 * - Support requests and usage: moved.
 * All writes run in one D1 batch (a single transaction).
 */
export async function moveUserData(env: Env, from: string, to: string): Promise<void> {
  if (from === to) return;
  const db = env.DB;
  const t = now();

  // The guest's avatar is dropped from R2 if the account already has one.
  const avatars = await db
    .prepare("SELECT user_id, avatar_key FROM profiles WHERE user_id IN (?1, ?2)")
    .bind(from, to)
    .all<{ user_id: string; avatar_key: string | null }>();
  const fromAvatar = avatars.results.find((r) => r.user_id === from)?.avatar_key;
  const toAvatar = avatars.results.find((r) => r.user_id === to)?.avatar_key;

  await db.batch([
    db.prepare(
      `INSERT OR IGNORE INTO saved_passages (user_id, ref, created_at)
       SELECT ?2, ref, created_at FROM saved_passages WHERE user_id = ?1`,
    ).bind(from, to),
    db.prepare("DELETE FROM saved_passages WHERE user_id = ?1").bind(from),

    db.prepare("UPDATE reading_events SET user_id = ?2 WHERE user_id = ?1").bind(from, to),

    db.prepare(
      `INSERT INTO preferences (user_id, intention, familiarity, topics, routine, reminders_enabled, reminder_time,
         time_zone, appearance, gradient, onboarding_version, onboarding_completed_at, updated_at)
       SELECT ?2, intention, familiarity, topics, routine, reminders_enabled, reminder_time,
         time_zone, appearance, gradient, onboarding_version, onboarding_completed_at, ?3
       FROM preferences WHERE user_id = ?1
       ON CONFLICT (user_id) DO UPDATE SET
         intention   = COALESCE(preferences.intention, excluded.intention),
         familiarity = COALESCE(preferences.familiarity, excluded.familiarity),
         topics      = CASE WHEN preferences.topics = '[]' THEN excluded.topics ELSE preferences.topics END,
         routine     = COALESCE(preferences.routine, excluded.routine),
         time_zone   = COALESCE(preferences.time_zone, excluded.time_zone),
         gradient    = COALESCE(preferences.gradient, excluded.gradient),
         onboarding_version = MAX(COALESCE(preferences.onboarding_version, 0), COALESCE(excluded.onboarding_version, 0)),
         onboarding_completed_at = CASE
           WHEN preferences.onboarding_completed_at IS NULL THEN excluded.onboarding_completed_at
           WHEN excluded.onboarding_completed_at IS NULL THEN preferences.onboarding_completed_at
           ELSE MIN(preferences.onboarding_completed_at, excluded.onboarding_completed_at) END,
         updated_at  = ?3`,
    ).bind(from, to, t),
    db.prepare("DELETE FROM preferences WHERE user_id = ?1").bind(from),

    db.prepare(
      `INSERT INTO profiles (user_id, display_name, bio, avatar_key, updated_at)
       SELECT ?2, display_name, bio, avatar_key, ?3 FROM profiles WHERE user_id = ?1
       ON CONFLICT (user_id) DO UPDATE SET
         display_name = COALESCE(profiles.display_name, excluded.display_name),
         bio          = COALESCE(profiles.bio, excluded.bio),
         avatar_key   = COALESCE(profiles.avatar_key, excluded.avatar_key),
         updated_at   = ?3`,
    ).bind(from, to, t),
    db.prepare("DELETE FROM profiles WHERE user_id = ?1").bind(from),

    db.prepare(
      `INSERT INTO plan_progress (user_id, plan_id, started_at, current_position, completed_at, updated_at)
       SELECT ?2, plan_id, started_at, current_position, completed_at, ?3 FROM plan_progress WHERE user_id = ?1
       ON CONFLICT (user_id, plan_id) DO UPDATE SET
         started_at       = MIN(plan_progress.started_at, excluded.started_at),
         current_position = MAX(plan_progress.current_position, excluded.current_position),
         completed_at     = CASE
           WHEN plan_progress.completed_at IS NULL THEN excluded.completed_at
           WHEN excluded.completed_at IS NULL THEN plan_progress.completed_at
           ELSE MIN(plan_progress.completed_at, excluded.completed_at) END,
         updated_at       = ?3`,
    ).bind(from, to, t),
    db.prepare(
      `INSERT OR IGNORE INTO plan_step_completions (user_id, plan_id, position, completed_at)
       SELECT ?2, plan_id, position, completed_at FROM plan_step_completions WHERE user_id = ?1`,
    ).bind(from, to),
    db.prepare("DELETE FROM plan_progress WHERE user_id = ?1").bind(from), // cascades to completions

    db.prepare(
      `INSERT INTO entitlements (user_id, entitlement, source, product_id, status, current_period_end,
         original_transaction_id, updated_at, will_renew, period_type, environment, last_event_at)
       SELECT ?2, entitlement, source, product_id, status, current_period_end, original_transaction_id, ?3,
         will_renew, period_type, environment, last_event_at
       FROM entitlements WHERE user_id = ?1
       ON CONFLICT (user_id, entitlement) DO UPDATE SET
         source = excluded.source, product_id = excluded.product_id, status = excluded.status,
         current_period_end = excluded.current_period_end,
         original_transaction_id = excluded.original_transaction_id, updated_at = ?3,
         will_renew = excluded.will_renew, period_type = excluded.period_type,
         environment = excluded.environment, last_event_at = excluded.last_event_at
       WHERE COALESCE(excluded.current_period_end, 0) > COALESCE(entitlements.current_period_end, 0)`,
    ).bind(from, to, t),
    db.prepare("DELETE FROM entitlements WHERE user_id = ?1").bind(from),

    db.prepare("UPDATE support_requests SET user_id = ?2 WHERE user_id = ?1").bind(from, to),
    db.prepare("UPDATE usage_ledger SET user_id = ?2 WHERE user_id = ?1").bind(from, to),
    db.prepare("UPDATE push_devices SET user_id = ?2 WHERE user_id = ?1").bind(from, to),
    db.prepare(
      `INSERT OR IGNORE INTO trial_reminders (user_id, trial_ends_at, original_transaction_id, devices, sent_at)
       SELECT ?2, trial_ends_at, original_transaction_id, devices, sent_at FROM trial_reminders WHERE user_id = ?1`,
    ).bind(from, to),
  ]);

  if (fromAvatar && toAvatar && fromAvatar !== toAvatar) await env.FILES.delete(fromAvatar);
}

/**
 * Removes everything stored for a user before the auth row is deleted.
 * Tables with a foreign key to "user" cascade; the rest are cleared here, along with R2 files.
 * App Store subscriptions keep billing until the user cancels them with Apple.
 */
export async function deleteUserData(env: Env, userId: string): Promise<void> {
  const profile = await env.DB
    .prepare("SELECT avatar_key FROM profiles WHERE user_id = ?1")
    .bind(userId)
    .first<{ avatar_key: string | null }>();
  if (profile?.avatar_key) await env.FILES.delete(profile.avatar_key);

  await env.DB.batch([
    env.DB.prepare("DELETE FROM entitlements WHERE user_id = ?1").bind(userId),
    env.DB.prepare("DELETE FROM usage_ledger WHERE user_id = ?1").bind(userId),
    env.DB.prepare("DELETE FROM entitlement_transfers WHERE from_user_id = ?1 OR to_user_id = ?1").bind(userId),
  ]);
}
