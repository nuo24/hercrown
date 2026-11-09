// Home and Discover content: Verse of the Day, Discover cards by theme (with "For you" and the current plan), a random
// verse for the reader toolbar, the widget verse, and Today's Devotional. References and reflections come from
// src/content/verses.json; verse text always comes from our Bibles in her translation.
import verses from "./content/verses.json";
import { badRequest, notFound, readJson } from "./http";
import { preferencesRow, type SessionUser } from "./profile";
import { resolveToday } from "./reading";
import { parseRef } from "./refs";
import { fetchRemoteChapter, type RemoteChapter } from "./apibible";
import { refLabel } from "./scripture";
import { dayOrdinal, isValidDay, localDayIn } from "./streak";

interface Card { ref: string; theme: string; reflection: string }
const CARDS = verses.cards as Card[];
const THEMES = verses.themes;
const LOCAL = new Set(["kjv", "bsb", "web"]);
const byRef = new Map(CARDS.map((c) => [c.ref, c]));

/** Stable order that mixes themes, so consecutive days don't share one (FNV-1a hash of the reference). */
const hash = (s: string) => [...s].reduce((h, c) => Math.imul(h ^ c.charCodeAt(0), 16777619) >>> 0, 2166136261);
export const VOTD_POOL = [...CARDS.map((c) => c.ref), ...verses.verseOfTheDayExtra].sort((a, b) => hash(a) - hash(b) || a.localeCompare(b));

/** Preserve the selected enabled edition; never silently substitute KJV for a licensed passage. */
async function translationFor(env: Env, user: SessionUser, url: URL) {
  const requested = url.searchParams.get("translation") ?? (await preferencesRow(env, user.id)).translation;
  return LOCAL.has(requested) || ["nkjv", "msg", "amp", "nlt"].includes(requested) ? requested : "kjv";
}

/** Text for many references, 24 per query (D1 allows 100 bound values; 4 per reference). Passages are joined with spaces. */
export interface PassageContent { text: string; label: string; copyright?: string | null }
export function remotePassage(content: RemoteChapter, ref: string): PassageContent | undefined {
  const p = parseRef(ref);
  if (!p) return;
  const matching = content.verses.filter(v => v.verse <= p.end && (v.end ?? v.verse) >= p.start);
  if (!matching.length) return;
  return { text: matching.map(v => v.text).join(" "),
    label: refLabel(p.book, p.chapter, matching[0]!.verse, matching.at(-1)!.end ?? matching.at(-1)!.verse), copyright: content.copyright };
}
export async function textsFor(env: Env, translation: string, refs: string[]): Promise<Map<string, PassageContent>> {
  const out = new Map<string, PassageContent>();
  const parsed = [...new Set(refs)].map((ref) => ({ ref, p: parseRef(ref)! })).filter((x) => x.p);
  if (!LOCAL.has(translation)) {
    const t = await env.DB.prepare("SELECT provider_bible_id FROM translations WHERE id = ?1 AND enabled = 1 AND provider = 'api_bible'")
      .bind(translation).first<{ provider_bible_id: string }>();
    if (!t?.provider_bible_id) throw notFound("Translation is not enabled");
    // Deduplicate chapters within this response; at most four provider requests in flight.
    const chapters = [...new Set(parsed.map(({ p }) => `${p.book}.${p.chapter}`))];
    const loaded = new Map<string, RemoteChapter>();
    for (let i = 0; i < chapters.length; i += 4) {
      await Promise.all(chapters.slice(i, i + 4).map(async key => {
        const [book, number] = key.split(".");
        loaded.set(key, await fetchRemoteChapter(env, t.provider_bible_id, book!, Number(number)));
      }));
    }
    for (const { ref, p } of parsed) {
      const passage = remotePassage(loaded.get(`${p.book}.${p.chapter}`)!, ref);
      if (passage) out.set(ref, passage);
    }
    return out;
  }
  for (let i = 0; i < parsed.length; i += 24) {
    const chunk = parsed.slice(i, i + 24);
    const where = chunk.map((_, j) => `(book_id = ?${j * 4 + 2} AND chapter = ?${j * 4 + 3} AND verse BETWEEN ?${j * 4 + 4} AND ?${j * 4 + 5})`).join(" OR ");
    const rows = await env.DB.prepare(`SELECT book_id, chapter, verse, text FROM verses WHERE translation_id = ?1 AND (${where}) ORDER BY book_id, chapter, verse`)
      .bind(translation, ...chunk.flatMap(({ p }) => [p.book, p.chapter, p.start, p.end])).all<{ book_id: string; chapter: number; verse: number; text: string }>();
    for (const { ref, p } of chunk) {
      const text = rows.results.filter((r) => r.book_id === p.book && r.chapter === p.chapter && r.verse >= p.start && r.verse <= p.end).map((r) => r.text).join(" ");
      if (text) out.set(ref, { text, label: label(ref) });
    }
  }
  return out;
}

const label = (ref: string) => {
  const p = parseRef(ref)!;
  return refLabel(p.book, p.chapter, p.start, p.end);
};

// ── Verse of the Day, random verse, widget ─────────────────────────────────

/** Rotate daily within her selected topics; readers with no topics retain the shared daily pool. */
export function verseOfTheDayRef(day: string, topics: string[] = []): string {
  const related = CARDS.filter(c => topics.includes(c.theme)).map(c => c.ref);
  const pool = related.length ? related : VOTD_POOL;
  const n = dayOrdinal(day);
  return pool[((n % pool.length) + pool.length) % pool.length]!;
}

async function verseCard(env: Env, translation: string, ref: string, userId: string) {
  const [text, saved] = await Promise.all([
    textsFor(env, translation, [ref]),
    env.DB.prepare("SELECT 1 FROM saved_passages WHERE user_id = ?1 AND ref = ?2").bind(userId, ref).first(),
  ]);
  const card = byRef.get(ref);
  return { ref, label: text.get(ref)?.label ?? label(ref), text: text.get(ref)?.text ?? null, copyright: text.get(ref)?.copyright ?? null, translation, theme: card?.theme ?? null, reflection: card?.reflection ?? null, saved: Boolean(saved) };
}

/** GET /scripture/verse-of-the-day?date=YYYY-MM-DD&translation= (date defaults to her today). */
export async function getVerseOfTheDay(url: URL, env: Env, user: SessionUser) {
  const day = await resolveToday(env, user.id, url.searchParams.get("date"));
  return Response.json({ date: day, ...(await verseCard(env, await translationFor(env, user, url), verseOfTheDayRef(day, JSON.parse((await preferencesRow(env, user.id)).topics) as string[]), user.id)) });
}

/** GET /scripture/random?translation=: the reader's random-verse button, from the curated verses. */
export async function getRandomVerse(url: URL, env: Env, user: SessionUser) {
  const ref = VOTD_POOL[Math.floor(Math.random() * VOTD_POOL.length)]!;
  return Response.json(await verseCard(env, await translationFor(env, user, url), ref, user.id));
}

/** GET /me/widget?date=: the home-screen widget's verse (her chosen "Widget Verse", else today's verse, same as Home's). */
export async function getWidget(url: URL, env: Env, user: SessionUser) {
  const prefs = await preferencesRow(env, user.id);
  const day = await resolveToday(env, user.id, url.searchParams.get("date"));
  const ref = prefs.widget_ref ?? verseOfTheDayRef(day, JSON.parse(prefs.topics) as string[]);
  return Response.json({ source: prefs.widget_ref ? "chosen" : "verse_of_the_day", date: day, ...(await verseCard(env, await translationFor(env, user, url), ref, user.id)) });
}

// ── Discover ────────────────────────────────────────────────────────────────

/**
 * GET /discover?filter=for-you|plan|<Theme>&translation=
 * "For you" puts her onboarding topics first (interleaved), then the rest, and rotates daily. "plan" is her current
 * plan's passages. Each card: verse text in her translation + a reflection question (not Scripture).
 */
export async function getDiscover(url: URL, env: Env, user: SessionUser) {
  const filter = url.searchParams.get("filter") ?? "for-you";
  const prefs = await preferencesRow(env, user.id);
  const translation = await translationFor(env, user, url);
  const plan = await env.DB.prepare(
    `SELECT p.id, p.title FROM plan_progress g JOIN plans p ON p.id = g.plan_id
     WHERE g.user_id = ?1 AND g.completed_at IS NULL ORDER BY g.updated_at DESC LIMIT 1`,
  ).bind(user.id).first<{ id: string; title: string }>();

  let chosen: { ref: string; theme: string | null; reflection: string | null }[];
  if (filter === "for-you") {
    const mine = (JSON.parse(prefs.topics) as string[]).filter((t) => THEMES.includes(t));
    const order = [...mine, ...THEMES.filter((t) => !mine.includes(t))];
    const today = dayOrdinal(localDayIn(prefs.time_zone ?? "UTC"));
    const lists = order.map((theme) => {
      const list = CARDS.filter((c) => c.theme === theme);
      const shift = today % list.length; // a different first card each day
      return [...list.slice(shift), ...list.slice(0, shift)];
    });
    chosen = [];
    // Her topics first, round-robin, then everything else round-robin.
    for (const group of [lists.slice(0, mine.length), lists.slice(mine.length)]) {
      for (let i = 0; group.some((l) => i < l.length); i++) for (const l of group) if (l[i]) chosen.push(l[i]!);
    }
  } else if (filter === "plan") {
    if (!plan) return Response.json({ filter, filters: filters(null), cards: [], plan: null });
    const steps = await env.DB.prepare("SELECT ref FROM plan_steps WHERE plan_id = ?1 ORDER BY position").bind(plan.id).all<{ ref: string }>();
    chosen = steps.results.map((s) => ({ ref: s.ref, theme: byRef.get(s.ref)?.theme ?? null, reflection: byRef.get(s.ref)?.reflection ?? null }));
  } else if (THEMES.includes(filter)) {
    chosen = CARDS.filter((c) => c.theme === filter);
  } else {
    throw badRequest(`filter must be for-you, plan, or one of: ${THEMES.join(", ")}`);
  }

  const offset = Math.max(0, Math.floor(Number(url.searchParams.get("offset")) || 0));
  const nextOffset = !LOCAL.has(translation) && offset + 12 < chosen.length ? offset + 12 : null;
  if (!LOCAL.has(translation)) chosen = chosen.slice(offset, offset + 12);
  const [texts, saved] = await Promise.all([
    textsFor(env, translation, chosen.map((c) => c.ref)),
    env.DB.prepare("SELECT ref FROM saved_passages WHERE user_id = ?1").bind(user.id).all<{ ref: string }>(),
  ]);
  const savedRefs = new Set(saved.results.map((r) => r.ref));
  return Response.json({
    filter, filters: filters(plan), translation, plan, nextOffset,
    cards: chosen.filter((c) => texts.has(c.ref)).map((c) => ({
      id: c.ref, ref: c.ref, label: texts.get(c.ref)!.label, theme: c.theme, text: texts.get(c.ref)!.text, copyright: texts.get(c.ref)!.copyright ?? null, reflection: c.reflection, saved: savedRefs.has(c.ref),
    })),
  });
}

const filters = (plan: { id: string; title: string } | null) => [
  { id: "for-you", title: "For you" },
  ...(plan ? [{ id: "plan", title: plan.title }] : []),
  ...THEMES.map((t) => ({ id: t, title: t })),
];

// ── Devotionals ─────────────────────────────────────────────────────────────

interface DevotionalRow { id: string; position: number; title: string; ref: string; tag: string; minutes: number; body: string; reflection: string; origin: string; sources: string }

async function devotionalJson(env: Env, user: SessionUser, url: URL, row: DevotionalRow) {
  const translation = await translationFor(env, user, url);
  const [texts, read] = await Promise.all([
    textsFor(env, translation, [row.ref]),
    env.DB.prepare("SELECT read_at FROM devotional_reads WHERE user_id = ?1 AND devotional_id = ?2").bind(user.id, row.id).first<{ read_at: number }>(),
  ]);
  return {
    id: row.id, title: row.title, ref: row.ref, label: texts.get(row.ref)?.label ?? label(row.ref), passage: texts.get(row.ref)?.text ?? null, copyright: texts.get(row.ref)?.copyright ?? null, translation,
    tag: row.tag, minutes: row.minutes, body: row.body, reflection: row.reflection,
    origin: row.origin, // "ai-draft-reviewed": drafted with AI from the cited commentaries, then approved by our team
    sources: JSON.parse(row.sources) as string[], readAt: read?.read_at ?? null,
  };
}

/** GET /devotionals/today?date=: one devotional per day for everyone, rotating through the approved ones. */
export async function getTodaysDevotional(url: URL, env: Env, user: SessionUser) {
  const day = await resolveToday(env, user.id, url.searchParams.get("date"));
  const count = (await env.DB.prepare("SELECT count(*) AS n FROM devotionals").first<{ n: number }>())!.n;
  if (count === 0) throw notFound("No devotionals yet");
  const row = await env.DB.prepare("SELECT * FROM devotionals ORDER BY position LIMIT 1 OFFSET ?1")
    .bind(((dayOrdinal(day) % count) + count) % count).first<DevotionalRow>();
  return Response.json({ date: day, ...(await devotionalJson(env, user, url, row!)) });
}

export async function getDevotional(url: URL, env: Env, user: SessionUser, id: string) {
  const row = await env.DB.prepare("SELECT * FROM devotionals WHERE id = ?1").bind(id).first<DevotionalRow>();
  if (!row) throw notFound("No such devotional");
  return Response.json(await devotionalJson(env, user, url, row));
}

/** POST /me/devotionals/{id}/read { localDay }: counts toward "Devotionals read". */
export async function markDevotionalRead(request: Request, env: Env, user: SessionUser, id: string) {
  const body = await readJson(request);
  if (typeof body.localDay !== "string" || !isValidDay(body.localDay)) throw badRequest("localDay must be a real date in YYYY-MM-DD form");
  if (!(await env.DB.prepare("SELECT 1 FROM devotionals WHERE id = ?1").bind(id).first())) throw notFound("No such devotional");
  await env.DB.prepare("INSERT OR IGNORE INTO devotional_reads (user_id, devotional_id, local_day, read_at) VALUES (?1, ?2, ?3, ?4)")
    .bind(user.id, id, body.localDay, Date.now()).run();
  return Response.json({ id, read: true });
}
