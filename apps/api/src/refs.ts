// Canonical passage references: "BOOK.CHAPTER.VERSE" or "BOOK.CHAPTER.VERSE-VERSE" with USFM book ids.
import books from "./books.json";
import { badRequest } from "./http";

/** The 66-book Protestant canon: [USFM id, name, testament, chapter count], in canonical order (books.json). */
export type Book = readonly [id: string, name: string, testament: "OT" | "NT", chapters: number];
export const BOOKS = books as unknown as readonly Book[];

const chapterCounts = new Map<string, number>(BOOKS.map(([id, , , chapters]) => [id, chapters]));

const REF = /^([0-9A-Z]{3})\.(\d{1,3})\.(\d{1,3})(?:-(\d{1,3}))?$/;
const ALIAS = /^[a-z]{1,4}\d{1,3}$/;

export interface ParsedRef {
  ref: string; // normalized canonical form
  book: string;
  chapter: number;
  start: number;
  end: number;
}

/** Parses a canonical reference, checking the book and chapter exist. Verse bounds are checked by resolveRef. */
export function parseRef(input: string): ParsedRef | null {
  const m = REF.exec(input);
  if (!m) return null;
  const [, book, ch, v1, v2] = m;
  const chapters = chapterCounts.get(book);
  const chapter = Number(ch), start = Number(v1), end = v2 === undefined ? start : Number(v2);
  if (!chapters || chapter < 1 || chapter > chapters || start < 1 || end < start) return null;
  const ref = end === start ? `${book}.${chapter}.${start}` : `${book}.${chapter}.${start}-${end}`;
  return { ref, book, chapter, start, end };
}

export const normalizeRef = (input: string) => parseRef(input)?.ref ?? null;

/**
 * Accepts a canonical reference or a prototype alias ("ps23") and returns the canonical form.
 * Verses are checked against the chapter's real length (chapter_verse_counts).
 */
export async function resolveRef(db: D1Database, input: string): Promise<string> {
  const ref = ALIAS.test(input)
    ? (await db.prepare("SELECT ref FROM passage_aliases WHERE alias = ?1").bind(input).first<{ ref: string }>())?.ref
    : normalizeRef(input);
  const parsed = ref ? parseRef(ref) : null;
  if (!parsed) throw badRequest(`Unknown passage reference: ${input}`);
  const count = await db.prepare("SELECT verse_count FROM chapter_verse_counts WHERE book_id = ?1 AND chapter = ?2")
    .bind(parsed.book, parsed.chapter).first<{ verse_count: number }>();
  if (!count || parsed.end > count.verse_count) {
    throw badRequest(`Unknown passage reference: ${input} (${parsed.book} ${parsed.chapter} has ${count?.verse_count ?? 0} verses)`);
  }
  return parsed.ref;
}
