import { env } from "cloudflare:workers";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { EventRow } from "../src/events";
import { greekParsing, hebrewParsing } from "../src/morph";
import { checkAnswer, excerpt } from "../src/study";
import { api, grantPremium, signInGuest } from "./helpers";

const EXPLAIN = `## Simple explanation
Jesus tells Nicodemus that God's love for the world is the reason He gave His Son [JFB]. Those who believe do not perish [Clarke].

## Key takeaway
God's love gave His Son so that whoever believes has eternal life.`;

/** An OpenRouter streaming response that sends `text` in small pieces, then usage. */
function openRouter(text: string, usage = { prompt_tokens: 1800, completion_tokens: 120, cost: 0.00042 }, model = "deepseek/deepseek-v4.1-flash") {
  const chunks = text.match(/[\s\S]{1,16}/g) ?? [];
  const body = [
    ": OPENROUTER PROCESSING\n\n",
    `data: ${JSON.stringify({ model, choices: [{ delta: { content: "", reasoning: "" } }] })}\n\n`,
    ...chunks.map((c) => `data: ${JSON.stringify({ model, choices: [{ delta: { content: c } }] })}\n\n`),
    `data: ${JSON.stringify({ model, choices: [{ delta: {}, finish_reason: "stop" }], usage })}\n\n`,
    "data: [DONE]\n\n",
  ].join("");
  return new Response(body, { headers: { "content-type": "text/event-stream" } });
}

let token: string;
let userId: string;
let calls: { url: string; body: any }[];
let reply: () => Response;
beforeEach(async () => {
  ({ token, userId } = await signInGuest());
  await grantPremium(userId);
  calls = [];
  reply = () => openRouter(EXPLAIN);
  vi.spyOn(globalThis, "fetch").mockImplementation(async (input, init) => {
    calls.push({ url: String(input), body: JSON.parse(String(init?.body)) });
    return reply();
  });
});
afterEach(() => vi.restoreAllMocks());

const get = (path: string, headers: Record<string, string> = {}) => api(path, { token, headers });
const clearAnswer = (ref: string, tool: string) => env.DB.prepare("DELETE FROM study_answers WHERE ref = ?1 AND tool = ?2").bind(ref, tool).run();

describe("access", () => {
  it("needs Plus, and one verse at a time", async () => {
    const free = await signInGuest();
    for (const tool of ["related", "original", "explain", "deeper"]) {
      const res = await api(`/study/JHN.3.16/${tool}`, { token: free.token });
      expect(res.status, tool).toBe(403);
      expect((await res.json<any>()).error).toBe("premium_required");
    }
    expect((await get("/study/JHN.3.16-17/explain")).status).toBe(400);
    expect((await get("/study/JHN.3.99/related")).status).toBe(400);
    expect((await get("/study/JHN.3.16/sermon")).status).toBe(404);
    expect(calls).toHaveLength(0);
  });
});

describe("related verses", () => {
  it("lists the best-voted cross-references with their text in the reader's translation", async () => {
    const res = await (await get("/study/JHN.3.16/related?translation=kjv")).json<any>();
    expect(res.source.license).toBe("CC BY");
    expect(res.related.length).toBeGreaterThan(0);
    expect(res.related[0]).toEqual({ ref: expect.any(String), label: expect.any(String), text: expect.any(String), votes: expect.any(Number) });
    const votes = res.related.map((r: any) => r.votes);
    expect(votes).toEqual([...votes].sort((a, b) => b - a));
  });
});

describe("original language", () => {
  it("gives each Greek word with its meaning and grammar", async () => {
    const res = await (await get("/study/JHN.3.16/original")).json<any>();
    expect(res.language).toBe("grc");
    const loved = res.words.find((w: any) => w.transliteration === "ēgapēsen");
    expect(loved).toMatchObject({ text: "ἠγάπησεν".normalize("NFC"), gloss: "loved", strong: "G0025", meaning: "to love",
      parsing: "Verb · aorist active indicative · 3rd person singular" });
    expect(res.source.license).toContain("CC BY");
  });

  it("gives each Hebrew word too", async () => {
    const res = await (await get("/study/GEN.1.1/original")).json<any>();
    expect(res.language).toBe("hbo");
    expect(res.words[1]).toMatchObject({ text: "בָּרָ֣א".normalize("NFC"), gloss: "he created", parsing: "Verb · qal perfect · 3rd person masculine singular" });
  });

  it("reads grammar codes", () => {
    expect(greekParsing("N-NSM-T")).toBe("Noun · nominative singular masculine");
    expect(greekParsing("V-PAP-NSM")).toBe("Verb · present active participle · nominative singular masculine");
    expect(greekParsing("CONJ")).toBe("Conjunction");
    expect(greekParsing("ZZZ")).toBeNull();
    expect(hebrewParsing("HNcmpa")).toBe("Noun · masculine plural absolute");
    expect(hebrewParsing("HNpm")).toBe("Proper noun · masculine");
    expect(hebrewParsing("HVhw3ms")).toBe("Verb · hiphil sequential imperfect · 3rd person masculine singular");
  });
});

describe("explain easier (AI)", () => {
  it("generates once from the commentaries, then serves the stored answer to everyone", async () => {
    const res = await get("/study/JHN.3.16/explain");
    expect(res.status).toBe(200);
    const answer = await res.json<any>();
    expect(answer).toMatchObject({
      ref: "JHN.3.16", label: "John 3:16", tool: "explain", cached: false,
      sections: [{ title: "Simple explanation", text: expect.stringContaining("[JFB]") }, { title: "Key takeaway", text: expect.any(String) }],
      notice: expect.stringContaining("separate from Scripture"),
    });
    expect(answer.sources.map((s: any) => s.tag).sort()).toEqual(["Clarke", "JFB"]);
    expect(answer.sources[0].license).toBe("Public domain");

    // What the model was given: the verse from our seeds, nearby verses and the commentaries; reasoning off; a fallback model.
    const request = calls[0]!.body;
    expect(calls[0]!.url).toBe("https://openrouter.ai/api/v1/chat/completions");
    expect(request).toMatchObject({ stream: true, model: "deepseek/deepseek-v4.1-flash",
      models: ["deepseek/deepseek-v4.1-flash", "deepseek/deepseek-v4-flash"], reasoning: { enabled: false }, usage: { include: true } });
    const prompt = request.messages[1].content as string;
    expect(prompt).toContain("VERSE: John 3:16");
    expect(prompt).toMatch(/BSB: For God so loved the world/);
    expect(prompt).toContain("[JFB] Jamieson, Fausset & Brown (1871)");
    expect(prompt).not.toContain("[Henry]"); // Henry's John 3 note is about Nicodemus and is cut off before v. 16
    expect(request.messages[0].content).toContain("Use only the verse");

    const other = await signInGuest();
    await grantPremium(other.userId);
    const again = await (await api("/study/JHN.3.16/explain", { token: other.token })).json<any>();
    expect(again).toMatchObject({ cached: true, sections: answer.sections });
    expect(calls).toHaveLength(1);
  });

  it("logs the cost of every call", async () => {
    await clearAnswer("JHN.3.17", "explain");
    const rows: EventRow[] = [];
    vi.spyOn(env.EVENTS, "send").mockImplementation(async (body) => (rows.push(body as EventRow), { metadata: {} } as QueueSendResponse));
    await get("/study/JHN.3.17/explain");
    const ledger = await env.DB.prepare("SELECT feature, units, cost_micros FROM usage_ledger WHERE user_id = ?1").bind(userId).first();
    expect(ledger).toEqual({ feature: "study_explain", units: 1920, cost_micros: 420 });
    await vi.waitFor(() => expect(rows.some((r) => r.event === "ai_call")).toBe(true));
    expect(JSON.parse(rows.find((r) => r.event === "ai_call")!.props)).toMatchObject({
      feature: "study_explain", model: "deepseek/deepseek-v4.1-flash", tokens_in: 1800, tokens_out: 120, cost_usd: 0.00042, ok: true,
    });
  });

  it("streams as Server-Sent Events", async () => {
    await clearAnswer("JHN.3.18", "explain");
    const res = await get("/study/JHN.3.18/explain", { accept: "text/event-stream" });
    expect(res.headers.get("content-type")).toContain("text/event-stream");
    const text = await res.text();
    const deltas = [...text.matchAll(/event: delta\ndata: (.*)/g)].map((m) => JSON.parse(m[1]!).text).join("");
    expect(deltas).toBe(EXPLAIN);
    const done = JSON.parse(/event: done\ndata: (.*)/.exec(text)![1]!);
    expect(done).toMatchObject({ ref: "JHN.3.18", cached: false, sections: [{ title: "Simple explanation" }, { title: "Key takeaway" }] });
  });

  it("refuses answers that break the format or cite a source they weren't given, and stores nothing", async () => {
    for (const bad of [
      "Here is a summary of John 3:19 without headings.",
      EXPLAIN.replace("[Clarke]", "[Wikipedia]"),
      EXPLAIN.replace("[Clarke]", "[Henry]"), // a real source, but not one it was given for this verse
      EXPLAIN.replace("## Key takeaway\n", "## Takeaway\n"),
    ]) {
      await clearAnswer("JHN.3.19", "explain");
      reply = () => openRouter(bad);
      const res = await get("/study/JHN.3.19/explain");
      expect(res.status, bad.slice(0, 30)).toBe(502);
      expect((await res.json<any>()).error).toBe("study_unavailable");
      expect(await env.DB.prepare("SELECT 1 FROM study_answers WHERE ref = 'JHN.3.19'").first()).toBeNull();
    }
    const streamed = await (await get("/study/JHN.3.19/explain", { accept: "text/event-stream" })).text();
    expect(streamed).toContain("event: reset");
    expect(streamed).toContain("event: error\ndata: {\"error\":\"study_unavailable\"");
  });

  it("retries once when the first answer is unusable", async () => {
    await clearAnswer("JHN.3.14", "explain");
    const answers = [EXPLAIN.replace("[Clarke]", "[Cross-ref]"), EXPLAIN];
    reply = () => openRouter(answers.shift()!);
    const text = await (await get("/study/JHN.3.14/explain", { accept: "text/event-stream" })).text();
    expect(text.indexOf("event: reset")).toBeLessThan(text.indexOf("event: done"));
    expect(JSON.parse(/event: done\ndata: (.*)/.exec(text)![1]!).sections[0].text).toContain("[Clarke]");
    expect(calls).toHaveLength(2);
    expect(calls[0]!.body.messages[1].content).toContain("ALLOWED TAGS: [JFB] [Clarke]");
  });

  it("says 'try again' when the model is down", async () => {
    reply = () => new Response("upstream down", { status: 502 });
    const res = await get("/study/JHN.3.20/explain");
    expect(res.status).toBe(503);
    expect((await res.json<any>()).error).toBe("study_unavailable");
  });

  it("limits new studies per day; stored ones are always free", async () => {
    await env.DB.batch(Array.from({ length: 60 }, () => env.DB.prepare(
      "INSERT INTO usage_ledger (id, user_id, feature, units, cost_micros, created_at) VALUES (?1, ?2, 'study_explain', 100, 1, ?3)",
    ).bind(crypto.randomUUID(), userId, Date.now())));
    const res = await get("/study/JHN.3.21/explain");
    expect(res.status).toBe(429);
    expect((await res.json<any>()).error).toBe("study_limit");
    expect((await get("/study/JHN.3.16/explain")).status).toBe(200); // stored in the first test
  });

  it("hides an answer after three people report it, then makes a new one", async () => {
    await get("/study/JHN.3.15/explain");
    for (let i = 0; i < 3; i++) {
      const u = await signInGuest();
      const res = await api("/study/JHN.3.15/explain/report", { method: "POST", token: u.token, body: JSON.stringify({ reason: "inaccurate", note: "Wrong speaker" }) });
      expect(res.status).toBe(200);
      if (i === 0) { // the same person reporting twice counts once
        await api("/study/JHN.3.15/explain/report", { method: "POST", token: u.token, body: JSON.stringify({ reason: "inaccurate" }) });
      }
    }
    const row = await env.DB.prepare("SELECT status, reports FROM study_answers WHERE ref = 'JHN.3.15' AND tool = 'explain'").first();
    expect(row).toEqual({ status: "hidden", reports: 3 });
    calls = [];
    expect((await (await get("/study/JHN.3.15/explain")).json<any>()).cached).toBe(false);
    expect(calls).toHaveLength(1);
    expect(await env.DB.prepare("SELECT status FROM study_answers WHERE ref = 'JHN.3.15' AND tool = 'explain'").first()).toEqual({ status: "published" });
    expect((await api("/study/JHN.3.15/explain/report", { method: "POST", token, body: JSON.stringify({ reason: "boring" }) })).status).toBe(400);
  });
});

describe("deeper study (AI)", () => {
  const DEEPER = `## Biblical meaning
The passage connects God’s love to the gift of his Son [JFB].

## Historical context
Jesus speaks with Nicodemus [JFB].

## Original language
"Agapaō" means to love [Lexicon].

## Life in biblical times
The sources don't describe the customs behind this verse.

## Theological significance
God’s love is shown through what he gives [JFB].

## Related passages
Romans 5:8 shows the same love [Cross-ref].

## Reflect
What does it mean to you that God gave?`;

  it("adds original words and cross-references to the sources", async () => {
    reply = () => openRouter(DEEPER);
    const answer = await (await get("/study/JHN.3.16/deeper")).json<any>();
    // "Life in biblical times" is left out when the sources don't describe any customs.
    expect(answer.sections.map((s: any) => s.title)).toEqual(["Biblical meaning", "Historical context", "Original language", "Theological significance", "Related passages", "Reflect"]);
    expect(answer.sources.map((s: any) => s.tag).sort()).toEqual(["Cross-ref", "JFB", "Lexicon"]);
    const prompt = calls[0]!.body.messages[1].content as string;
    expect(prompt).toContain("[Lexicon] Original words in this verse");
    expect(prompt.normalize("NFC")).toContain("ἠγάπησεν · ēgapēsen · loved · to love".normalize("NFC"));
    expect(prompt).toContain("[Cross-ref] Passages often read alongside this verse");
  });

  it("retries an uncited historical section with specific feedback and replaces the old format", async () => {
    await clearAnswer("JHN.3.16", "deeper");
    await env.DB.prepare(`INSERT INTO study_answers
      (ref, tool, version, status, sections, sources, model, prompt_tokens, completion_tokens, cost_micros, created_at)
      VALUES ('JHN.3.16', 'deeper', 2, 'published', '[]', '[]', 'old', 0, 0, 0, 1)`).run();
    const answers = [
      DEEPER.replace("Jesus speaks with Nicodemus [JFB].", "The sources don't describe the setting."),
      DEEPER,
    ];
    reply = () => openRouter(answers.shift()!);
    const res = await get("/study/JHN.3.16/deeper");
    expect(res.status).toBe(200);
    const answer = await res.json<any>();
    expect(answer.cached).toBe(false);
    expect(answer.sections).toContainEqual({ title: "Historical context", text: "Jesus speaks with Nicodemus [JFB]." });
    expect(calls).toHaveLength(2);
    expect(calls[1]!.body.messages.at(-1).content).toContain('"Historical context" needs a supplied source tag');
    const rows = await env.DB.prepare("SELECT version FROM study_answers WHERE ref = 'JHN.3.16' AND tool = 'deeper' ORDER BY version").all();
    expect(rows.results).toEqual([{ version: 2 }, { version: 4 }]);
  });

  it("accepts a passage citation in historical context and allows only the optional heading to be omitted", async () => {
    await clearAnswer("JHN.3.16", "deeper");
    reply = () => openRouter(DEEPER.replace("Jesus speaks with Nicodemus [JFB].", "The surrounding verses name Nicodemus [Passage].")
      .replace("## Life in biblical times\nThe sources don't describe the customs behind this verse.\n\n", ""));
    const res = await get("/study/JHN.3.16/deeper");
    expect(res.status).toBe(200);
    expect((await res.json<any>()).sources.map((source: any) => source.tag)).toContain("Passage");
    expect(calls).toHaveLength(1);
  });

  it("names unsupported citation tags when retrying an original-language section", async () => {
    await clearAnswer("JHN.3.16", "deeper");
    const answers = [DEEPER.replace("[Lexicon]", "[Strong] [Lexicon]"), DEEPER];
    reply = () => openRouter(answers.shift()!);
    const res = await get("/study/JHN.3.16/deeper");
    expect(res.status).toBe(200);
    expect(calls).toHaveLength(2);
    expect(calls[1]!.body.messages.at(-1).content).toContain('"Original language" used unsupported tags [Strong]');
    expect((await res.json<any>()).sources.map((source: any) => source.tag)).not.toContain("Strong");
  });

  it("does not cache an uncited answer when the retry still fails", async () => {
    await clearAnswer("JHN.3.16", "deeper");
    reply = () => openRouter(DEEPER.replace("Romans 5:8 shows the same love [Cross-ref].", "Romans 5:8 shows the same love."));
    expect((await get("/study/JHN.3.16/deeper")).status).toBe(502);
    expect(calls).toHaveLength(2);
    expect(await env.DB.prepare("SELECT 1 FROM study_answers WHERE ref = 'JHN.3.16' AND tool = 'deeper'").first()).toBeNull();
  });

});

describe("checks", () => {
  const ctx = { v: { book: "JHN", chapter: 3, verse: 16, ref: "JHN.3.16", label: "John 3:16" }, notes: [{ tag: "JFB" as const, text: "see Joh 1:14" }],
    related: [{ label: "Romans 5:8", text: "" }], words: [] };
  it("flags references the sources don't contain", () => {
    const c = checkAnswer(`## Simple explanation\nCompare Romans 5:8 and John 3:17 and Matthew 28:19 [JFB].\n\n## Key takeaway\nLove.`, "explain", ctx)!;
    expect(c.refsOutsideSources).toEqual(["Matthew 28:19"]);
  });
  it("finds the part of a long note about this verse, and drops long notes about something else", () => {
    const long = `${"Intro. ".repeat(500)} Ver. 16. For God so loved — the heart of it. ${"More. ".repeat(500)}`;
    expect(excerpt(long, 16, 400, 1)).toContain("Ver. 16. For God so loved");
    expect(excerpt(long, 21, 400, 1)).toBeNull();
    expect(excerpt(long, 3, 400, 1)).toMatch(/^Intro\./);
    expect(excerpt("Short note.", 21, 400, 1)).toBe("Short note.");
  });
});
