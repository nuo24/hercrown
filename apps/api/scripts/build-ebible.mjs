// Builds offline translations from eBible.org USFM (public domain): Berean Standard Bible, World English Bible.
//
//   node scripts/build-ebible.mjs bsb|web [dir-with-downloaded-zips]
//
// Without a directory it downloads the pinned zips. Each build is checked against eBible's own
// verse-per-line (VPL) edition of the same text: every verse must match exactly (psalm titles,
// which VPL merges into verse 1, are kept separate here). Outputs (generated, committed):
//   seeds/<id>.sql        verses + psalm titles for D1   → npm run seed:<id>
//   seeds/<id>-test.sql   a few chapters for tests
//   seeds/<id>.json       compact offline bundle for the iOS app
//   seeds/<id>-meta.json  per-chapter verse numbers (used to update canonical counts)
// Transform: footnotes, cross-references, section headings and Strong's tags removed; words of Jesus
// (\wj) recorded as UTF-16 [start, length] ranges; whitespace collapsed. The words themselves are unchanged.
import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { mkdirSync, mkdtempSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { finishVerse, WJ_CLOSE, WJ_OPEN } from "./scripture-text.mjs";

const EDITIONS = {
  bsb: {
    ebibleId: "engbsb",
    name: "Berean Standard Bible",
    usfmSha256: "75ca91d5a5c69ca4cbdeabdb03ea1a458db20cf3966abe15d86df086acf7fbc4",
    vplSha256: "72ecd9e0131e82737b76e1f2d706c85771d6054b6350673f80f49c839133f45e",
    expected: { verses: 31086 }, // eBible: OT 23,145 + NT 7,941 (omits verses absent from early manuscripts)
  },
  web: {
    ebibleId: "engwebp",
    name: "World English Bible",
    usfmSha256: "a93df5571009fed56f77e3ac1d3ce71c9a3a3df1486f7570cc7a8f823192fdba",
    vplSha256: "37a8ccecfbc765a2305ae64f3b5e88d1d01bafceb9a33e8d191f6ee551a437b9",
    expected: { verses: 31103 }, // eBible: OT 23,145 + NT 7,958
  },
};

const id = process.argv[2];
const edition = EDITIONS[id];
if (!edition) throw new Error(`Usage: node scripts/build-ebible.mjs ${Object.keys(EDITIONS).join("|")} [dir]`);
const BOOKS = JSON.parse(readFileSync(new URL("../src/books.json", import.meta.url)));
const bookIds = new Set(BOOKS.map((b) => b[0]));

// ── Sources (pinned) ─────────────────────────────────────────────────────────
async function source(kind) {
  const file = `${edition.ebibleId}_${kind}.zip`;
  const bytes = process.argv[3]
    ? readFileSync(join(process.argv[3], file))
    : Buffer.from(await (await fetch(`https://ebible.org/Scriptures/${file}`)).arrayBuffer());
  const sha = createHash("sha256").update(bytes).digest("hex");
  const pinned = kind === "usfm" ? edition.usfmSha256 : edition.vplSha256;
  if (sha !== pinned) throw new Error(`${file} checksum changed: ${sha}. Review eBible's update, then update the pin.`);
  const dir = mkdtempSync(join(tmpdir(), `${id}-${kind}-`));
  writeFileSync(join(dir, file), bytes);
  execFileSync("unzip", ["-q", "-o", join(dir, file), "-d", dir]);
  return dir;
}
const usfmDir = await source("usfm");
const vplDir = await source("vpl");

// ── Parse USFM ───────────────────────────────────────────────────────────────
const SKIP_LINE = /^\\(id|ide|h|toc\d|mt\d?|ms\d?|mr|s\d?|sr|r|sp|cl|cd|rem|d|qa|periph|imt\d?|is\d?|ip|iot|io\d?)\b/;

/** Verse text from USFM: keep words, drop notes/markup, mark \wj spans with sentinels. */
function cleanVerse(raw) {
  return raw
    .replace(/\\f\s[\s\S]*?\\f\*/g, "")             // footnotes
    .replace(/\\x\s[\s\S]*?\\x\*/g, "")             // cross-references
    .replace(/\\\+?w\s([^|\\]*?)(\|[^\\]*)?\\\+?w\*/g, "$1") // \w word|strong="…"\w*
    .replace(/\\wj\s/g, WJ_OPEN).replace(/\\wj\*/g, WJ_CLOSE)
    .replace(/\\\+?[a-z]+\d*\*/g, "")                // closing markers (\k* \qs* \bk* …): no space, punctuation may follow
    .replace(/\\\+?[a-z]+\d*/g, " ")                // opening/paragraph markers (\p \q1 \k \qs \add …), keep their text
    .replace(/\s+/g, " ");
}

const verses = new Map(BOOKS.map(([b]) => [b, []])); // verses[book][chapter-1] = Map(verse → {text, wj})
const titles = new Map(); // "PSA.23" → "A Psalm by David."
const acrostics = new Map(); // "PSA.119.1" → "ALEPH" (Psalm 119 letter headings; headings, not verse text)
const speakers = new Map(); // "SNG.1.4" → ["Friends", "Beloved"] (Song of Solomon speaker labels; editorial, not verse text)

for (const file of readdirSync(usfmDir).filter((f) => f.endsWith(".usfm"))) {
  const text = readFileSync(join(usfmDir, file), "utf8");
  const book = text.match(/^\\id\s+(\S+)/m)?.[1];
  if (!bookIds.has(book)) continue; // front matter, glossary, etc.
  let chapter = 0, verse = null, buffer = "", pendingQa = null;
  const flush = () => {
    if (verse !== null) {
      const [t, wj] = finishVerse(cleanVerse(buffer));
      const chapters = verses.get(book);
      (chapters[chapter - 1] ??= new Map()).set(verse, { text: t, wj });
    }
    verse = null; buffer = "";
  };
  for (const line of text.split(/\r?\n/)) {
    const c = line.match(/^\\c\s+(\d+)/);
    if (c) { flush(); chapter = Number(c[1]); continue; }
    const d = line.match(/^\\d\s+(.*)$/);
    if (d) {
      const text = finishVerse(cleanVerse(d[1]))[0];
      // WEB marks Psalm 119's letter headings (ALEPH, BETH, …) as \d; they head a stanza, not the psalm.
      if (/^[A-Z]+( [A-Z]+)*$/.test(text)) pendingQa = text;
      else { flush(); titles.set(`${book}.${chapter}`, text); }
      continue;
    }
    const qa = line.match(/^\\qa\s+(.*)$/);
    if (qa) { pendingQa = finishVerse(cleanVerse(qa[1]))[0]; continue; }
    const sp = line.match(/^\\sp\s+(.*)$/);
    if (sp) {
      const key = `${book}.${chapter}.${verse ?? "next"}`;
      speakers.set(key, [...(speakers.get(key) ?? []), finishVerse(cleanVerse(sp[1]))[0]]);
      continue;
    }
    if (SKIP_LINE.test(line)) continue;
    // A line may hold several verses: split at each \v N.
    const parts = line.split(/\\v\s+(\d+)\s/);
    buffer += " " + parts[0];
    for (let i = 1; i < parts.length; i += 2) {
      flush();
      verse = Number(parts[i]);
      buffer = parts[i + 1] ?? "";
      if (pendingQa) { acrostics.set(`${book}.${chapter}.${verse}`, pendingQa); pendingQa = null; }
      const before = speakers.get(`${book}.${chapter}.next`);
      if (before) { speakers.set(`${book}.${chapter}.${verse}`, before); speakers.delete(`${book}.${chapter}.next`); }
    }
  }
  flush();
}

// ── Validate ─────────────────────────────────────────────────────────────────
// Some editions keep an empty verse (only a footnote) where later manuscripts add a verse, e.g. WEB Luke 17:36.
// Those count toward eBible's totals but are omitted from our data.
let markerTotal = 0;
const omitted = [];
for (const [b, , , chapterCount] of BOOKS) {
  const chapters = verses.get(b);
  if (chapters.length !== chapterCount) throw new Error(`${b}: ${chapters.length} chapters, expected ${chapterCount}`);
  chapters.forEach((vs, i) => {
    if (!vs || vs.size === 0) throw new Error(`${b} ${i + 1}: no verses`);
    markerTotal += vs.size;
    for (const [n, v] of vs) {
      if (!v.text) { omitted.push(`${b} ${i + 1}:${n}`); vs.delete(n); continue; }
      if (/\s{2}|^\s|\s$/.test(v.text)) throw new Error(`${b} ${i + 1}:${n} has stray whitespace: ${JSON.stringify(v.text)}`);
    }
  });
}
if (markerTotal !== edition.expected.verses) throw new Error(`${markerTotal} verse markers, expected ${edition.expected.verses}`);
const verseTotal = markerTotal - omitted.length;

// Every verse must equal eBible's own plain-text (VPL) edition of the same release.
const vpl = readFileSync(join(vplDir, `${edition.ebibleId}_vpl.txt`), "utf8").split(/\r?\n/).filter(Boolean);
// The VPL text file uses BibleWorks-style book codes (e.g. 3JO); map them by canonical order.
const vplCodes = [...new Set(vpl.map((l) => l.split(" ")[0]))];
if (vplCodes.length !== 66) throw new Error(`VPL has ${vplCodes.length} books`);
const vplBook = new Map(vplCodes.map((code, i) => [code, BOOKS[i][0]]));
let compared = 0, titleMerged = 0, acrosticMerged = 0, speakerLabels = 0;
for (const line of vpl) {
  const m = line.match(/^(\S+) (\d+):(\d+) ?(.*)$/);
  if (!m) throw new Error(`Unexpected VPL line: ${line.slice(0, 80)}`);
  let [, code, ch, v, expected] = m;
  const b = vplBook.get(code);
  const ours = verses.get(b)[ch - 1]?.get(Number(v));
  if (!expected.trim() && !ours && omitted.includes(`${b} ${ch}:${v}`)) continue; // omitted in both
  if (!ours) throw new Error(`Missing ${b} ${ch}:${v}`);
  const title = titles.get(`${b}.${ch}`);
  const norm = (s) => s.replace(/\s+/g, " ").trim();
  // Remove this verse's speaker labels (and a label that VPL attached from the next verse) before comparing.
  let vplText = expected;
  for (const label of [...(speakers.get(`${b}.${ch}.${v}`) ?? []), ...(speakers.get(`${b}.${ch}.${Number(v) + 1}`) ?? [])]) {
    const at = vplText.indexOf(label);
    if (at >= 0 && (at === 0 || vplText[at - 1] === " ")) { vplText = vplText.slice(0, at) + vplText.slice(at + label.length); speakerLabels++; }
  }
  expected = vplText;
  if (norm(ours.text) === norm(expected)) compared++;
  else if (v === "1" && title && norm(`${title} ${ours.text}`) === norm(expected)) { compared++; titleMerged++; }
  // VPL glues a letter heading onto a neighbouring verse: before the first stanza, after the previous verse otherwise.
  else if (acrostics.has(`${b}.${ch}.${v}`) && norm(`${acrostics.get(`${b}.${ch}.${v}`)} ${ours.text}`) === norm(expected)) { compared++; acrosticMerged++; }
  else if (acrostics.has(`${b}.${ch}.${Number(v) + 1}`) && norm(`${ours.text} ${acrostics.get(`${b}.${ch}.${Number(v) + 1}`)}`) === norm(expected)) { compared++; acrosticMerged++; }
  else throw new Error(`${b} ${ch}:${v} differs from eBible's VPL\n  ours: ${ours.text}\n  vpl:  ${expected}`);
}
if (compared !== verseTotal) throw new Error(`Compared ${compared} of ${verseTotal} verses`);

// ── Write ────────────────────────────────────────────────────────────────────
const outDir = new URL("../seeds/", import.meta.url);
mkdirSync(outDir, { recursive: true });
const sq = (s) => `'${s.replace(/'/g, "''")}'`;
const header = `-- Generated by scripts/build-ebible.mjs ${id} from eBible.org ${edition.ebibleId}_usfm.zip\n-- sha256 ${edition.usfmSha256}. Do not edit by hand.\n`;

function inserts(filter = () => true) {
  const rows = [], titleRows = [];
  for (const [b] of BOOKS) verses.get(b).forEach((vs, c) => {
    if (!filter(b, c + 1)) return;
    for (const [n, v] of [...vs].sort((x, y) => x[0] - y[0])) {
      rows.push(`(${sq(id)},${sq(b)},${c + 1},${n},${sq(v.text)},${v.wj ? sq(JSON.stringify(v.wj)) : "NULL"})`);
    }
    const title = titles.get(`${b}.${c + 1}`);
    if (title) titleRows.push(`(${sq(id)},${sq(b)},${c + 1},${sq(title)})`);
  });
  const out = [];
  for (let i = 0; i < rows.length; i += 200) {
    out.push(`INSERT INTO verses (translation_id, book_id, chapter, verse, text, words_of_jesus) VALUES\n${rows.slice(i, i + 200).join(",\n")};`);
  }
  if (titleRows.length) out.push(`INSERT INTO chapter_titles (translation_id, book_id, chapter, text) VALUES\n${titleRows.join(",\n")};`);
  return out.join("\n") + "\nINSERT INTO verses_fts (verses_fts) VALUES ('rebuild');\n";
}

writeFileSync(new URL(`${id}.sql`, outDir), header +
  `DELETE FROM chapter_titles WHERE translation_id = ${sq(id)};\nDELETE FROM verses WHERE translation_id = ${sq(id)};\n` + inserts());
const TEST = new Set(["GEN.1", "PSA.23", "PSA.117", "MAT.11", "MAT.17", "JHN.3", "3JN.1", "REV.12"]);
writeFileSync(new URL(`${id}-test.sql`, outDir), header + inserts((b, c) => TEST.has(`${b}.${c}`)));

writeFileSync(new URL(`${id}.json`, outDir), JSON.stringify({
  translation: { id, name: edition.name, license: "Public Domain", source: `https://ebible.org/Scriptures/${edition.ebibleId}_usfm.zip`, sha256: edition.usfmSha256 },
  books: BOOKS.map(([b, name, testament]) => ({
    id: b, name, testament,
    chapters: verses.get(b).map((vs, c) => ({
      title: titles.get(`${b}.${c + 1}`) ?? null,
      verses: [...vs].sort((x, y) => x[0] - y[0]).map(([n, v]) => (v.wj ? { n, t: v.text, wj: v.wj } : { n, t: v.text })),
    })),
  })),
}));

writeFileSync(new URL(`${id}-meta.json`, outDir), JSON.stringify(
  Object.fromEntries(BOOKS.map(([b]) => [b, verses.get(b).map((vs) => [...vs.keys()].sort((x, y) => x - y))])),
));

const wjVerses = [...verses.values()].flat().reduce((n, vs) => n + [...vs.values()].filter((v) => v.wj).length, 0);
console.log(`OK ${id}: 66 books, 1189 chapters, ${verseTotal} verses; all ${compared} match eBible's VPL (${titleMerged} with a separate psalm title, ${acrosticMerged} with a separate Psalm 119 letter heading, ${speakerLabels} speaker labels kept out of verses); ${titles.size} titles; ${wjVerses} verses with words of Jesus.`);
console.log(`Omitted in this edition (${omitted.length}): ${omitted.join(", ") || "none"}`);
