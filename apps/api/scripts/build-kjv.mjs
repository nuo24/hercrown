// Builds the KJV data from seven1m/open-bibles (eng-kjv.osis.xml, public domain; the data bible-api.com serves).
//
//   node scripts/build-kjv.mjs [path-to-eng-kjv.osis.xml]
//
// Without a path it downloads the pinned file. Outputs (all generated, committed):
//   seeds/kjv.sql        verse text for D1        → npm run seed:kjv
//   seeds/kjv-test.sql   a few chapters for tests
//   seeds/kjv.json       compact offline bundle for the iOS app
//   (books + chapter verse counts were generated once into migrations/0003_scripture.sql)
// Transform: verse text between OSIS milestones, notes removed, tags stripped, whitespace collapsed. Nothing else.
import { createHash } from "node:crypto";
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

/** verses[usfm][chapter-1][verse-1] = text */
const verses = new Map(BOOKS.map(([id]) => [id, []]));
const start = /<verse\b[^>]*\bosisID="([^"]+)"[^>]*\bsID="([^"]+)"[^>]*\/>/g;
let m;
while ((m = start.exec(text))) {
  const [osisBook, ch, v] = m[1].split(".");
  const end = text.indexOf(`eID="${m[2]}"`, start.lastIndex);
  if (end < 0) throw new Error(`Unclosed verse ${m[1]}`);
  const body = text.slice(start.lastIndex, text.lastIndexOf("<", end));
  if (!usfmFor.has(osisBook)) continue; // Apocrypha
  const book = verses.get(usfmFor.get(osisBook));
  (book[ch - 1] ??= [])[v - 1] = clean(body);
}

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
  const rows = [];
  for (const [id] of BOOKS) verses.get(id).forEach((vs, c) => {
    if (filter(id, c + 1)) vs.forEach((t, v) => rows.push(`('kjv',${sq(id)},${c + 1},${v + 1},${sq(t)})`));
  });
  const out = [];
  for (let i = 0; i < rows.length; i += 200) out.push(`INSERT INTO verses (translation_id, book_id, chapter, verse, text) VALUES\n${rows.slice(i, i + 200).join(",\n")};`);
  return out.join("\n") + "\nINSERT INTO verses_fts (verses_fts) VALUES ('rebuild');\n";
}

const header = `-- Generated by scripts/build-kjv.mjs from ${SOURCE_URL}\n-- sha256 ${SOURCE_SHA256}. Do not edit by hand.\n`;
writeFileSync(new URL("kjv.sql", outDir), header + "DELETE FROM verses WHERE translation_id = 'kjv';\n" + verseInserts());

// Chapters the tests use: the fixtures, the shortest/longest chapters and canon boundaries.
const TEST_CHAPTERS = new Set(["GEN.1", "GEN.2", "GEN.50", "EXO.1", "PSA.23", "PSA.107", "PSA.117", "PSA.119", "PRO.3",
  "PRO.17", "PRO.31", "JER.29", "MAL.4", "MAT.1", "MAT.11", "JAS.1", "3JN.1", "REV.22"]);
writeFileSync(new URL("kjv-test.sql", outDir), header + verseInserts((id, c) => TEST_CHAPTERS.has(`${id}.${c}`)));

writeFileSync(new URL("kjv.json", outDir), JSON.stringify({
  translation: { id: "kjv", name: "King James Version", license: "Public Domain", source: SOURCE_URL, sha256: SOURCE_SHA256 },
  books: BOOKS.map(([id, name, testament]) => ({ id, name, testament, chapters: verses.get(id) })),
}));

console.log(`OK: ${EXPECTED.books} books, ${chapterTotal} chapters, ${verseTotal} verses; ${compared} kit verses match exactly.`);
