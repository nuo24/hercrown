// Drafts devotionals with AI for the team to review (content/devotionals.json). Each draft is grounded in the passage
// (BSB, from our seeds) and the public-domain commentaries on it (from the study-data cache). Drafts start unapproved:
// only entries with "approved": true and "approvedBy" are ever loaded into the app (scripts/build-devotionals.mjs).
//
//   node scripts/draft-devotionals.mjs            drafts every outline without an entry yet (needs OPENROUTER_API_KEY in .dev.vars
//                                                 and `npm run build:study` for the commentary cache)
import { existsSync, readFileSync, writeFileSync } from "node:fs";

const root = new URL("..", import.meta.url).pathname;
const out = `${root}../../content/devotionals.json`;
const key = /^OPENROUTER_API_KEY=(.+)$/m.exec(readFileSync(`${root}.dev.vars`, "utf8"))?.[1]?.trim();
if (!key) throw new Error("OPENROUTER_API_KEY missing from apps/api/.dev.vars");
const model = /"STUDY_MODEL": "([^"]+)"/.exec(readFileSync(`${root}wrangler.jsonc`, "utf8"))[1];

// What to write about: passage + tag (the outline is ours; the passage text and the commentary come from the sources).
const OUTLINES = [
  ["forget-not-his-benefits", "PSA.103.1-3", "Give Thanks"], ["come-and-rest", "MAT.11.28-30", "Rest"],
  ["peace-that-guards", "PHP.4.6-7", "Peace"], ["called-by-name", "ISA.43.1-2", "Identity"],
  ["new-every-morning", "LAM.3.22-23", "Hope"], ["lean-on-him", "PRO.3.5-6", "Trust"],
  ["a-very-present-help", "PSA.46.1-3", "Strength"], ["abide", "JHN.15.4-5", "Abide"],
  ["grace-is-enough", "2CO.12.9", "Grace"], ["nothing-can-separate", "ROM.8.38-39", "Love"],
  ["wonderfully-made", "PSA.139.13-14", "Identity"], ["do-not-worry", "MAT.6.25-27", "Anxiety"],
  ["the-better-part", "LUK.10.41-42", "Rest"], ["where-you-go", "RUT.1.16", "Faithfulness"],
  ["for-such-a-time", "EST.4.14", "Courage"], ["clothed-in-strength", "PRO.31.25-26", "Strength"],
  ["be-strong-and-courageous", "JOS.1.9", "Courage"], ["near-the-brokenhearted", "PSA.34.18", "Comfort"],
  ["renewed-strength", "ISA.40.29-31", "Hope"], ["ask-for-wisdom", "JAS.1.5", "Wisdom"],
  ["clothe-yourselves", "COL.3.12-13", "Relationships"], ["give-thanks-always", "1TH.5.16-18", "Give Thanks"],
  ["assurance-of-things-hoped-for", "HEB.11.1", "Faith"], ["what-the-lord-requires", "MIC.6.8", "Purpose"],
  ["the-lord-is-my-shepherd", "PSA.23.1-3", "Peace"], ["living-water", "JHN.4.13-14", "Longing"],
  ["blessed-is-she-who-believed", "LUK.1.45", "Faith"], ["go-in-peace", "MRK.5.34", "Healing"],
  ["the-god-who-sees", "GEN.16.13", "Seen"], ["he-delights-in-you", "ZEP.3.17", "Delight"],
];

const bsb = JSON.parse(readFileSync(`${root}seeds/bsb.json`, "utf8"));
const books = new Map(JSON.parse(readFileSync(`${root}src/books.json`, "utf8")).map((b) => [b[0], b[1]]));
function passage(ref) {
  const [, book, ch, start, end = start] = /^([1-3A-Z]{3})\.(\d+)\.(\d+)(?:-(\d+))?$/.exec(ref);
  const chapter = bsb.books.find((b) => b.id === book).chapters[Number(ch) - 1];
  const verses = chapter.verses.filter((v) => v.n >= Number(start) && v.n <= Number(end));
  const name = books.get(book) === "Psalms" ? "Psalm" : books.get(book);
  return { book, ch: Number(ch), start: Number(start), end: Number(end), label: `${name} ${ch}:${start}${end !== start ? `–${end}` : ""}`, text: verses.map((v) => v.t).join(" ") };
}
const SOURCES = { JFB: "jamieson-fausset-brown", Henry: "matthew-henry", Clarke: "adam-clarke" };
function notes(p) {
  const found = [];
  for (const [tag, id] of Object.entries(SOURCES)) {
    const file = `${root}.cache/study/${id}-${p.book}-${p.ch}.json`;
    if (!existsSync(file)) continue;
    const items = JSON.parse(readFileSync(file, "utf8")).chapter.content.filter((i) => i.type === "verse");
    const text = items.filter((i) => i.number >= p.start - (tag === "Henry" ? 30 : 0) && i.number <= p.end)
      .map((i) => (Array.isArray(i.content) ? i.content : [i.content]).filter((c) => typeof c === "string").join("\n")).join("\n").slice(0, 3500);
    if (text.trim()) found.push({ tag, text });
  }
  return found;
}

const SYSTEM = `You write short daily devotionals for women who are building a habit of reading the Bible.
Rules:
- Ground everything in the PASSAGE and the COMMENTARY notes given. Don't add facts, history or other Bible references that aren't in them.
- Never quote the passage in a different wording; you may refer to its phrases.
- Warm, honest, plain modern English. Speak to an adult woman's real life without stereotypes. No clichés, no emojis, no preaching at her.
- The commentaries are 150–300 years old: keep their insight, not their tone.
- 140–190 words in the body: about a one-minute read.
Reply with JSON only: {"title": "3–6 words", "body": "the devotional, paragraphs separated by \\n\\n", "reflection": "one question", "sources": ["tags of the notes you drew on"]}`;

const existing = existsSync(out) ? JSON.parse(readFileSync(out, "utf8")) : { about: "", devotionals: [] };
existing.about = "Devotional drafts for review. Only entries with \"approved\": true and \"approvedBy\" (who reviewed it) are loaded into the app by scripts/build-devotionals.mjs. Edit freely: the passage text always comes from our Bibles; 'ref' must stay a real passage. Drafted by AI from the passage and public-domain commentaries (see 'sources').";
const have = new Set(existing.devotionals.map((d) => d.id));
let cost = 0;
for (const [i, [id, ref, tag]] of OUTLINES.entries()) {
  if (have.has(id)) continue;
  const p = passage(ref);
  const n = notes(p);
  const user = `PASSAGE (BSB) ${p.label}: ${p.text}\nTHEME: ${tag}\n\nCOMMENTARY:\n${n.map((x) => `[${x.tag}] ${x.text}`).join("\n\n") || "(none)"}`;
  const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: { authorization: `Bearer ${key}`, "content-type": "application/json", "x-title": "Bible Scroll devotional drafts" },
    body: JSON.stringify({ model, messages: [{ role: "system", content: SYSTEM }, { role: "user", content: user }], temperature: 0.6,
      max_tokens: 700, reasoning: { enabled: false }, response_format: { type: "json_object" }, usage: { include: true } }),
  });
  const data = await res.json();
  cost += data.usage?.cost ?? 0;
  let draft;
  try { draft = JSON.parse(data.choices[0].message.content.replace(/^```json\s*|\s*```$/g, "")); } catch { console.error(`✗ ${id}: unusable reply`); continue; }
  const words = draft.body.split(/\s+/).length;
  existing.devotionals.push({
    id, position: i, title: draft.title, ref, tag, minutes: Math.max(1, Math.round(words / 200)), body: draft.body.trim(),
    reflection: draft.reflection.trim(), sources: (draft.sources ?? []).filter((s) => n.some((x) => x.tag === s)),
    origin: "ai-draft-reviewed", approved: false, approvedBy: "", reviewNotes: "",
  });
  console.log(`✓ ${id} (${p.label}) "${draft.title}" ${words} words`);
  writeFileSync(out, JSON.stringify(existing, null, 2) + "\n");
}
console.log(`\n${existing.devotionals.length} devotionals in content/devotionals.json · this run cost $${cost.toFixed(4)}`);
