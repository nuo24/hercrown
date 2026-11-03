// Builds the KJV data from seven1m/open-bibles (eng-kjv.osis.xml, public domain; the data bible-api.com serves).
//
//   node scripts/build-kjv.mjs [path-to-eng-kjv.osis.xml]
//
// Without a path it downloads the pinned file. Outputs (all generated, committed):
//   seeds/kjv.sql        verse text for D1        → npm run seed:kjv
//   seeds/kjv-test.sql   a few chapters for tests
//   seeds/kjv.json       compact offline bundle for the iOS app (same format as bsb.json / web.json)
//   seeds/kjv-meta.json  per-chapter verse numbers
//   (books + chapter verse counts were generated once into migrations/0003_scripture.sql)
// Transform: verse text between OSIS milestones, notes removed, tags stripped, whitespace collapsed. Nothing else.
import { createHash } from "node:crypto";
import { existsSync } from "node:fs";
import { finishVerse, WJ_CLOSE, WJ_OPEN } from "./scripture-text.mjs";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
const BOOKS = JSON.parse(readFileSync(new URL("../src/books.json", import.meta.url)));

const SOURCE_URL = "https://raw.githubusercontent.com/seven1m/open-bibles/master/eng-kjv.osis.xml";
const SOURCE_SHA256 = "eeeae647fc28360ce47f9c0d5cc3b397b7fdd9913fe53dc9f44eb6deee50e253";
const EXPECTED = { books: 66, chapters: 1189, verses: 31102 };

const input = process.argv[2];
const xml = input ? readFileSync(input) : Buffer.from(await (await fetch(SOURCE_URL)).arrayBuffer());
const sha = createHash("sha256").update(xml).digest("hex");
if (sha !== SOURCE_SHA256) throw new Error(`Source checksum changed: ${sha}. Review the new file, then update SOURCE_SHA256.`);
const text = xml.toString("utf8");

// ── Parse ─────────────────────────────────────────────────────────────────────
const decode = (s) => s.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&amp;/g, "&");
const clean = (s) => decode(s.replace(/<note\b[\s\S]*?<\/note>/g, "").replace(/<[^>]+>/g, "")).replace(/\s+/g, " ").trim();

// OSIS book ids for the 66-book canon, in BOOKS order. The source also has the Apocrypha, which is skipped.
const OSIS = ["Gen", "Exod", "Lev", "Num", "Deut", "Josh", "Judg", "Ruth", "1Sam", "2Sam", "1Kgs", "2Kgs", "1Chr", "2Chr",
  "Ezra", "Neh", "Esth", "Job", "Ps", "Prov", "Eccl", "Song", "Isa", "Jer", "Lam", "Ezek", "Dan", "Hos", "Joel", "Amos",
  "Obad", "Jonah", "Mic", "Nah", "Hab", "Zeph", "Hag", "Zech", "Mal", "Matt", "Mark", "Luke", "John", "Acts", "Rom",
  "1Cor", "2Cor", "Gal", "Eph", "Phil", "Col", "1Thess", "2Thess", "1Tim", "2Tim", "Titus", "Phlm", "Heb", "Jas",
  "1Pet", "2Pet", "1John", "2John", "3John", "Jude", "Rev"];
const usfmFor = new Map(OSIS.map((osis, i) => [osis, BOOKS[i][0]]));
const osisBooks = new Set([...text.matchAll(/<div type="book" osisID="([^"]+)"/g)].map((m) => m[1]));
const missing = OSIS.filter((b) => !osisBooks.has(b));
if (missing.length) throw new Error(`Source is missing books: ${missing.join(", ")}`);

/** verses[usfm][chapter-1][verse-1] = text; wordsOfJesus["GEN.1.1"] = ranges */
const verses = new Map(BOOKS.map(([id]) => [id, []]));
const wordsOfJesus = new Map();

// Words of Jesus are <q who="Jesus" sID=…/> … <q eID=…/> milestones, which can span verses.
const jesusIds = new Set([...text.matchAll(/<q\b[^>]*who="Jesus"[^>]*\bsID="([^"]+)"/g)].map((q) => q[1]));
const jesusEvents = [...text.matchAll(/<q\b[^>]*\b(sID|eID)="([^"]+)"[^>]*\/>/g)]
  .filter((q) => jesusIds.has(q[2]))
  .map((q) => ({ at: q.index, open: q[1] === "sID" }));
let eventIndex = 0, inJesus = false;
const markJesus = (s) => s.replace(/<q\b[^>]*\b(sID|eID)="([^"]+)"[^>]*\/>/g, (tag, kind, id) =>
  jesusIds.has(id) ? (kind === "sID" ? WJ_OPEN : WJ_CLOSE) : tag);

const start = /<verse\b[^>]*\bosisID="([^"]+)"[^>]*\bsID="([^"]+)"[^>]*\/>/g;
let m;
while ((m = start.exec(text))) {
  const [osisBook, ch, v] = m[1].split(".");
  const end = text.indexOf(`eID="${m[2]}"`, start.lastIndex);
  if (end < 0) throw new Error(`Unclosed verse ${m[1]}`);
  const bodyStart = start.lastIndex, bodyEnd = text.lastIndexOf("<", end);
  const body = text.slice(bodyStart, bodyEnd);
  // Quote state at the start of this verse, then advance past the events inside it.
  while (eventIndex < jesusEvents.length && jesusEvents[eventIndex].at < bodyStart) inJesus = jesusEvents[eventIndex++].open;
  const startsInside = inJesus;
  while (eventIndex < jesusEvents.length && jesusEvents[eventIndex].at < bodyEnd) inJesus = jesusEvents[eventIndex++].open;
  if (!usfmFor.has(osisBook)) continue; // Apocrypha
  const id = usfmFor.get(osisBook);
  const plain = clean(body);
  const [marked, ranges] = finishVerse(clean((startsInside ? WJ_OPEN : "") + markJesus(body) + (inJesus ? WJ_CLOSE : "")));
  if (marked !== plain) throw new Error(`${m[1]}: words-of-Jesus marking changed the text`);
  (verses.get(id)[ch - 1] ??= [])[v - 1] = plain;
  if (ranges) wordsOfJesus.set(`${id}.${ch}.${v}`, ranges);
}

// Psalm titles (canonical superscriptions), kept apart from verse 1. Psalm 119's letter headings are skipped.
const titles = new Map();
for (const t of text.matchAll(/<title type="psalm"[^>]*>([\s\S]*?)<\/title>/g)) {
  const title = clean(t[1]);
  if (/^[A-Z]+\.?$/.test(title)) continue; // ALEPH. BETH. …
  const next = text.slice(t.index).match(/osisID="Ps\.(\d+)\.\d+"/);
  titles.set(`PSA.${next[1]}`, title);
}
if (titles.size !== 116) throw new Error(`Expected 116 psalm titles, found ${titles.size}`);

// ── Validate ──────────────────────────────────────────────────────────────────
let chapterTotal = 0, verseTotal = 0;
for (const [id, , , chapterCount] of BOOKS) {
  const chapters = verses.get(id);
  if (chapters.length !== chapterCount) throw new Error(`${id}: ${chapters.length} chapters, expected ${chapterCount}`);
  chapters.forEach((vs, i) => {
    if (!vs || vs.length === 0) throw new Error(`${id} ${i + 1}: no verses`);
    vs.forEach((t, j) => { if (!t) throw new Error(`${id} ${i + 1}:${j + 1} missing or empty`); });
    verseTotal += vs.length;
  });
  chapterTotal += chapters.length;
}
if (chapterTotal !== EXPECTED.chapters || verseTotal !== EXPECTED.verses) {
  throw new Error(`Totals ${chapterTotal} chapters / ${verseTotal} verses, expected ${EXPECTED.chapters} / ${EXPECTED.verses}`);
}

// Must match the kit's verified fixture text exactly (Genesis 1, Psalm 23 and the nine passage cards).
const kit = new URL("../../../", import.meta.url);
const { chapters: kitChapters } = await import(new URL("reference-web/dist/chapters.mjs", kit));
const fixtures = JSON.parse(readFileSync(new URL("specs/content-fixtures.json", kit)));
const byName = new Map(BOOKS.map(([id, name]) => [name, id]));
const lookup = (name, ch, v) => verses.get(byName.get(name === "Psalm" ? "Psalms" : name))[ch - 1][v - 1];
let compared = 0;
for (const [key, list] of Object.entries(kitChapters)) {
  const [, name, ch] = key.match(/^(.*) (\d+)$/);
  list.forEach(([t], i) => { compared++; if (lookup(name, +ch, i + 1) !== t) throw new Error(`${key}:${i + 1} differs from kit fixture`); });
}
for (const f of fixtures.verses) {
  const [, name, ch, v] = f.ref.match(/^(.*) (\d+):(\d+)$/);
  compared++;
  if (lookup(name, +ch, +v) !== f.text) throw new Error(`${f.ref} differs from kit fixture`);
}

// ── Write ─────────────────────────────────────────────────────────────────────
const outDir = new URL("../seeds/", import.meta.url);
mkdirSync(outDir, { recursive: true });
const sq = (s) => `'${s.replace(/'/g, "''")}'`;

function verseInserts(filter = () => true) {
  const rows = [], titleRows = [];
  for (const [id] of BOOKS) verses.get(id).forEach((vs, c) => {
    if (!filter(id, c + 1)) return;
    vs.forEach((t, v) => {
      const wj = wordsOfJesus.get(`${id}.${c + 1}.${v + 1}`);
      rows.push(`('kjv',${sq(id)},${c + 1},${v + 1},${sq(t)},${wj ? sq(JSON.stringify(wj)) : "NULL"})`);
    });
    const title = titles.get(`${id}.${c + 1}`);
    if (title) titleRows.push(`('kjv',${sq(id)},${c + 1},${sq(title)})`);
  });
  const out = [];
  for (let i = 0; i < rows.length; i += 200) out.push(`INSERT INTO verses (translation_id, book_id, chapter, verse, text, words_of_jesus) VALUES\n${rows.slice(i, i + 200).join(",\n")};`);
  if (titleRows.length) out.push(`INSERT INTO chapter_titles (translation_id, book_id, chapter, text) VALUES\n${titleRows.join(",\n")};`);
  return out.join("\n") + "\nINSERT INTO verses_fts (verses_fts) VALUES ('rebuild');\n";
}

const header = `-- Generated by scripts/build-kjv.mjs from ${SOURCE_URL}\n-- sha256 ${SOURCE_SHA256}. Do not edit by hand.\n`;
// The verse text must not change when the data format does: compare with the committed bundle.
const previous = new URL("kjv.json", outDir);
if (existsSync(previous)) {
  const old = JSON.parse(readFileSync(previous));
  for (const book of old.books) book.chapters.forEach((ch, c) => {
    const vs = Array.isArray(ch) ? ch : ch.verses.map((v) => v.t);
    vs.forEach((t, v) => { if (verses.get(book.id)[c][v] !== t) throw new Error(`${book.id} ${c + 1}:${v + 1} text changed`); });
  });
}

writeFileSync(new URL("kjv.sql", outDir), header +
  "DELETE FROM chapter_titles WHERE translation_id = 'kjv';\nDELETE FROM verses WHERE translation_id = 'kjv';\n" + verseInserts());

// Chapters the tests use: the fixtures, the shortest/longest chapters and canon boundaries.
const TEST_CHAPTERS = new Set(["GEN.1", "GEN.2", "GEN.50", "EXO.1", "PSA.23", "PSA.107", "PSA.117", "PSA.119", "PRO.3",
  "PRO.17", "PRO.31", "JER.29", "MAL.4", "MAT.1", "MAT.11", "MAT.17", "JHN.3", "JAS.1", "3JN.1", "REV.22"]);
writeFileSync(new URL("kjv-test.sql", outDir), header + verseInserts((id, c) => TEST_CHAPTERS.has(`${id}.${c}`)));

writeFileSync(new URL("kjv.json", outDir), JSON.stringify({
  translation: { id: "kjv", name: "King James Version", license: "Public Domain", source: SOURCE_URL, sha256: SOURCE_SHA256 },
  books: BOOKS.map(([id, name, testament]) => ({
    id, name, testament,
    chapters: verses.get(id).map((vs, c) => ({
      title: titles.get(`${id}.${c + 1}`) ?? null,
      verses: vs.map((t, v) => {
        const wj = wordsOfJesus.get(`${id}.${c + 1}.${v + 1}`);
        return wj ? { n: v + 1, t, wj } : { n: v + 1, t };
      }),
    })),
  })),
}));

writeFileSync(new URL("kjv-meta.json", outDir), JSON.stringify(
  Object.fromEntries(BOOKS.map(([id]) => [id, verses.get(id).map((vs) => vs.map((_, v) => v + 1))])),
));
console.log(`OK: ${EXPECTED.books} books, ${chapterTotal} chapters, ${verseTotal} verses; ${compared} kit verses match exactly; ` +
  `${titles.size} psalm titles; ${wordsOfJesus.size} verses with words of Jesus; verse text unchanged.`);
