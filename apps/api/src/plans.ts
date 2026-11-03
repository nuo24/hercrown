// Reading plans: definitions, start, step completion and resume position.
import { entitlementFor, requirePremium } from "./billing";
import { badRequest, notFound } from "./http";
import type { SessionUser } from "./profile";

interface PlanRow {
  id: string;
  title: string;
  description: string;
  topic: string | null;
  tone: string | null;
}

interface ProgressRow {
  plan_id: string;
  started_at: number;
  current_position: number;
  completed_at: number | null;
  updated_at: number;
}

async function loadPlans(env: Env, userId: string, planId?: string) {
  const only = planId ?? null; // NULL = all plans
  const [plans, steps, progress, completions] = await env.DB.batch([
    env.DB.prepare("SELECT id, title, description, topic, tone FROM plans WHERE published = 1 AND (?1 IS NULL OR id = ?1) ORDER BY position")
      .bind(only),
    env.DB.prepare(`SELECT s.plan_id, s.position, s.ref FROM plan_steps s JOIN plans p ON p.id = s.plan_id
                    WHERE p.published = 1 AND (?1 IS NULL OR s.plan_id = ?1) ORDER BY s.plan_id, s.position`)
      .bind(only),
    env.DB.prepare(`SELECT plan_id, started_at, current_position, completed_at, updated_at FROM plan_progress
                    WHERE user_id = ?1 AND (?2 IS NULL OR plan_id = ?2)`)
      .bind(userId, only),
    env.DB.prepare(`SELECT plan_id, position, completed_at FROM plan_step_completions
                    WHERE user_id = ?1 AND (?2 IS NULL OR plan_id = ?2)`)
      .bind(userId, only),
  ]);

  const stepsByPlan = Map.groupBy(steps.results as { plan_id: string; position: number; ref: string }[], (s) => s.plan_id);
  const doneByPlan = Map.groupBy(completions.results as { plan_id: string; position: number; completed_at: number }[], (c) => c.plan_id);
  const progressByPlan = new Map((progress.results as unknown as ProgressRow[]).map((p) => [p.plan_id, p]));

  return (plans.results as unknown as PlanRow[]).map((plan) => {
    const planSteps = stepsByPlan.get(plan.id) ?? [];
    const done = new Map((doneByPlan.get(plan.id) ?? []).map((c) => [c.position, c.completed_at]));
    const p = progressByPlan.get(plan.id);
    return {
      id: plan.id,
      title: plan.title,
      description: plan.description,
      topic: plan.topic,
      tone: plan.tone,
      days: planSteps.length,
      steps: planSteps.map((s) => ({ position: s.position, ref: s.ref, completedAt: done.get(s.position) ?? null })),
      progress: p
        ? {
            startedAt: p.started_at,
            nextPosition: p.completed_at ? null : p.current_position, // resume here
            completedSteps: done.size,
            completedAt: p.completed_at,
            updatedAt: p.updated_at,
          }
        : null,
    };
  });
}

/** Plans are Premium: anyone can browse them; starting and progressing needs Plus (`locked` tells the app). */
export async function listPlans(env: Env, user: SessionUser) {
  const [plans, { premium }] = await Promise.all([loadPlans(env, user.id), entitlementFor(env, user.id)]);
  // The plan shown as "Plan" in Discover: most recently touched plan that isn't finished.
  const active = plans
    .filter((p) => p.progress && !p.progress.completedAt)
    .sort((a, b) => b.progress!.updatedAt - a.progress!.updatedAt)[0];
  return Response.json({ plans, activePlanId: active?.id ?? null, locked: !premium });
}

async function onePlan(env: Env, userId: string, planId: string) {
  const [plan] = await loadPlans(env, userId, planId);
  if (!plan) throw notFound(`No plan "${planId}"`);
  return plan;
}

export async function getPlan(env: Env, user: SessionUser, planId: string) {
  return Response.json(await onePlan(env, user.id, planId));
}

/** Starting is idempotent; starting an in-progress plan just marks it as the active one. */
export async function startPlan(env: Env, user: SessionUser, planId: string) {
  await onePlan(env, user.id, planId);
  await requirePremium(env, user.id);
  const t = Date.now();
  await env.DB.prepare(
    `INSERT INTO plan_progress (user_id, plan_id, started_at, current_position, updated_at) VALUES (?1, ?2, ?3, 0, ?3)
     ON CONFLICT (user_id, plan_id) DO UPDATE SET updated_at = ?3`,
  ).bind(user.id, planId, t).run();
  return Response.json(await onePlan(env, user.id, planId));
}

/**
 * Completes one step (starting the plan if needed). Steps may be done out of order;
 * the resume position becomes the first step not yet completed.
 */
export async function completePlanStep(env: Env, user: SessionUser, planId: string, position: number) {
  const plan = await onePlan(env, user.id, planId);
  await requirePremium(env, user.id);
  if (!Number.isInteger(position) || position < 0 || position >= plan.days) {
    throw badRequest(`Step must be between 0 and ${plan.days - 1}`);
  }
  const t = Date.now();
  await env.DB.batch([
    env.DB.prepare(
      `INSERT INTO plan_progress (user_id, plan_id, started_at, current_position, updated_at) VALUES (?1, ?2, ?3, 0, ?3)
       ON CONFLICT (user_id, plan_id) DO NOTHING`,
    ).bind(user.id, planId, t),
    env.DB.prepare("INSERT OR IGNORE INTO plan_step_completions (user_id, plan_id, position, completed_at) VALUES (?1, ?2, ?3, ?4)")
      .bind(user.id, planId, position, t),
    // Resume position = first step without a completion; the plan completes when none are left.
    env.DB.prepare(
      `UPDATE plan_progress SET
         current_position = COALESCE((
           SELECT MIN(s.position) FROM plan_steps s WHERE s.plan_id = ?2 AND s.position NOT IN
             (SELECT c.position FROM plan_step_completions c WHERE c.user_id = ?1 AND c.plan_id = ?2)
         ), ?4),
         completed_at = CASE WHEN completed_at IS NOT NULL THEN completed_at
           WHEN (SELECT count(*) FROM plan_step_completions c WHERE c.user_id = ?1 AND c.plan_id = ?2) >= ?4 THEN ?3
           ELSE NULL END,
         updated_at = ?3
       WHERE user_id = ?1 AND plan_id = ?2`,
    ).bind(user.id, planId, t, plan.days),
  ]);
  return Response.json(await onePlan(env, user.id, planId));
}
