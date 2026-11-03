// Builds the data behind the Plus study tools from freely licensed sources (decision 0006):
//   • Cross-references: OpenBible.info (CC BY), with votes
//   • Greek & Hebrew words: STEPBible TAGNT / TAHOT, lexicons TBESG / TBESH (CC BY 4.0, Tyndale House Cambridge), pinned commit
//   • Commentaries (public domain): Jamieson-Fausset-Brown, Matthew Henry, Adam Clarke, via the Free Use Bible API
// Nothing is reworded: notes and glosses are stored as published, with markup stripped.
//
//   node scripts/build-study.mjs            build; fails if a source changed since seeds/study-sources.json
//   node scripts/build-study.mjs --update   accept new source checksums (review the diff in study-meta.json)
//
// Outputs: seeds/study/*.sql (large, gitignored, rebuilt by this script), seeds/study-test.sql, seeds/study-meta.json,
// seeds/study-sources.json. Downloads are cached in .cache/study.
import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const ROOT = new URL("..", import.meta.url).pathname;
const CACHE = join(ROOT, ".cache/study");
const OUT = join(ROOT, "seeds/study");
const SOURCES_FILE = join(ROOT, "seeds/study-sources.json");
const UPDATE = process.argv.includes("--update");
mkdirSync(CACHE, { recursive: true });
mkdirSync(OUT, { recursive: true });

const BOOKS = JSON.parse(readFileSync(join(ROOT, "src/books.json"), "utf8"));
const IDS = BOOKS.map((b) => b[0]);
const OSIS = ["Gen", "Exod", "Lev", "Num", "Deut", "Josh", "Judg", "Ruth", "1Sam", "2Sam", "1Kgs", "2Kgs", "1Chr", "2Chr",
  "Ezra", "Neh", "Esth", "Job", "Ps", "Prov", "Eccl", "Song", "Isa", "Jer", "Lam", "Ezek", "Dan", "Hos", "Joel", "Amos",
  "Obad", "Jonah", "Mic", "Nah", "Hab", "Zeph", "Hag", "Zech", "Mal", "Matt", "Mark", "Luke", "John", "Acts", "Rom",
  "1Cor", "2Cor", "Gal", "Eph", "Phil", "Col", "1Thess", "2Thess", "1Tim", "2Tim", "Titus", "Phlm", "Heb", "Jas",
  "1Pet", "2Pet", "1John", "2John", "3John", "Jude", "Rev"];
const STEP = ["Gen", "Exo", "Lev", "Num", "Deu", "Jos", "Jdg", "Rut", "1Sa", "2Sa", "1Ki", "2Ki", "1Ch", "2Ch", "Ezr", "Neh",
  "Est", "Job", "Psa", "Pro", "Ecc", "Sng", "Isa", "Jer", "Lam", "Ezk", "Dan", "Hos", "Jol", "Amo", "Oba", "Jon", "Mic", "Nam",
  "Hab", "Zep", "Hag", "Zec", "Mal", "Mat", "Mrk", "Luk", "Jhn", "Act", "Rom", "1Co", "2Co", "Gal", "Eph", "Php", "Col", "1Th",
  "2Th", "1Ti", "2Ti", "Tit", "Phm", "Heb", "Jas", "1Pe", "2Pe", "1Jn", "2Jn", "3Jn", "Jud", "Rev"];
const fromOsis = new Map(OSIS.map((b, i) => [b, IDS[i]]));
const fromStep = new Map(STEP.map((b, i) => [b, IDS[i]]));

// Canonical verse bounds (migration 0003 + 0006).
const bounds = new Map();
const migration = readFileSync(join(ROOT, "migrations/0003_scripture.sql"), "utf8");
for (const m of migration.matchAll(/\('([1-3A-Z]{3})',(\d+),(\d+)\)/g)) bounds.set(`${m[1]}.${m[2]}`, Number(m[3]));
bounds.set("ROM.14", 26);
const inBounds = (book, ch, v) => v >= 1 && v <= (bounds.get(`${book}.${ch}`) ?? 0);

const STEP_SHA = "5de0a47f35f0fc13dfe1430d104e5db8a4285f9c";
const STEP_BASE = `https://raw.githubusercontent.com/STEPBible/STEPBible-Data/${STEP_SHA}`;
const STEP_FILES = {
  tagnt1: "Translators Amalgamated OT+NT/TAGNT Mat-Jhn - Translators Amalgamated Greek NT - STEPBible.org CC-BY.txt",
  tagnt2: "Translators Amalgamated OT+NT/TAGNT Act-Rev - Translators Amalgamated Greek NT - STEPBible.org CC-BY.txt",
  tahot1: "Translators Amalgamated OT+NT/TAHOT Gen-Deu - Translators Amalgamated Hebrew OT - STEPBible.org CC BY.txt",
  tahot2: "Translators Amalgamated OT+NT/TAHOT Jos-Est - Translators Amalgamated Hebrew OT - STEPBible.org CC BY.txt",
  tahot3: "Translators Amalgamated OT+NT/TAHOT Job-Sng - Translators Amalgamated Hebrew OT - STEPBible.org CC BY.txt",
  tahot4: "Translators Amalgamated OT+NT/TAHOT Isa-Mal - Translators Amalgamated Hebrew OT - STEPBible.org CC BY.txt",
  tbesg: "Lexicons/TBESG - Translators Brief lexicon of Extended Strongs for Greek - STEPBible.org CC BY.txt",
  tbesh: "Lexicons/TBESH - Translators Brief lexicon of Extended Strongs for Hebrew - STEPBible.org CC BY.txt",
};
const COMMENTARIES = [
  ["jfb", "jamieson-fausset-brown"],
  ["henry", "matthew-henry"],
  ["clarke", "adam-clarke"],
];

// ── Downloads with recorded checksums ────────────────────────────────────────

const recorded = existsSync(SOURCES_FILE) ? JSON.parse(readFileSync(SOURCES_FILE, "utf8")) : {};
const seen = {};
const sha256 = (buf) => createHash("sha256").update(buf).digest("hex");

async function download(key, url, { binary = false } = {}) {
  const file = join(CACHE, key.replace(/[^\w.-]/g, "_"));
  let buf;
  if (existsSync(file)) buf = readFileSync(file);
  else {
    for (let attempt = 1; ; attempt++) {
      const res = await fetch(url);
      if (res.ok) { buf = Buffer.from(await res.arrayBuffer()); break; }
      if (res.status === 404) return null;
      if (attempt >= 4) throw new Error(`${res.status} ${url}`);
      await new Promise((r) => setTimeout(r, 1000 * attempt));
    }
    writeFileSync(file, buf);
  }
  seen[key] = sha256(buf);
  return binary ? buf : buf.toString("utf8");
}

async function pool(items, size, fn) {
  const queue = [...items];
  await Promise.all(Array.from({ length: size }, async () => { while (queue.length) await fn(queue.shift()); }));
}

// ── SQL output ──────────────────────────────────────────────────────────────

const q = (v) => (v === null || v === undefined ? "NULL" : typeof v === "number" ? String(v) : `'${String(v).replace(/'/g, "''")}'`);
function sqlInserts(table, columns, rows) {
  const out = [];
  let batch = [];
  let size = 0;
  const flush = () => {
    if (batch.length) out.push(`INSERT INTO ${table} (${columns.join(", ")}) VALUES\n${batch.join(",\n")};`);
    batch = []; size = 0;
  };
  for (const row of rows) {
    const values = `(${row.map(q).join(",")})`;
    const bytes = Buffer.byteLength(values); // D1 caps a statement at 100 KB; Greek and Hebrew take 2–3 bytes per letter
    if (size + bytes > 80_000) flush();
    batch.push(values); size += bytes;
  }
  flush();
  return out.join("\n");
}

const stripHtml = (s) => s
  .replace(/<ref='[^']*'>/g, "").replace(/<\/ref>/g, "")
  .replace(/<br\s*\/?>/gi, "\n").replace(/<[^>]+>/g, "")
  .replace(/&nbsp;/g, " ").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"')
  .replace(/[ \t]+/g, " ").replace(/\n\s*\n+/g, "\n").trim();

// ── 1. Cross-references ─────────────────────────────────────────────────────

function parseOsisRef(ref) {
  const m = /^(\w+)\.(\d+)\.(\d+)$/.exec(ref);
  if (!m || !fromOsis.has(m[1])) return null;
  return { book: fromOsis.get(m[1]), chapter: Number(m[2]), verse: Number(m[3]) };
}

async function crossReferences() {
  const zip = await download("openbible-cross-references.zip", "https://a.openbible.info/data/cross-references.zip", { binary: true });
  const text = execFileSync("unzip", ["-p", join(CACHE, "openbible-cross-references.zip"), "cross_references.txt"], { maxBuffer: 1 << 26 }).toString("utf8");
  void zip;
  const perVerse = new Map();
  let skipped = 0;
  for (const line of text.split("\n").slice(1)) {
    if (!line.trim()) continue;
    const [from, to, votes] = line.split("\t");
    const f = parseOsisRef(from);
    const [a, b] = to.split("-");
    const t1 = parseOsisRef(a);
    const t2 = b ? parseOsisRef(b) : t1;
    const v = Number(votes);
    if (!f || !t1 || !t2 || !inBounds(f.book, f.chapter, f.verse) || !inBounds(t1.book, t1.chapter, t1.verse) || v < 1) { skipped++; continue; }
    if (t2.book !== t1.book || t2.chapter !== t1.chapter || !inBounds(t2.book, t2.chapter, t2.verse)) { skipped++; continue; } // cross-chapter ranges: rare, skipped
    const target = t2.verse > t1.verse ? `${t1.book}.${t1.chapter}.${t1.verse}-${t2.verse}` : `${t1.book}.${t1.chapter}.${t1.verse}`;
    const key = `${f.book}.${f.chapter}.${f.verse}`;
    if (!perVerse.has(key)) perVerse.set(key, []);
    perVerse.get(key).push([target, v]);
  }
  const rows = [];
  for (const [key, list] of perVerse) {
    const [book, ch, v] = key.split(".");
    list.sort((x, y) => y[1] - x[1]).slice(0, 20).forEach(([target, votes], i) => rows.push([book, Number(ch), Number(v), i + 1, target, votes]));
  }
  console.log(`cross-references: ${rows.length} kept (top 20 per verse, votes ≥ 1) for ${perVerse.size} verses; ${skipped} skipped`);
  return rows;
}

// ── 2. Greek and Hebrew words + lexicon ─────────────────────────────────────

function parseLexicon(text, lang) {
  const rows = new Map();
  for (const line of text.split("\n")) {
    const cols = line.split("\t");
    if (!/^[GH]\d{4}/.test(cols[0] ?? "") || !cols[1]) continue;
    const id = cols[1].split(" ")[0].trim();
    if (!/^[GH]\d{4}[A-Za-z]?$/.test(id) || rows.has(id)) continue;
    const [, , , lemma, translit, pos, gloss, definition] = cols;
    rows.set(id, [id, lang, lemma?.trim() ?? "", translit?.trim() ?? "", pos?.trim() ?? "", gloss?.trim() ?? "",
      stripHtml(definition ?? "").slice(0, 600)]);
  }
  return rows;
}

const words = new Map(); // "BOOK.C.V" -> [lang, word[]]
let wordCount = 0, wordSkipped = 0;

function addWord(book, ch, v, lang, word) {
  if (!inBounds(book, ch, v)) { wordSkipped++; return; }
  const key = `${book}.${ch}.${v}`;
  if (!words.has(key)) words.set(key, [lang, []]);
  words.get(key)[1].push(word);
  wordCount++;
}

function parseTagnt(text) {
  for (const line of text.split("\n")) {
    const m = /^(\w{3})\.(\d+)\.(\d+)#\d+=(\w+)\t/.exec(line);
    if (!m) continue;
    const book = fromStep.get(m[1]);
    if (!book) throw new Error(`Unknown STEP book ${m[1]}`);
    const cols = line.split("\t");
    const [, greekCol, english, strongMorph, lemmaGloss, editions] = cols;
    const gm = /^(.*?)\s*\(([^)]*)\)\s*$/.exec(greekCol);
    const [strong, morph] = strongMorph.split("=");
    const editionsUsed = m[4].toUpperCase();
    // Words in neither the Nestle-Aland text (BSB, most modern Bibles) nor the Textus Receptus (KJV) are left out.
    if (!/[NK]/.test(editionsUsed)) continue;
    addWord(book, Number(m[2]), Number(m[3]), "grc", [
      (gm ? gm[1] : greekCol).replace(/[,.;·:]+$/, "").trim(), gm ? gm[2].trim() : "", english.trim(),
      strong.trim(), morph?.trim() ?? "", lemmaGloss.split("=")[0].trim(), editionsUsed.replace(/[^NK]/g, ""),
    ]);
    void editions;
  }
}

function parseTahot(text) {
  for (const line of text.split("\n")) {
    // "Gen.31.55(32.1)#01=L": English (KJV) numbering first, Hebrew numbering in brackets.
    const m = /^(\w{3})\.(\d+)\.(\d+)(?:\([\d.]+\))?#\d+=(\w+)\t/.exec(line);
    if (!m) continue;
    const book = fromStep.get(m[1]);
    if (!book) throw new Error(`Unknown STEP book ${m[1]}`);
    const cols = line.split("\t");
    const [, hebrew, translit, english, strongs, morphs] = cols;
    if (!/L/.test(m[4])) continue; // Leningrad Codex text (what translations follow); variants left out
    const parts = strongs.split("/");
    const main = Math.max(0, parts.findIndex((p) => p.includes("{")));
    // A trailing "\H9014" etc. marks punctuation (maqqef, sof pasuq) after the word.
    const strong = (parts[main] ?? "").replace(/[{}]/g, "").split("\\")[0].trim();
    const morph = ((morphs ?? "").split("/")[main] ?? "").split("\\")[0];
    addWord(book, Number(m[2]), Number(m[3]), "hbo", [
      hebrew.replace(/[\/\\]/g, "").trim(), translit.replace(/[\/\\]/g, "").trim(), english.replace(/[\/\\]/g, "").replace(/\s+/g, " ").trim(),
      strong, (morph.startsWith("H") ? morph : `H${morph}`).trim(), "", "",
    ]);
  }
}

// ── 3. Commentaries ─────────────────────────────────────────────────────────

const flatten = (content) => (Array.isArray(content) ? content : [content]).map((c) =>
  typeof c === "string" ? c : c && typeof c === "object" ? (c.text ?? c.heading ?? flatten(c.content ?? "")) : "").join("\n");
const cleanNote = (s) => s.replace(/\r/g, "").replace(/[ \t]+/g, " ").replace(/ *\n */g, "\n").replace(/\n{3,}/g, "\n\n").trim();

async function commentary(id, apiId) {
  const books = JSON.parse(await download(`${apiId}-books.json`, `https://bible.helloao.org/api/c/${apiId}/books.json`));
  const jobs = [];
  for (const b of books.books) {
    if (!IDS.includes(b.id)) continue;
    for (let ch = 1; ch <= b.numberOfChapters; ch++) jobs.push([b.id, ch]);
  }
  const rows = [];
  await pool(jobs, 8, async ([book, ch]) => {
    const raw = await download(`${apiId}-${book}-${ch}.json`, `https://bible.helloao.org/api/c/${apiId}/${book}/${ch}.json`);
    if (!raw) return;
    const chapter = JSON.parse(raw).chapter;
    const intro = cleanNote(flatten(chapter.introduction ?? ""));
    if (intro) rows.push([id, book, ch, 0, intro]);
    for (const item of chapter.content ?? []) {
      if (item.type !== "verse" || !inBounds(book, ch, item.number)) continue;
      const text = cleanNote(flatten(item.content));
      if (text) rows.push([id, book, ch, item.number, text]);
    }
  });
  // A few chapters have two entries for the same verse: keep both, in order, as one note.
  const merged = new Map();
  for (const row of rows) {
    const key = row.slice(0, 4).join("|");
    if (merged.has(key)) merged.get(key)[4] += `\n\n${row[4]}`;
    else merged.set(key, [...row]);
  }
  const notes = [...merged.values()].sort((a, b) => IDS.indexOf(a[1]) - IDS.indexOf(b[1]) || a[2] - b[2] || a[3] - b[3]);
  console.log(`commentary ${id}: ${notes.length} notes in ${jobs.length} chapters (${rows.length - notes.length} duplicates merged)`);
  return notes;
}

// ── Build ───────────────────────────────────────────────────────────────────

const xrefs = await crossReferences();

const step = {};
for (const [key, path] of Object.entries(STEP_FILES)) step[key] = await download(`step-${key}.txt`, `${STEP_BASE}/${encodeURI(path).replace(/\+/g, "%2B")}`);
const lexicon = new Map([...parseLexicon(step.tbesg, "grc"), ...parseLexicon(step.tbesh, "hbo")]);
parseTagnt(step.tagnt1); parseTagnt(step.tagnt2);
for (const k of ["tahot1", "tahot2", "tahot3", "tahot4"]) parseTahot(step[k]);
// Extended Strong's ids in the texts that the brief lexicons don't list fall back to the base number.
const wordRows = [...words].map(([key, [lang, list]]) => { const [b, c, v] = key.split("."); return [b, Number(c), Number(v), lang, JSON.stringify(list)]; });
wordRows.sort((a, b) => IDS.indexOf(a[0]) - IDS.indexOf(b[0]) || a[1] - b[1] || a[2] - b[2]);
const usedStrongs = new Set();
for (const [, [, list]] of words) for (const w of list) usedStrongs.add(w[3]);
const usedBases = new Set([...usedStrongs].map((s) => s.replace(/[A-Za-z]$/, "")));
const lexiconRows = [...lexicon.values()].filter(([id]) => usedStrongs.has(id) || usedBases.has(id));
const missingLex = [...usedStrongs].filter((s) => !lexicon.has(s) && !lexicon.has(s.replace(/[A-Za-z]$/, "")) && !/^H9\d{3}/.test(s));
console.log(`original words: ${wordCount} words in ${wordRows.length} verses (${wordSkipped} outside canonical bounds); lexicon ${lexiconRows.length} entries; ${missingLex.length} Strong's ids without an entry`);
const verseCount = [...bounds.values()].reduce((a, b) => a + b, 0);
if (wordRows.length < verseCount * 0.99) throw new Error(`Original-language coverage too low: ${wordRows.length}/${verseCount}`);

const notes = [];
for (const [id, apiId] of COMMENTARIES) notes.push(...(await commentary(id, apiId)));

// Source checksums: the same inputs must give the same seeds.
const combined = sha256(Buffer.from(Object.keys(seen).sort().map((k) => `${k}:${seen[k]}`).join("\n")));
if (Object.keys(recorded).length && !UPDATE) {
  const changed = Object.keys(seen).filter((k) => recorded.files?.[k] && recorded.files[k] !== seen[k]);
  if (changed.length) throw new Error(`Sources changed since the last build: ${changed.slice(0, 10).join(", ")}${changed.length > 10 ? "…" : ""}. Re-run with --update after reviewing.`);
}
writeFileSync(SOURCES_FILE, JSON.stringify({ stepbibleCommit: STEP_SHA, combined, files: Object.fromEntries(Object.keys(seen).sort().map((k) => [k, seen[k]])) }, null, 1) + "\n");

const files = {
  "cross_references.sql": sqlInserts("cross_references", ["book_id", "chapter", "verse", "rank", "target", "votes"], xrefs),
  "original_words.sql": sqlInserts("original_words", ["book_id", "chapter", "verse", "language", "words"], wordRows),
  "lexicon.sql": sqlInserts("lexicon", ["strong", "language", "lemma", "transliteration", "part_of_speech", "gloss", "definition"], lexiconRows),
  "commentary_notes.sql": sqlInserts("commentary_notes", ["source", "book_id", "chapter", "verse", "text"], notes),
};
// Each full seed replaces its table, so re-seeding is safe.
for (const [name, sql] of Object.entries(files)) writeFileSync(join(OUT, name), `DELETE FROM ${name.replace(".sql", "")};\n${sql}\n`);
for (const stale of readdirSync(OUT)) if (!files[stale]) console.warn(`stale file in seeds/study: ${stale}`);

// Small subset for tests (committed): a few chapters across testaments and genres.
const TEST = new Set(["GEN.1", "PSA.23", "JHN.3", "ROM.8", "HEB.1", "1CO.13"]);
const inTest = (b, c) => TEST.has(`${b}.${c}`);
const testWords = wordRows.filter((r) => inTest(r[0], r[1]));
const testStrongs = new Set(testWords.flatMap((r) => JSON.parse(r[4]).map((w) => w[3])));
writeFileSync(join(ROOT, "seeds/study-test.sql"), [
  "-- Generated by scripts/build-study.mjs: test subset (GEN 1, PSA 23, JHN 3, ROM 8, HEB 1, 1CO 13).",
  sqlInserts("cross_references", ["book_id", "chapter", "verse", "rank", "target", "votes"], xrefs.filter((r) => inTest(r[0], r[1]))),
  sqlInserts("original_words", ["book_id", "chapter", "verse", "language", "words"], testWords),
  sqlInserts("lexicon", ["strong", "language", "lemma", "transliteration", "part_of_speech", "gloss", "definition"],
    lexiconRows.filter(([id]) => testStrongs.has(id) || new Set([...testStrongs].map((s) => s.replace(/[A-Za-z]$/, ""))).has(id))),
  sqlInserts("commentary_notes", ["source", "book_id", "chapter", "verse", "text"], notes.filter((r) => inTest(r[1], r[2]))),
].join("\n") + "\n");

const meta = {
  built: "build-study.mjs", combinedSourceSha256: combined, stepbibleCommit: STEP_SHA,
  crossReferences: xrefs.length, originalWordVerses: wordRows.length, originalWords: wordCount, lexiconEntries: lexiconRows.length,
  lexiconMissing: missingLex.length,
  commentaryNotes: Object.fromEntries(COMMENTARIES.map(([id]) => [id, notes.filter((n) => n[0] === id).length])),
  sqlBytes: Object.fromEntries(Object.entries(files).map(([k, v]) => [k, v.length])),
};
writeFileSync(join(ROOT, "seeds/study-meta.json"), JSON.stringify(meta, null, 1) + "\n");
console.log(meta);
