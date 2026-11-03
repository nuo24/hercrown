// Scripture reading: translations, books, chapters (with continuation), passages and search.
import { fetchRemoteChapter } from "./apibible";
import { badRequest, HttpError, notFound } from "./http";
import { BOOKS, parseRef } from "./refs";

interface TranslationRow {
  id: string;
  name: string;
  abbreviation: string | null;
  language: string;
  license: string;
  attribution: string | null;
  availability: "bundled" | "remote";
  provider: "local" | "api_bible";
  provider_bible_id: string | null;
}

const bookIndex = new Map(BOOKS.map((b, i) => [b[0], i]));

async function translation(env: Env, id: string) {
  const row = await env.DB.prepare(
    `SELECT id, name, abbreviation, language, license, attribution, availability, provider, provider_bible_id
     FROM translations WHERE id = ?1 AND enabled = 1`,
  ).bind(id.toLowerCase()).first<TranslationRow>();
  if (!row) throw notFound(`No translation "${id}"`);
  return row;
}

const translationJson = (t: TranslationRow, env: Env) => ({
  id: t.id,
  name: t.name,
  abbreviation: t.abbreviation,
  language: t.language,
  availability: t.availability, // "bundled": in the app, works offline; "remote": needs a connection
  online: t.provider !== "local" ? Boolean(env.API_BIBLE_KEY) : true,
  license: t.license,
  attribution: t.attribution,
});

export async function listTranslations(env: Env) {
  const rows = await env.DB.prepare(
    `SELECT id, name, abbreviation, language, license, attribution, availability, provider, provider_bible_id
     FROM translations WHERE enabled = 1 ORDER BY position, name`,
  ).all<TranslationRow>();
  return Response.json({ translations: rows.results.map((t) => translationJson(t, env)) });
}

/** Books with per-chapter verse counts for the reader rail. `?translation=bsb` counts that translation's own verses
 *  (BSB omits some verses); remote translations and the default use the canonical counts. */
export async function listBooks(url: URL, env: Env) {
  const requested = url.searchParams.get("translation");
  const t = requested ? await translation(env, requested) : null;
  const rows = t?.provider === "local"
    ? await env.DB.prepare(
        "SELECT book_id, chapter, count(*) AS verse_count FROM verses WHERE translation_id = ?1 GROUP BY book_id, chapter ORDER BY chapter",
      ).bind(t.id).all<{ book_id: string; chapter: number; verse_count: number }>()
    : await env.DB.prepare("SELECT book_id, chapter, verse_count FROM chapter_verse_counts ORDER BY chapter")
        .all<{ book_id: string; chapter: number; verse_count: number }>();
  if (t?.provider === "local" && rows.results.length === 0) {
    throw new HttpError(503, "scripture_not_loaded", `${t.abbreviation ?? t.id} text isn't loaded on this server (run npm run seed:${t.id})`);
  }
  const counts = new Map(rows.results.map((r) => [`${r.book_id}.${r.chapter}`, r.verse_count]));
  return Response.json({
    translation: t?.id ?? null,
    books: BOOKS.map(([id, name, testament, chapters]) => ({
      id, name, testament, chapters,
      // One entry per chapter, in order (0 if a chapter has no stored verses); drives the reader rail.
      verseCounts: Array.from({ length: chapters }, (_, i) => counts.get(`${id}.${i + 1}`) ?? 0),
    })),
  });
}

async function verseCount(env: Env, book: string, chapter: number) {
  const row = await env.DB.prepare("SELECT verse_count FROM chapter_verse_counts WHERE book_id = ?1 AND chapter = ?2")
    .bind(book, chapter).first<{ verse_count: number }>();
  if (!row) throw notFound(`No chapter ${book} ${chapter}`);
  return row.verse_count;
}

/** Previous/next chapter across book boundaries; null at Genesis 1 and Revelation 22. */
function neighbours(book: string, chapter: number) {
  const i = bookIndex.get(book)!;
  const [, , , chapters] = BOOKS[i];
  const previous = chapter > 1 ? { book, chapter: chapter - 1 } : i > 0 ? { book: BOOKS[i - 1][0], chapter: BOOKS[i - 1][3] } : null;
  const next = chapter < chapters ? { book, chapter: chapter + 1 } : i < BOOKS.length - 1 ? { book: BOOKS[i + 1][0], chapter: 1 } : null;
  return { previous, next };
}

interface ChapterVerse {
  verse: number;
  text: string;
  wordsOfJesus?: [number, number][]; // [start, length] in UTF-16 units, for "Words of Jesus in red"
}

async function chapterVerses(env: Env, t: TranslationRow, book: string, chapter: number) {
  if (t.provider === "local") {
    const [rows, title] = await env.DB.batch([
      env.DB.prepare("SELECT verse, text, words_of_jesus FROM verses WHERE translation_id = ?1 AND book_id = ?2 AND chapter = ?3 ORDER BY verse")
        .bind(t.id, book, chapter),
      env.DB.prepare("SELECT text FROM chapter_titles WHERE translation_id = ?1 AND book_id = ?2 AND chapter = ?3").bind(t.id, book, chapter),
    ]);
    const verses = (rows.results as { verse: number; text: string; words_of_jesus: string | null }[]).map((r): ChapterVerse =>
      r.words_of_jesus ? { verse: r.verse, text: r.text, wordsOfJesus: JSON.parse(r.words_of_jesus) } : { verse: r.verse, text: r.text });
    if (verses.length === 0) {
      throw new HttpError(503, "scripture_not_loaded", `${t.abbreviation ?? t.id} text isn't loaded on this server (run npm run seed:${t.id})`);
    }
    const titleText = (title.results[0] as { text: string } | undefined)?.text ?? null;
    return { verses, title: titleText, copyright: t.attribution, fumsToken: null };
  }
  if (!t.provider_bible_id) throw new HttpError(503, "translation_unavailable", "This translation isn't configured");
  const remote = await fetchRemoteChapter(env, t.provider_bible_id, book, chapter);
  return { ...remote, verses: remote.verses as ChapterVerse[], title: null };
}

export async function getChapter(env: Env, translationId: string, bookInput: string, chapterInput: string) {
  const book = bookInput.toUpperCase();
  const chapter = Number(chapterInput);
  if (!bookIndex.has(book)) throw notFound(`No book "${bookInput}"`);
  if (!Number.isInteger(chapter)) throw badRequest("chapter must be a number");
  const [t] = await Promise.all([translation(env, translationId), verseCount(env, book, chapter)]); // 404 if no such chapter
  const content = await chapterVerses(env, t, book, chapter);
  return Response.json({
    translation: translationJson(t, env),
    book: { id: book, name: BOOKS[bookIndex.get(book)!][1] },
    chapter,
    title: content.title, // psalm superscription, shown above verse 1
    // This translation's own verses: numbering can have gaps (e.g. BSB Matthew 17 has no verse 21).
    verseCount: content.verses.length,
    verses: content.verses,
    ...neighbours(book, chapter),
    copyright: content.copyright,
    fumsToken: content.fumsToken,
  });
}

export async function getPassage(env: Env, translationId: string, refInput: string) {
  const ref = parseRef(refInput);
  if (!ref) throw badRequest(`Unknown passage reference: ${refInput}`);
  const [t, total] = await Promise.all([translation(env, translationId), verseCount(env, ref.book, ref.chapter)]);
  if (ref.end > total) throw badRequest(`${ref.book} ${ref.chapter} has ${total} verses`);
  const content = await chapterVerses(env, t, ref.book, ref.chapter);
  const verses = content.verses.filter((v) => v.verse >= ref.start && v.verse <= ref.end);
  if (verses.length === 0) {
    throw new HttpError(404, "not_in_translation",
      `${refLabel(ref.book, ref.chapter, ref.start, ref.end)} isn't in the ${t.abbreviation ?? t.name}. Some translations leave out verses that are missing from the earliest manuscripts.`);
  }
  return Response.json({
    translation: translationJson(t, env),
    ref: ref.ref,
    label: refLabel(ref.book, ref.chapter, ref.start, ref.end),
    verses,
    copyright: content.copyright,
    fumsToken: content.fumsToken,
  });
}

export function refLabel(book: string, chapter: number, start: number, end = start) {
  const name = BOOKS[bookIndex.get(book)!][1];
  const display = name === "Psalms" ? "Psalm" : name;
  return `${display} ${chapter}:${start}${end > start ? `–${end}` : ""}`;
}

// ── Search ──────────────────────────────────────────────────────────────────

const norm = (s: string) => s.toLowerCase().replace(/[^a-z0-9]/g, "");
const ABBREVIATIONS: Record<string, string> = {
  gn: "GEN", ex: "EXO", lv: "LEV", nm: "NUM", dt: "DEU", jdg: "JDG", ps: "PSA", psalm: "PSA", pss: "PSA", pr: "PRO",
  prov: "PRO", song: "SNG", songofsongs: "SNG", is: "ISA", jer: "JER", mt: "MAT", mk: "MRK", lk: "LUK", jn: "JHN",
  rom: "ROM", phil: "PHP", jas: "JAS", rev: "REV", revelations: "REV",
};

/** Book name or abbreviation → USFM id, if unambiguous. "1 john" → 1JN, "ps" → PSA, "jo" → null. */
export function bookFromName(input: string): string | null {
  const key = norm(input);
  if (!key) return null;
  if (ABBREVIATIONS[key]) return ABBREVIATIONS[key];
  const exact = BOOKS.find(([id, name]) => norm(name) === key || norm(id) === key);
  if (exact) return exact[0];
  const prefixed = BOOKS.filter(([, name]) => norm(name).startsWith(key));
  return key.length >= 3 && prefixed.length === 1 ? prefixed[0][0] : null;
}

/** "John 3:16", "1 Cor 13:4-7", "Psalm 23" → canonical parts, or null if it isn't a reference. */
async function referenceFromQuery(env: Env, q: string) {
  const m = q.trim().match(/^([1-3]?\s*[a-zA-Z][a-zA-Z .]*?)\s*(\d{1,3})(?:\s*[:.]\s*(\d{1,3})(?:\s*[-–]\s*(\d{1,3}))?)?$/);
  if (!m) return null;
  const book = bookFromName(m[1]);
  const chapter = Number(m[2]);
  if (!book || chapter < 1 || chapter > BOOKS[bookIndex.get(book)!][3]) return null;
  const total = await verseCount(env, book, chapter);
  const start = m[3] ? Number(m[3]) : 1;
  const end = m[4] ? Number(m[4]) : m[3] ? start : total;
  if (start < 1 || end < start || end > total) return null;
  return {
    ref: end === start ? `${book}.${chapter}.${start}` : `${book}.${chapter}.${start}-${end}`,
    label: m[3] ? refLabel(book, chapter, start, end) : `${BOOKS[bookIndex.get(book)!][1].replace(/^Psalms$/, "Psalm")} ${chapter}`,
    book,
    chapter,
  };
}

/** Passage search for Home: recognizes typed references, then searches an offline translation (all words must match). */
export async function search(url: URL, env: Env) {
  const q = (url.searchParams.get("q") ?? "").trim();
  if (q.length < 2 || q.length > 100) throw badRequest("q must be 2-100 characters");
  const limit = Math.min(Math.max(Number(url.searchParams.get("limit")) || 20, 1), 50);

  // Word search covers the offline translations (online providers' search isn't connected yet).
  const t = await translation(env, url.searchParams.get("translation") ?? "kjv");
  if (t.provider !== "local") throw badRequest(`Search isn't available for ${t.abbreviation ?? t.name} yet; try KJV, BSB or WEB`);
  const searchIn = t.id;

  // A typed reference ("Proverbs 31") is answered by the reference alone; word matches would only add noise.
  const reference = await referenceFromQuery(env, q);
  const words = q.toLowerCase().match(/[a-z']+/g)?.filter((w) => w.replace(/'/g, "").length > 1) ?? [];
  if (reference || words.length === 0) return Response.json({ reference, translation: searchIn, results: [] });

  const match = words.map((w) => `"${w.replace(/"/g, "")}"`).join(" ");
  const rows = await env.DB.prepare(
    `SELECT v.book_id, v.chapter, v.verse, v.text FROM verses_fts f JOIN verses v ON v.rowid = f.rowid
     WHERE verses_fts MATCH ?1 AND v.translation_id = ?2 ORDER BY f.rank LIMIT ?3`,
  ).bind(match, searchIn, limit).all<{ book_id: string; chapter: number; verse: number; text: string }>();

  return Response.json({
    reference,
    translation: searchIn,
    results: rows.results.map((r) => ({
      ref: `${r.book_id}.${r.chapter}.${r.verse}`,
      label: refLabel(r.book_id, r.chapter, r.verse),
      text: r.text,
    })),
  });
}
