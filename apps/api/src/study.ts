// Plus study tools for one verse (decision 0006):
//   Related verses     OpenBible.info cross-references, best-voted first (data, no AI)
//   Original language  STEPBible Greek/Hebrew words + brief lexicon (data, no AI)
//   Explain easier     AI summary of the public-domain commentaries for this verse
//   Deeper study       AI: historical context, key original words, customs, related passages, a reflection question
// AI answers are grounded only in the sources we pass, cite them by tag, are generated once per verse and prompt
// version, stored, and served to everyone. Scripture text always comes from our verified seeds, never from the model.
import { type AiUsage, logAiCall, streamChat, type ChatMessage } from "./ai";
import { requirePremium } from "./billing";
import type { Tracker } from "./events";
import { recordStudied } from "./library";
import { badRequest, HttpError, readJson } from "./http";
import { parsing } from "./morph";
import type { SessionUser } from "./profile";
import { BOOKS, parseRef, resolveRef } from "./refs";
import { bookFromName, refLabel } from "./scripture";

export const PROMPT_VERSION = 1;
const DEEPER_PROMPT_VERSION = 4;
const versionFor = (tool: AiTool) => tool === "deeper" ? DEEPER_PROMPT_VERSION : PROMPT_VERSION;
export const TOOLS = ["explain", "deeper"] as const;
export type AiTool = (typeof TOOLS)[number];
const LOCAL = new Set(["kjv", "bsb", "web", "asv", "ylt", "darby", "webster", "msb", "rv1909"]);
const NOTICE = "Study commentary · separate from Scripture.";
const REPORTS_TO_HIDE = 3;

interface Verse { book: string; chapter: number; verse: number; ref: string; label: string }

async function verseFor(env: Env, input: string): Promise<Verse> {
  const ref = await resolveRef(env.DB, input);
  const p = parseRef(ref)!;
  if (p.start !== p.end) throw badRequest("Study one verse at a time");
  return { book: p.book, chapter: p.chapter, verse: p.start, ref, label: refLabel(p.book, p.chapter, p.start) };
}

// ── Related verses ──────────────────────────────────────────────────────────

async function passageText(env: Env, translation: string, target: string): Promise<string | null> {
  const p = parseRef(target);
  if (!p) return null;
  const rows = await env.DB.prepare(
    "SELECT text FROM verses WHERE translation_id = ?1 AND book_id = ?2 AND chapter = ?3 AND verse BETWEEN ?4 AND ?5 ORDER BY verse",
  ).bind(translation, p.book, p.chapter, p.start, p.end).all<{ text: string }>();
  return rows.results.length ? rows.results.map((r) => r.text).join(" ") : null;
}

async function crossReferences(env: Env, v: Verse, limit: number) {
  return (await env.DB.prepare(
    "SELECT target, votes FROM cross_references WHERE book_id = ?1 AND chapter = ?2 AND verse = ?3 ORDER BY rank LIMIT ?4",
  ).bind(v.book, v.chapter, v.verse, limit).all<{ target: string; votes: number }>()).results;
}

export async function getRelated(env: Env, user: SessionUser, refInput: string, url: URL) {
  await requirePremium(env, user.id);
  const v = await verseFor(env, refInput);
  const requested = url.searchParams.get("translation") ?? "kjv";
  const translation = LOCAL.has(requested) ? requested : "bsb";
  const related = [];
  for (const { target, votes } of await crossReferences(env, v, 12)) {
    const p = parseRef(target)!;
    const text = await passageText(env, translation, target);
    if (text) related.push({ ref: target, label: refLabel(p.book, p.chapter, p.start, p.end), text, votes });
  }
  await recordStudied(env, user.id, v.ref, "related");
  return Response.json({
    ref: v.ref, label: v.label, translation, related,
    source: { name: "OpenBible.info cross-references", license: "CC BY", url: "https://www.openbible.info/labs/cross-references/" },
  });
}

// ── Original language ───────────────────────────────────────────────────────

type WordRow = [text: string, transliteration: string, gloss: string, strong: string, morph: string, lemma: string, editions: string];
interface LexiconRow { strong: string; lemma: string; transliteration: string; part_of_speech: string; gloss: string; definition: string }

async function originalWords(env: Env, v: Verse) {
  const row = await env.DB.prepare("SELECT language, words FROM original_words WHERE book_id = ?1 AND chapter = ?2 AND verse = ?3")
    .bind(v.book, v.chapter, v.verse).first<{ language: "grc" | "hbo"; words: string }>();
  if (!row) return null;
  const words = JSON.parse(row.words) as WordRow[];
  const ids = [...new Set(words.flatMap((w) => [w[3], w[3].replace(/[A-Za-z]$/, "")]))];
  const lex = new Map<string, LexiconRow>();
  for (let i = 0; i < ids.length; i += 90) {
    const chunk = ids.slice(i, i + 90);
    const rows = await env.DB.prepare(`SELECT * FROM lexicon WHERE strong IN (${chunk.map((_, j) => `?${j + 1}`).join(",")})`)
      .bind(...chunk).all<LexiconRow>();
    for (const r of rows.results) lex.set(r.strong, r);
  }
  return {
    language: row.language,
    words: words.map(([text, transliteration, gloss, strong, morph, , editions]) => {
      const entry = lex.get(strong) ?? lex.get(strong.replace(/[A-Za-z]$/, ""));
      return {
        text: text.normalize("NFC"), transliteration, gloss, strong, morphology: morph, parsing: parsing(row.language, morph),
        lemma: entry?.lemma.normalize("NFC") ?? null, lemmaTransliteration: entry?.transliteration ?? null,
        meaning: entry?.gloss ?? null, definition: entry?.definition ?? null,
        // Greek only: N = in the Nestle-Aland text (most modern Bibles), K = in the Textus Receptus (KJV).
        editions: row.language === "grc" ? editions : undefined,
      };
    }),
  };
}

export async function getOriginal(env: Env, user: SessionUser, refInput: string) {
  await requirePremium(env, user.id);
  const v = await verseFor(env, refInput);
  const original = await originalWords(env, v);
  if (!original) throw new HttpError(404, "not_found", `No original-language data for ${v.label}`);
  await recordStudied(env, user.id, v.ref, "original");
  return Response.json({
    ref: v.ref, label: v.label, ...original,
    source: {
      name: original.language === "grc" ? "STEPBible Translators Amalgamated Greek NT (TAGNT) and brief lexicon (TBESG)"
        : "STEPBible Translators Amalgamated Hebrew OT (TAHOT) and brief lexicon (TBESH)",
      license: "CC BY 4.0, Tyndale House Cambridge", url: "https://github.com/STEPBible/STEPBible-Data",
    },
  });
}

// ── AI tools: context ───────────────────────────────────────────────────────

const SOURCE_TAGS = { JFB: "jfb", Henry: "henry", Clarke: "clarke" } as const;
const NOTE_LIMITS: Record<keyof typeof SOURCE_TAGS, { back: number; chars: number }> = {
  JFB: { back: 2, chars: 1800 }, Clarke: { back: 2, chars: 2200 }, Henry: { back: 200, chars: 3200 },
};

/**
 * The part of a long note that talks about this verse ("v. 16", "ver. 16", "Verse 16"). A long note that starts
 * several verses earlier and never mentions this one is about something else: null. (Some source notes are also cut off
 * at 32 KB, so the end of a long passage note can be missing.)
 */
export function excerpt(text: string, verse: number, chars: number, startsAt = verse): string | null {
  if (text.length <= chars) return text;
  const at = new RegExp(`\\b(?:v|ver|vv|verse|verses)\\.?\\s*${verse}\\b`, "i").exec(text)?.index;
  if (at === undefined && verse - startsAt > 3) return null;
  const start = Math.max(0, (at ?? 0) - Math.floor(chars / 4));
  return `${start > 0 ? "…" : ""}${text.slice(start, start + chars).trim()}…`;
}

interface Context {
  v: Verse;
  bsb: string;
  kjv: string | null;
  nearby: string;
  notes: { tag: keyof typeof SOURCE_TAGS; text: string }[];
  words: { text: string; transliteration: string; gloss: string; meaning: string | null; parsing: string | null }[];
  related: { label: string; text: string }[];
}

async function buildContext(env: Env, v: Verse, tool: AiTool): Promise<Context> {
  const bsb = await passageText(env, "bsb", v.ref) ?? await passageText(env, "kjv", v.ref);
  if (!bsb) throw new HttpError(404, "not_found", `${v.label} isn't in our Bibles`);
  const kjv = await passageText(env, "kjv", v.ref);
  const nearbyRows = await env.DB.prepare(
    "SELECT verse, text FROM verses WHERE translation_id = 'bsb' AND book_id = ?1 AND chapter = ?2 AND verse BETWEEN ?3 AND ?4 ORDER BY verse",
  ).bind(v.book, v.chapter, Math.max(1, v.verse - 3), v.verse + 2).all<{ verse: number; text: string }>();
  const notes: Context["notes"] = [];
  for (const [tag, source] of Object.entries(SOURCE_TAGS) as [keyof typeof SOURCE_TAGS, string][]) {
    const limit = NOTE_LIMITS[tag];
    const note = await env.DB.prepare(
      `SELECT verse, text FROM commentary_notes WHERE source = ?1 AND book_id = ?2 AND chapter = ?3 AND verse BETWEEN ?4 AND ?5
       ORDER BY verse DESC LIMIT 1`,
    ).bind(source, v.book, v.chapter, Math.max(1, v.verse - limit.back), v.verse).first<{ verse: number; text: string }>();
    const text = note && excerpt(note.text, v.verse, limit.chars, note.verse);
    if (text) notes.push({ tag, text });
  }
  const original = tool === "deeper" ? await originalWords(env, v) : null;
  const words = (original?.words ?? []).filter((w) => w.meaning && !/^[GH]9\d{3}/.test(w.strong)).slice(0, 25)
    .map((w) => ({ text: w.text, transliteration: w.transliteration, gloss: w.gloss, meaning: w.meaning, parsing: w.parsing }));
  const related = [];
  if (tool === "deeper") {
    for (const { target } of await crossReferences(env, v, 6)) {
      const p = parseRef(target)!;
      const text = await passageText(env, "bsb", target);
      if (text) related.push({ label: refLabel(p.book, p.chapter, p.start, p.end), text: text.slice(0, 400) });
    }
  }
  return {
    v, bsb, kjv, notes, words, related,
    nearby: nearbyRows.results.map((r) => `${r.verse} ${r.text}`).join("\n"),
  };
}

// ── AI tools: prompts ───────────────────────────────────────────────────────

const SYSTEM = `You write short Bible study notes for women reading Scripture on their phones.

Rules:
- Use only the verse, its nearby verses and the SOURCES given. Don't add facts, dates, names, numbers or claims that aren't in them. If the sources don't cover something, leave it out.
- After each claim, cite where it came from with the source's tag in square brackets, like [JFB]. Use only the tags listed as allowed for this verse.
- Don't quote the verse in another wording and don't invent Bible verses or references. Mention only references that appear in the sources.
- Where Christians read a passage differently, say so briefly and fairly instead of taking a side.
- Write plain, warm, modern English for an adult reader. No preaching, no clichés, no emojis. The commentaries are 150–300 years old; keep their insight, not their dated or harsh tone toward any group.
- Follow the output format exactly: the headings given, in that order, nothing before or after.`;

const OPTIONAL_CONTEXT = "The sources don't describe the customs behind this verse.";
const SOURCE_GAP = "The available sources do not give enough detail for this section.";

const FORMATS: Record<AiTool, { titles: string[]; instructions: string; maxTokens: number }> = {
  explain: {
    titles: ["Simple explanation", "Key takeaway"],
    instructions: `## Simple explanation
What the verse means in its context, in 60–110 words.

## Key takeaway
One sentence, at most 25 words.`,
    maxTokens: 500,
  },
  deeper: {
    titles: ["Biblical meaning", "Historical context", "Original language", "Life in biblical times", "Theological significance", "Related passages", "Reflect"],
    instructions: `## Biblical meaning
Explain the verse in its immediate literary context, tracing its argument or imagery in 80–120 words.

## Historical context
Explain who is speaking or writing, to whom, and what is happening, in 60–120 words. If authorship, audience or date aren't established in the material, say what the provided passage itself shows about the setting and cite [Passage]. Do not infer a date or author from silence.

## Original language
One to three important words from the [Lexicon] list: the original word, its transliteration, and what it means here. Cite the exact tag [Lexicon] for word meanings. Use square brackets only for the supplied source tags, never for Strong’s numbers, translation names, or editorial labels. At most 100 words.

## Life in biblical times
Customs or daily life behind the verse, in at most 90 words, only if the sources describe them. Otherwise write exactly: "${OPTIONAL_CONTEXT}"

## Theological significance
Explain one or two theological themes supported by the supplied passages or commentary in 80–120 words. Distinguish what the text says from interpretive conclusions.

## Related passages
One to three passages from the [Cross-ref] list and how each connects, in at most 90 words.

## Reflect
One question to think about, in one sentence.

Keep all headings in order; only Life in biblical times may be omitted. [Passage] refers to the supplied verse and nearby verses, not outside knowledge. Put a supplied source tag next to the claim it supports in each factual section; use [Lexicon] for Original language and [Cross-ref] for Related passages. No citation is required for Reflect. If a required factual section cannot be grounded, keep its heading and use exactly "${SOURCE_GAP}" as its entire body. Use the source-gap sentence only when the material is genuinely missing. In contested passages, describe the interpretation precisely without language implying any person's lesser worth.`,
    maxTokens: 1800,
  },
};

export function buildMessages(ctx: Context, tool: AiTool): ChatMessage[] {
  const sources = [
    ...ctx.notes.map((n) => `[${n.tag}] ${n.tag === "JFB" ? "Jamieson, Fausset & Brown (1871)" : n.tag === "Henry" ? "Matthew Henry (1706)" : "Adam Clarke (1831)"}:\n${n.text}`),
    ...(ctx.words.length ? [`[Lexicon] Original words in this verse (word · transliteration · gloss · dictionary meaning · grammar):\n${
      // The gloss uses brackets for supplied words (e.g. "teach [us]"). Reserve brackets for citations in the prompt.
      ctx.words.map((w) => `${w.text} · ${w.transliteration} · ${w.gloss.replace(/\[([^\[\]]+)\]/g, "($1)")} · ${w.meaning} · ${w.parsing ?? ""}`).join("\n")}`] : []),
    ...(ctx.related.length ? [`[Cross-ref] Passages often read alongside this verse (BSB):\n${ctx.related.map((r) => `${r.label}: ${r.text}`).join("\n")}`] : []),
  ];
  const tags = [...(tool === "deeper" ? ["Passage"] : []), ...ctx.notes.map((n) => n.tag), ...(ctx.words.length ? ["Lexicon"] : []), ...(ctx.related.length ? ["Cross-ref"] : [])];
  const user = `${tool === "deeper" ? "[Passage] " : ""}VERSE: ${ctx.v.label}
BSB: ${ctx.bsb}${ctx.kjv ? `\nKJV: ${ctx.kjv}` : ""}

${tool === "deeper" ? "[Passage] " : ""}NEARBY VERSES (BSB):
${ctx.nearby}

SOURCES:
${sources.length ? sources.join("\n\n") : "(none for this verse)"}

ALLOWED TAGS: ${tags.length ? tags.map((t) => `[${t}]`).join(" ") : "none (write without citations)"}

Write the notes in this format:
${FORMATS[tool].instructions}`;
  return [{ role: "system", content: SYSTEM }, { role: "user", content: user }];
}

// ── AI tools: checking the answer ───────────────────────────────────────────

export interface Checked {
  sections: { title: string; text: string }[];
  cited: string[];
  refsOutsideSources: string[];
}

const ALLOWED_TAGS = new Set<string>([...Object.keys(SOURCE_TAGS), "Lexicon", "Cross-ref", "Passage"]);

const citationTags = (text: string) => [...text.matchAll(/\[([A-Za-z-]+)\]/g)].map((m) => m[1]!);

export function checkAnswer(text: string, tool: AiTool, ctx: Pick<Context, "notes" | "related" | "v" | "words">): Checked | null {
  const result = validateAnswer(text, tool, ctx);
  return typeof result === "string" ? null : result;
}

/** Returns actionable feedback for the one retry. Never use unchecked text as a saved answer. */
function validateAnswer(text: string, tool: AiTool, ctx: Pick<Context, "notes" | "related" | "v" | "words">): Checked | string {
  const fullTitles = FORMATS[tool].titles;
  const parts = text.trim().split(/^##[ \t]+/m);
  const titles = tool === "deeper" && parts.length === fullTitles.length
    ? fullTitles.filter((title) => title !== "Life in biblical times")
    : fullTitles;
  if (parts[0] !== "" || parts.length !== titles.length + 1) {
    return `Use exactly these headings, in order: ${titles.join(", ")}.`;
  }
  const available = new Set<string>([...(tool === "deeper" ? ["Passage"] : []), ...ctx.notes.map((n) => n.tag), ...(ctx.words.length ? ["Lexicon"] : []), ...(ctx.related.length ? ["Cross-ref"] : [])]);
  const sections: Checked["sections"] = [];
  const tags: string[] = [];
  const problems: string[] = [];
  for (const [i, part] of parts.slice(1).entries()) {
    const expected = titles[i]!;
    const newline = part.indexOf("\n");
    const title = (newline < 0 ? part : part.slice(0, newline)).trim();
    const body = newline < 0 ? "" : part.slice(newline + 1).trim();
    if (title.toLowerCase() !== expected.toLowerCase() || !body) {
      problems.push(`Section ${i + 1} must be "${expected}" with a nonempty body.`);
      continue;
    }
    if (tool === "deeper" && expected === "Life in biblical times" && body.replaceAll("’", "'") === OPTIONAL_CONTEXT) continue;
    const cited = citationTags(body);
    const unknown = [...new Set(cited.filter((tag) => !ALLOWED_TAGS.has(tag) || !available.has(tag)))];
    if (unknown.length) {
      problems.push(`"${expected}" used unsupported tags ${unknown.map((tag) => `[${tag}]`).join(", ")}. Use only ${[...available].map((tag) => `[${tag}]`).join(", ") || "the supplied material without tags"}.`);
    }
    if (tool === "deeper" && expected !== "Reflect" && body !== SOURCE_GAP) {
      const required = expected === "Original language" ? "Lexicon" : expected === "Related passages" ? "Cross-ref" : undefined;
      if (required ? !cited.includes(required) : cited.length === 0) {
        problems.push(`"${expected}" needs ${required ? `[${required}]` : "a supplied source tag"} or the exact source-gap sentence if unsupported.`);
      }
    }
    if (tool === "deeper" && body === SOURCE_GAP) {
      const missingSpecificSource = (expected === "Original language" && !available.has("Lexicon")) ||
        (expected === "Related passages" && !available.has("Cross-ref"));
      if (!missingSpecificSource) {
        problems.push(expected === "Life in biblical times"
          ? `Use the exact customs fallback for "${expected}" when unsupported.`
          : `Use the supplied material in "${expected}". For literary or historical context, describe only what the text itself shows and cite [Passage].`);
      }
    }
    tags.push(...cited);
    sections.push({ title: expected, text: body });
  }
  if (problems.length) return problems.join(" ");
  // References the answer mentions that aren't the verse's chapter, a cross-reference, or in a source note: kept, flagged for review.
  const known = [ctx.v.label, ...ctx.related.map((r) => r.label)].join(" ");
  const notesText = ctx.notes.map((n) => n.text).join(" ");
  const refsOutsideSources = [...text.matchAll(/\b((?:[1-3]\s)?[A-Z][a-z]+)\s(\d{1,3}):(\d{1,3})/g)]
    .filter(([, name, ch]) => {
      const book = bookFromName(name!);
      if (!book) return false;
      if (book === ctx.v.book && Number(ch) === ctx.v.chapter) return false;
      const bookName = BOOKS.find((b) => b[0] === book)?.[1] ?? name!;
      return !known.includes(`${bookName === "Psalms" ? "Psalm" : bookName} ${ch}:`) && !notesText.includes(`${ch}:`);
    })
    .map((m) => m[0]);
  return { sections, cited: [...new Set(tags)], refsOutsideSources };
}

// ── AI tools: endpoint ──────────────────────────────────────────────────────

class StudyValidationError extends HttpError {
  constructor(readonly feedback: string) {
    super(502, "study_unavailable", "We couldn't prepare this study. Please try again.");
  }
}

interface AnswerRow { sections: string; sources: string; model: string; created_at: number; status: string }

const SOURCE_INFO: Record<string, { name: string; author: string; published: string; license: string; url: string }> = {
  Passage: { name: "This passage and nearby Scripture", author: "Bundled Bible text", published: "", license: "Public domain", url: "https://berean.bible/" },
  JFB: { name: "Commentary Critical and Explanatory on the Whole Bible", author: "Jamieson, Fausset & Brown", published: "1871", license: "Public domain", url: "https://bible.helloao.org" },
  Henry: { name: "Commentary on the Whole Bible", author: "Matthew Henry", published: "1706", license: "Public domain", url: "https://bible.helloao.org" },
  Clarke: { name: "Commentary on the Bible", author: "Adam Clarke", published: "1831", license: "Public domain", url: "https://bible.helloao.org" },
  Lexicon: { name: "STEPBible brief lexicons", author: "Tyndale House Cambridge", published: "2024", license: "CC BY 4.0", url: "https://github.com/STEPBible/STEPBible-Data" },
  "Cross-ref": { name: "OpenBible.info cross-references", author: "OpenBible.info", published: "2026", license: "CC BY", url: "https://www.openbible.info/labs/cross-references/" },
};

function answerJson(v: Verse, tool: AiTool, sections: { title: string; text: string }[], cited: string[], createdAt: number, cached: boolean) {
  return {
    ref: v.ref, label: v.label, tool, sections, cached, generatedAt: createdAt, notice: NOTICE,
    sources: cited.map((tag) => ({ tag, ...SOURCE_INFO[tag]! })),
  };
}

async function dailyGenerations(env: Env, userId: string) {
  const row = await env.DB.prepare(
    "SELECT count(*) AS n FROM usage_ledger WHERE user_id = ?1 AND feature LIKE 'study_%' AND units > 0 AND created_at > ?2",
  ).bind(userId, Date.now() - 86_400_000).first<{ n: number }>();
  return row?.n ?? 0;
}

/**
 * GET /study/{ref}/explain | /deeper. A stored answer comes back as JSON at once. Otherwise it's generated: as
 * Server-Sent Events when the request accepts `text/event-stream` (events `delta` {text}; `reset` {} = discard the text so
 * far, a retry follows; then `done` {answer} or `error` {error, message}), else as JSON when complete.
 */
export async function getAiStudy(request: Request, env: Env, ctx: ExecutionContext, user: SessionUser, refInput: string,
  tool: AiTool, tracker: Tracker) {
  await requirePremium(env, user.id);
  const v = await verseFor(env, refInput);
  const stored = await env.DB.prepare(
    "SELECT sections, sources, model, created_at, status FROM study_answers WHERE ref = ?1 AND tool = ?2 AND version = ?3",
  ).bind(v.ref, tool, versionFor(tool)).first<AnswerRow>();
  if (stored?.status === "published") {
    tracker.track("study_viewed", { tool, cached: true });
    await recordStudied(env, user.id, v.ref, tool);
    return Response.json(answerJson(v, tool, JSON.parse(stored.sections), JSON.parse(stored.sources), stored.created_at, true));
  }

  const limit = Number(env.STUDY_DAILY_LIMIT) || 60;
  if ((await dailyGenerations(env, user.id)) >= limit) {
    throw new HttpError(429, "study_limit", "You've opened a lot of new studies today. Saved ones still work; new ones are back tomorrow.");
  }
  const context = await buildContext(env, v, tool);
  const messages = buildMessages(context, tool);
  const feature = `study_${tool}`;

  // One retry when the model breaks the format or cites a source it wasn't given (the stream sends `reset` first).
  const generate = async (onDelta: (text: string) => void, onReset: () => void) => {
    try {
      return await attempt(onDelta);
    } catch (err) {
      if (!(err instanceof HttpError) || err.status !== 502) throw err;
      onReset();
      const feedback = err instanceof StudyValidationError ? err.feedback : undefined;
      return attempt(onDelta, feedback);
    }
  };

  const attempt = async (onDelta: (text: string) => void, feedback?: string) => {
    let text = "";
    let usage: AiUsage | null = null;
    try {
      const retryMessages = feedback
        ? [...messages, { role: "user" as const, content: `Rewrite the full answer from the original sources. Fix these validation problems: ${feedback}` }]
        : messages;
      const stream = streamChat(env, retryMessages, { maxTokens: FORMATS[tool].maxTokens });
      for (;;) {
        const next = await stream.next();
        if (next.done) { usage = next.value; break; }
        text += next.value;
        onDelta(next.value);
      }
    } catch (err) {
      await logAiCall(env, tracker, user.id, feature, usage, false);
      throw err;
    }
    const checked = validateAnswer(text, tool, context);
    await logAiCall(env, tracker, user.id, feature, usage, typeof checked !== "string");
    if (typeof checked === "string") {
      console.warn(`study: unusable ${tool} answer for ${v.ref}: ${checked}`);
      throw new StudyValidationError(checked);
    }
    if (checked.refsOutsideSources.length) console.warn(`study: ${v.ref} ${tool} mentions refs outside its sources`, checked.refsOutsideSources);
    const t = Date.now();
    await env.DB.prepare(
      `INSERT INTO study_answers (ref, tool, version, status, sections, sources, model, prompt_tokens, completion_tokens, cost_micros, created_at)
       VALUES (?1, ?2, ?3, 'published', ?4, ?5, ?6, ?7, ?8, ?9, ?10)
       ON CONFLICT (ref, tool, version) DO UPDATE SET status = 'published', sections = excluded.sections, sources = excluded.sources,
         model = excluded.model, prompt_tokens = excluded.prompt_tokens, completion_tokens = excluded.completion_tokens,
         cost_micros = excluded.cost_micros, reports = 0, created_at = excluded.created_at
       WHERE study_answers.status = 'hidden'`,
    ).bind(v.ref, tool, versionFor(tool), JSON.stringify(checked.sections), JSON.stringify(checked.cited), usage!.model,
      usage!.promptTokens, usage!.completionTokens, Math.round(usage!.costUsd * 1_000_000), t).run();
    tracker.track("study_viewed", { tool, cached: false });
    await recordStudied(env, user.id, v.ref, tool);
    return answerJson(v, tool, checked.sections, checked.cited, t, false);
  };

  if (!(request.headers.get("accept") ?? "").includes("text/event-stream")) return Response.json(await generate(() => {}, () => {}));

  const { readable, writable } = new TransformStream<Uint8Array, Uint8Array>();
  const writer = writable.getWriter();
  const encoder = new TextEncoder();
  let open = true;
  const send = (event: string, data: unknown) => {
    if (!open) return;
    writer.write(encoder.encode(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`)).catch(() => { open = false; }); // reader left: keep generating
  };
  ctx.waitUntil((async () => {
    try {
      send("done", await generate((text) => send("delta", { text }), () => send("reset", {})));
    } catch (err) {
      const e = err instanceof HttpError ? err : new HttpError(503, "study_unavailable", "Study tools are busy right now. Try again in a moment.");
      if (!(err instanceof HttpError)) console.error("study: generation failed", err);
      send("error", { error: e.code, message: e.message });
    } finally {
      if (open) await writer.close().catch(() => {});
    }
  })());
  return new Response(readable, { headers: { "content-type": "text/event-stream; charset=utf-8", "cache-control": "no-store" } });
}

/** POST /study/{ref}/{tool}/report { reason, note? }: three reports from different people hide the answer until it's regenerated. */
export async function reportStudy(request: Request, env: Env, user: SessionUser, refInput: string, tool: AiTool, tracker: Tracker) {
  const v = await verseFor(env, refInput);
  const body = await readJson(request);
  const reason = body.reason;
  if (reason !== "inaccurate" && reason !== "unclear" && reason !== "offensive" && reason !== "other") {
    throw badRequest("reason must be inaccurate, unclear, offensive or other");
  }
  const note = typeof body.note === "string" ? body.note.trim().slice(0, 1000) || null : null;
  const inserted = await env.DB.prepare(
    `INSERT OR IGNORE INTO study_reports (id, ref, tool, version, user_id, reason, note, created_at)
     VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)`,
  ).bind(crypto.randomUUID(), v.ref, tool, versionFor(tool), user.id, reason, note, Date.now()).run();
  if (inserted.meta.changes > 0) {
    await env.DB.prepare(
      `UPDATE study_answers SET reports = reports + 1, status = CASE WHEN reports + 1 >= ?4 THEN 'hidden' ELSE status END
       WHERE ref = ?1 AND tool = ?2 AND version = ?3`,
    ).bind(v.ref, tool, versionFor(tool), REPORTS_TO_HIDE).run();
    tracker.track("study_reported", { tool, reason });
  }
  return Response.json({ reported: true });
}
