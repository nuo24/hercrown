// Checks the curated content (src/content/verses.json, content/devotionals.json): every reference is a single verse
// (or a short passage for devotionals) that exists in all three offline Bibles, themes are known, nothing is repeated.
// Part of `npm run check`.
import { readFileSync, existsSync } from "node:fs";

const root = new URL("..", import.meta.url).pathname;
const bibles = ["kjv", "bsb", "web"].map((id) => {
  const data = JSON.parse(readFileSync(`${root}seeds/${id}.json`, "utf8"));
  const has = new Set();
  for (const book of data.books) book.chapters.forEach((ch, i) => ch.verses.forEach((v) => has.add(`${book.id}.${i + 1}.${v.n}`)));
  return { id, has };
});
const problems = [];
const checkRef = (ref, where, { range = false } = {}) => {
  const m = /^([1-3A-Z]{3})\.(\d+)\.(\d+)(?:-(\d+))?$/.exec(ref);
  if (!m || (m[4] && !range)) return problems.push(`${where}: "${ref}" is not a ${range ? "verse or passage" : "single verse"} reference`);
  const [, book, ch, start, end = start] = m;
  for (let v = Number(start); v <= Number(end); v++) {
    for (const b of bibles) if (!b.has.has(`${book}.${ch}.${v}`)) problems.push(`${where}: ${book}.${ch}.${v} is missing from ${b.id.toUpperCase()}`);
  }
};

const verses = JSON.parse(readFileSync(`${root}src/content/verses.json`, "utf8"));
const seen = new Set();
for (const [i, card] of verses.cards.entries()) {
  checkRef(card.ref, `card ${i}`);
  if (!verses.themes.includes(card.theme)) problems.push(`card ${card.ref}: unknown theme ${card.theme}`);
  if (!card.reflection?.trim().endsWith("?") && !card.reflection?.trim().endsWith(".")) problems.push(`card ${card.ref}: reflection should be a sentence`);
  if (seen.has(card.ref)) problems.push(`card ${card.ref}: repeated`);
  seen.add(card.ref);
}
for (const ref of verses.verseOfTheDayExtra) {
  checkRef(ref, "verseOfTheDayExtra");
  if (seen.has(ref)) problems.push(`verseOfTheDayExtra ${ref}: already a card`);
  seen.add(ref);
}
for (const theme of verses.themes) if (!verses.cards.some((c) => c.theme === theme)) problems.push(`theme ${theme} has no cards`);

const devotionalsFile = `${root}../../content/devotionals.json`;
if (existsSync(devotionalsFile)) {
  const { devotionals } = JSON.parse(readFileSync(devotionalsFile, "utf8"));
  const ids = new Set();
  for (const d of devotionals) {
    checkRef(d.ref, `devotional ${d.id}`, { range: true });
    if (ids.has(d.id)) problems.push(`devotional ${d.id}: repeated id`);
    ids.add(d.id);
    for (const field of ["title", "tag", "body", "reflection"]) if (!d[field]?.trim()) problems.push(`devotional ${d.id}: ${field} is empty`);
    if (d.approved && !d.approvedBy?.trim()) problems.push(`devotional ${d.id}: approved without approvedBy`);
  }
}

if (problems.length) {
  console.error(`Content problems:\n- ${problems.join("\n- ")}`);
  process.exit(1);
}
console.log(`content ok: ${verses.cards.length} cards, ${seen.size} verse-of-the-day verses`);
