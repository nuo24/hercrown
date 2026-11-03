// "Your library": notes on verses (auto-saved), saved studies, studied verses, and the counts on the Saved screen
// (saved verses, notes, studies, studied). Note text is private: never logged or sent to analytics.
import { badRequest, notFound, readJson } from "./http";
import { preferencesRow, type SessionUser } from "./profile";
import { parseRef, resolveVerse } from "./refs";
import { refLabel } from "./scripture";

const MAX_NOTE = 10_000;
const PAGE = 50;
export const STUDY_TOOLS = ["explain", "deeper", "original", "related"] as const;
export type StudyTool = (typeof STUDY_TOOLS)[number];

const label = (ref: string) => {
  const p = parseRef(ref)!;
  return refLabel(p.book, p.chapter, p.start, p.end);
};

/** Verse text in her reading translation (falls back to KJV for online-only translations). */
async function verseTexts(env: Env, userId: string, refs: string[]): Promise<Map<string, string>> {
  const out = new Map<string, string>();
  if (refs.length === 0) return out;
  const { translation } = await preferencesRow(env, userId);
  const local = ["kjv", "bsb", "web"].includes(translation) ? translation : "kjv";
  for (const ref of refs) {
    const p = parseRef(ref)!;
    const row = await env.DB.prepare("SELECT text FROM verses WHERE translation_id = ?1 AND book_id = ?2 AND chapter = ?3 AND verse = ?4")
      .bind(local, p.book, p.chapter, p.start).first<{ text: string }>();
    if (row) out.set(ref, row.text);
  }
  return out;
}

const before = (url: URL) => {
  const b = Number(url.searchParams.get("before"));
  return Number.isFinite(b) && b > 0 ? b : Number.MAX_SAFE_INTEGER;
};

// ── Notes ───────────────────────────────────────────────────────────────────

/** GET /me/notes?before=<updatedAt>: newest first, 50 per page, with the verse. */
export async function listNotes(url: URL, env: Env, user: SessionUser) {
  const rows = (await env.DB.prepare(
    "SELECT ref, text, created_at, updated_at FROM verse_notes WHERE user_id = ?1 AND updated_at < ?2 ORDER BY updated_at DESC LIMIT ?3",
  ).bind(user.id, before(url), PAGE).all<{ ref: string; text: string; created_at: number; updated_at: number }>()).results;
  const texts = await verseTexts(env, user.id, rows.map((r) => r.ref));
  return Response.json({
    notes: rows.map((r) => ({ ref: r.ref, label: label(r.ref), verse: texts.get(r.ref) ?? null, text: r.text, createdAt: r.created_at, updatedAt: r.updated_at })),
    nextBefore: rows.length === PAGE ? rows[rows.length - 1]!.updated_at : null,
  });
}

export async function getNote(env: Env, user: SessionUser, refInput: string) {
  const ref = await resolveVerse(env.DB, refInput);
  const row = await env.DB.prepare("SELECT text, created_at, updated_at FROM verse_notes WHERE user_id = ?1 AND ref = ?2")
    .bind(user.id, ref).first<{ text: string; created_at: number; updated_at: number }>();
  if (!row) throw notFound("No note on this verse");
  return Response.json({ ref, label: label(ref), text: row.text, createdAt: row.created_at, updatedAt: row.updated_at });
}

/**
 * PUT /me/notes/{ref} { text, at? }: auto-save. Empty text deletes the note. `at` (client ms) keeps an older save from a
 * slower request or another device from overwriting a newer one.
 */
export async function saveNote(request: Request, env: Env, user: SessionUser, refInput: string) {
  const ref = await resolveVerse(env.DB, refInput);
  const body = await readJson(request);
  if (typeof body.text !== "string") throw badRequest("text must be a string");
  const text = body.text.replace(/\r\n/g, "\n").trimEnd();
  if (text.length > MAX_NOTE) throw badRequest(`Notes can be up to ${MAX_NOTE} characters`);
  const at = typeof body.at === "number" && Number.isFinite(body.at) ? Math.min(body.at, Date.now()) : Date.now();
  if (!text.trim()) {
    await env.DB.prepare("DELETE FROM verse_notes WHERE user_id = ?1 AND ref = ?2 AND updated_at <= ?3").bind(user.id, ref, at).run();
    return Response.json({ ref, text: null, deleted: true });
  }
  await env.DB.prepare(
    `INSERT INTO verse_notes (user_id, ref, text, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?4)
     ON CONFLICT (user_id, ref) DO UPDATE SET text = ?3, updated_at = ?4 WHERE verse_notes.updated_at <= ?4`,
  ).bind(user.id, ref, text, at).run();
  const row = await env.DB.prepare("SELECT text, updated_at FROM verse_notes WHERE user_id = ?1 AND ref = ?2")
    .bind(user.id, ref).first<{ text: string; updated_at: number }>();
  return Response.json({ ref, label: label(ref), text: row!.text, updatedAt: row!.updated_at, saved: row!.updated_at === at });
}

export async function deleteNote(env: Env, user: SessionUser, refInput: string) {
  const ref = await resolveVerse(env.DB, refInput);
  await env.DB.prepare("DELETE FROM verse_notes WHERE user_id = ?1 AND ref = ?2").bind(user.id, ref).run();
  return new Response(null, { status: 204 });
}

// ── Studies ─────────────────────────────────────────────────────────────────

/** Called whenever a study tool answers: feeds Library → Studied. */
export async function recordStudied(env: Env, userId: string, ref: string, tool: StudyTool) {
  const t = Date.now();
  await env.DB.prepare(
    `INSERT INTO study_history (user_id, ref, tool, first_viewed_at, last_viewed_at) VALUES (?1, ?2, ?3, ?4, ?4)
     ON CONFLICT (user_id, ref, tool) DO UPDATE SET last_viewed_at = ?4`,
  ).bind(userId, ref, tool, t).run();
}

/** PUT|DELETE /me/studies/{ref}/{explain|deeper}: save a study to come back to. */
export async function saveStudy(env: Env, user: SessionUser, refInput: string, tool: string, save: boolean) {
  if (tool !== "explain" && tool !== "deeper") throw badRequest("Only Explain easier and Deeper study can be saved");
  const ref = await resolveVerse(env.DB, refInput);
  if (save) {
    await env.DB.prepare("INSERT OR IGNORE INTO saved_studies (user_id, ref, tool, saved_at) VALUES (?1, ?2, ?3, ?4)")
      .bind(user.id, ref, tool, Date.now()).run();
    return Response.json({ ref, tool, saved: true });
  }
  await env.DB.prepare("DELETE FROM saved_studies WHERE user_id = ?1 AND ref = ?2 AND tool = ?3").bind(user.id, ref, tool).run();
  return new Response(null, { status: 204 });
}

/** GET /me/studies: saved studies, newest first. */
export async function listSavedStudies(url: URL, env: Env, user: SessionUser) {
  const rows = (await env.DB.prepare(
    "SELECT ref, tool, saved_at FROM saved_studies WHERE user_id = ?1 AND saved_at < ?2 ORDER BY saved_at DESC LIMIT ?3",
  ).bind(user.id, before(url), PAGE).all<{ ref: string; tool: string; saved_at: number }>()).results;
  const texts = await verseTexts(env, user.id, [...new Set(rows.map((r) => r.ref))]);
  return Response.json({
    studies: rows.map((r) => ({ ref: r.ref, label: label(r.ref), verse: texts.get(r.ref) ?? null, tool: r.tool, savedAt: r.saved_at })),
    nextBefore: rows.length === PAGE ? rows[rows.length - 1]!.saved_at : null,
  });
}

/** GET /me/studied: verses she studied, most recent first, with the tools used. */
export async function listStudied(url: URL, env: Env, user: SessionUser) {
  const rows = (await env.DB.prepare(
    `SELECT ref, group_concat(tool) AS tools, max(last_viewed_at) AS last FROM study_history WHERE user_id = ?1
     GROUP BY ref HAVING last < ?2 ORDER BY last DESC LIMIT ?3`,
  ).bind(user.id, before(url), PAGE).all<{ ref: string; tools: string; last: number }>()).results;
  const texts = await verseTexts(env, user.id, rows.map((r) => r.ref));
  return Response.json({
    studied: rows.map((r) => ({
      ref: r.ref, label: label(r.ref), verse: texts.get(r.ref) ?? null,
      tools: STUDY_TOOLS.filter((t) => r.tools.split(",").includes(t)), lastStudiedAt: r.last,
    })),
    nextBefore: rows.length === PAGE ? rows[rows.length - 1]!.last : null,
  });
}

/** GET /me/library: the four rows of "Your library" with counts. */
export async function getLibrary(env: Env, user: SessionUser) {
  const row = await env.DB.prepare(
    `SELECT (SELECT count(*) FROM saved_passages WHERE user_id = ?1) AS saved,
            (SELECT count(*) FROM verse_notes WHERE user_id = ?1) AS notes,
            (SELECT count(*) FROM saved_studies WHERE user_id = ?1) AS studies,
            (SELECT count(DISTINCT ref) FROM study_history WHERE user_id = ?1) AS studied`,
  ).bind(user.id).first<{ saved: number; notes: number; studies: number; studied: number }>();
  return Response.json({
    savedVerses: row!.saved, notes: row!.notes, studies: row!.studies, studied: row!.studied,
    total: row!.saved + row!.notes + row!.studies,
  });
}
