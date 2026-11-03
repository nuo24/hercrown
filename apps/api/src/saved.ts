// Saved passages: one collection shared by the reader and Discover. Saving is idempotent.
import { resolveRef } from "./refs";
import type { SessionUser } from "./profile";

async function list(env: Env, userId: string) {
  const rows = await env.DB.prepare("SELECT ref, created_at FROM saved_passages WHERE user_id = ?1 ORDER BY created_at DESC")
    .bind(userId)
    .all<{ ref: string; created_at: number }>();
  return rows.results.map((r) => ({ ref: r.ref, savedAt: r.created_at }));
}

export async function listSaved(env: Env, user: SessionUser) {
  return Response.json({ saved: await list(env, user.id) });
}

export async function savePassage(env: Env, user: SessionUser, input: string) {
  const ref = await resolveRef(env.DB, input);
  await env.DB.prepare("INSERT OR IGNORE INTO saved_passages (user_id, ref, created_at) VALUES (?1, ?2, ?3)")
    .bind(user.id, ref, Date.now()).run();
  return Response.json({ saved: await list(env, user.id) });
}

export async function unsavePassage(env: Env, user: SessionUser, input: string) {
  const ref = await resolveRef(env.DB, input);
  await env.DB.prepare("DELETE FROM saved_passages WHERE user_id = ?1 AND ref = ?2").bind(user.id, ref).run();
  return Response.json({ saved: await list(env, user.id) });
}
