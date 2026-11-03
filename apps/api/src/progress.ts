// Bible progress (the streak sheet): chapters read of 1,189, days opened vs days read, weeks in a row, days this
// year, devotionals read. Days are the person's local calendar days, sent by the app.
import { badRequest, readJson } from "./http";
import type { SessionUser } from "./profile";
import { readingDays, resolveToday } from "./reading";
import { BOOKS } from "./refs";
import { dayOrdinal, isValidDay, localDayIn, streakSummary } from "./streak";

export const TOTAL_CHAPTERS = BOOKS.reduce((sum, b) => sum + b[3], 0); // 1,189

/** The local day from the request body, checked: real, and not later than the earliest time zone's today. */
function localDay(body: Record<string, unknown>): string {
  const day = body.localDay;
  if (typeof day !== "string" || !isValidDay(day)) throw badRequest("localDay must be a real date in YYYY-MM-DD form");
  if (dayOrdinal(day) > dayOrdinal(localDayIn("Pacific/Kiritimati"))) throw badRequest(`localDay ${day} is in the future`);
  return day;
}

/** POST /me/opened { localDay }: once per launch; counts toward "Days opened". */
export async function recordOpened(request: Request, env: Env, user: SessionUser) {
  const day = localDay(await readJson(request));
  await env.DB.prepare("INSERT OR IGNORE INTO app_open_days (user_id, local_day) VALUES (?1, ?2)").bind(user.id, day).run();
  return Response.json({ localDay: day });
}

/**
 * POST /me/chapters/{book}/{chapter}/complete { localDay, timeZone }: she reached the end of a chapter. Idempotent (the
 * first completion is kept) and also a reading day for the streak. DELETE un-marks it (the reading day stays).
 */
export async function completeChapter(request: Request, env: Env, user: SessionUser, bookId: string, chapterInput: string) {
  const book = BOOKS.find((b) => b[0] === bookId.toUpperCase());
  const chapter = Number(chapterInput);
  if (!book || !Number.isInteger(chapter) || chapter < 1 || chapter > book[3]) throw badRequest(`Unknown chapter: ${bookId} ${chapterInput}`);
  const body = await readJson(request);
  const day = localDay(body);
  const timeZone = typeof body.timeZone === "string" && body.timeZone.length <= 64 ? body.timeZone : "UTC";
  const t = Date.now();
  await env.DB.batch([
    env.DB.prepare("INSERT OR IGNORE INTO chapter_completions (user_id, book_id, chapter, local_day, completed_at) VALUES (?1, ?2, ?3, ?4, ?5)")
      .bind(user.id, book[0], chapter, day, t),
    env.DB.prepare(
      `INSERT OR IGNORE INTO reading_events (id, user_id, local_day, time_zone, occurred_at, ref, plan_id, plan_step, created_at)
       VALUES (?1, ?2, ?3, ?4, ?5, ?6, NULL, NULL, ?5)`,
    ).bind(`chapter-${user.id}-${book[0]}-${chapter}-${day}`, user.id, day, timeZone, t, `${book[0]}.${chapter}.1`),
  ]);
  return Response.json({ book: book[0], chapter, completed: true });
}

export async function uncompleteChapter(env: Env, user: SessionUser, bookId: string, chapterInput: string) {
  await env.DB.prepare("DELETE FROM chapter_completions WHERE user_id = ?1 AND book_id = ?2 AND chapter = ?3")
    .bind(user.id, bookId.toUpperCase(), Number(chapterInput)).run();
  return new Response(null, { status: 204 });
}

/** Consecutive Monday-to-Sunday weeks with at least one reading day, ending this week (or last week if not yet read this week). */
export function weeksInARow(days: string[], today: string): number {
  const week = (n: number) => Math.floor((n + 3) / 7); // 1970-01-01 was a Thursday; weeks start Monday
  const now = dayOrdinal(today);
  const weeks = new Set(days.map(dayOrdinal).filter((n) => Number.isFinite(n) && n <= now).map(week));
  let w = weeks.has(week(now)) ? week(now) : week(now) - 1;
  let count = 0;
  while (weeks.has(w)) { count++; w--; }
  return count;
}

/** GET /me/progress?today=YYYY-MM-DD */
export async function getProgress(url: URL, env: Env, user: SessionUser) {
  const today = await resolveToday(env, user.id, url.searchParams.get("today"));
  const [read, opened, chapters, extra] = await Promise.all([
    readingDays(env, user.id),
    env.DB.prepare("SELECT local_day FROM app_open_days WHERE user_id = ?1").bind(user.id).all<{ local_day: string }>(),
    env.DB.prepare("SELECT book_id, count(*) AS n FROM chapter_completions WHERE user_id = ?1 GROUP BY book_id").bind(user.id).all<{ book_id: string; n: number }>(),
    env.DB.prepare(
      `SELECT (SELECT count(*) FROM devotional_reads WHERE user_id = ?1) AS devotionals,
              (SELECT count(DISTINCT ref) FROM study_history WHERE user_id = ?1) AS studied`,
    ).bind(user.id).first<{ devotionals: number; studied: number }>(),
  ]);
  // Opening the app to read counts as opening it, even if the "opened" ping was lost.
  const openedDays = [...new Set([...opened.results.map((r) => r.local_day), ...read])];
  const perBook = new Map(chapters.results.map((r) => [r.book_id, r.n]));
  const chaptersRead = chapters.results.reduce((s, r) => s + r.n, 0);
  const readSummary = streakSummary(read, today);
  const openSummary = streakSummary(openedDays, today);
  const year = today.slice(0, 4);
  const now = dayOrdinal(today);
  return Response.json({
    today,
    bible: {
      chaptersRead, totalChapters: TOTAL_CHAPTERS, percent: Math.round((chaptersRead / TOTAL_CHAPTERS) * 1000) / 10,
      books: BOOKS.map(([id, name, testament, total]) => ({ id, name, testament, chapters: total, chaptersRead: perBook.get(id) ?? 0 })),
    },
    daysOpened: { total: openedDays.filter((d) => dayOrdinal(d) <= now).length, current: openSummary.current, best: openSummary.best },
    daysRead: { total: new Set(read.filter((d) => dayOrdinal(d) <= now)).size, current: readSummary.current, best: readSummary.best },
    daysThisYear: new Set(read.filter((d) => d.startsWith(year) && dayOrdinal(d) <= now)).size,
    weeksInARow: weeksInARow(read, today),
    week: readSummary.week,
    milestone: readSummary.milestone,
    devotionalsRead: extra?.devotionals ?? 0,
    versesStudied: extra?.studied ?? 0,
  });
}

/** GET /me/chapters?book=JHN: which chapters of a book she has finished (for the chapter picker's checkmarks). */
export async function listCompletedChapters(url: URL, env: Env, user: SessionUser) {
  const book = (url.searchParams.get("book") ?? "").toUpperCase();
  if (!BOOKS.some((b) => b[0] === book)) throw badRequest("book must be a book id, e.g. JHN");
  const rows = await env.DB.prepare("SELECT chapter, local_day FROM chapter_completions WHERE user_id = ?1 AND book_id = ?2 ORDER BY chapter")
    .bind(user.id, book).all<{ chapter: number; local_day: string }>();
  return Response.json({ book, completed: rows.results.map((r) => ({ chapter: r.chapter, localDay: r.local_day })) });
}
