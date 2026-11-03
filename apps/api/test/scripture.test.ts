import { env } from "cloudflare:workers";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { fetchRemoteChapter, versesFromContent } from "../src/apibible";
import { bookFromName } from "../src/scripture";
import { api, signInGuest } from "./helpers";

let token: string;
beforeEach(async () => ({ token } = await signInGuest()));
const get = async (path: string) => {
  const res = await api(path, { token });
  return { status: res.status, body: await res.json<any>() };
};

describe("catalog", () => {
  it("lists KJV, BSB and WEB as bundled offline translations", async () => {
    const { body } = await get("/scripture/translations");
    expect(body.translations.map((t: any) => [t.id, t.abbreviation, t.availability, t.license])).toEqual([
      ["kjv", "KJV", "bundled", "Public Domain"],
      ["bsb", "BSB", "bundled", "Public Domain"],
      ["web", "WEB", "bundled", "Public Domain"],
    ]);
    expect(body.translations[2].attribution).toMatch(/trademark of eBible\.org/);
  });

  it("lists 66 books with real verse counts for the reader rail", async () => {
    const { body } = await get("/scripture/books");
    expect(body.books).toHaveLength(66);
    const gen = body.books[0], psa = body.books.find((b: any) => b.id === "PSA");
    expect(gen).toMatchObject({ id: "GEN", name: "Genesis", testament: "OT", chapters: 50 });
    expect(gen.verseCounts[0]).toBe(31);
    expect(psa.verseCounts).toHaveLength(150);
    expect(psa.verseCounts[22]).toBe(6); // Psalm 23
    expect(psa.verseCounts[116]).toBe(2); // Psalm 117, the shortest chapter
    expect(psa.verseCounts[118]).toBe(176); // Psalm 119, the longest
    // Canonical upper bound across bundled translations: KJV's 31,102 + WEB's Romans 14:24–26.
    const total = body.books.reduce((n: number, b: any) => n + b.verseCounts.reduce((a: number, c: number) => a + c, 0), 0);
    expect(total).toBe(31105);
    for (const b of body.books) expect(b.verseCounts).toHaveLength(b.chapters);
  });
});

describe("chapters", () => {
  it("serves Genesis 1 with all 31 verses and continuation", async () => {
    const { status, body } = await get("/scripture/kjv/GEN/1");
    expect(status).toBe(200);
    expect(body.verses).toHaveLength(31);
    expect(body.verseCount).toBe(31);
    expect(body.verses[0]).toEqual({ verse: 1, text: "In the beginning God created the heaven and the earth." });
    expect(body.previous).toBeNull();
    expect(body.next).toEqual({ book: "GEN", chapter: 2 });
    expect(body.book).toEqual({ id: "GEN", name: "Genesis" });
  });

  it("serves short and long chapters, keeping LORD and without psalm headings", async () => {
    const ps23 = (await get("/scripture/kjv/PSA/23")).body;
    expect(ps23.verses.map((v: any) => v.verse)).toEqual([1, 2, 3, 4, 5, 6]);
    expect(ps23.verses[0].text).toBe("The LORD is my shepherd; I shall not want.");
    expect((await get("/scripture/kjv/PSA/117")).body.verses).toHaveLength(2);
    const ps119 = (await get("/scripture/kjv/psa/119")).body; // book id is case-insensitive
    expect(ps119.verses).toHaveLength(176);
    expect(ps119.verses[104].text).toBe("Thy word is a lamp unto my feet, and a light unto my path.");
  });

  it("continues across book boundaries and stops at the ends", async () => {
    expect((await get("/scripture/kjv/GEN/50")).body.next).toEqual({ book: "EXO", chapter: 1 });
    expect((await get("/scripture/kjv/EXO/1")).body.previous).toEqual({ book: "GEN", chapter: 50 });
    expect((await get("/scripture/kjv/MAL/4")).body.next).toEqual({ book: "MAT", chapter: 1 });
    const third = (await get("/scripture/kjv/3JN/1")).body;
    expect(third).toMatchObject({ previous: { book: "2JN", chapter: 1 }, next: { book: "JUD", chapter: 1 } });
    expect((await get("/scripture/kjv/REV/22")).body.next).toBeNull();
  });

  it("returns clear errors", async () => {
    expect((await get("/scripture/kjv/GEN/51")).status).toBe(404);
    expect((await get("/scripture/kjv/XYZ/1")).status).toBe(404);
    expect((await get("/scripture/niv/GEN/1")).status).toBe(404);
    expect((await get("/scripture/kjv/GEN/one")).status).toBe(400);
    // A real chapter whose text isn't loaded (the test seed has only a few chapters).
    expect((await get("/scripture/kjv/ROM/8")).body.error).toBe("scripture_not_loaded");
  });
});

describe("passages", () => {
  it("returns a verse range with a readable label", async () => {
    const { body } = await get("/scripture/kjv/passages/MAT.11.28-30");
    expect(body.label).toBe("Matthew 11:28–30");
    expect(body.verses.map((v: any) => v.verse)).toEqual([28, 29, 30]);
    expect(body.verses[0].text).toMatch(/^Come unto me, all ye that labour/);
    expect((await get("/scripture/kjv/passages/PSA.23.1")).body.label).toBe("Psalm 23:1");
  });

  it("rejects verses past the end of the chapter, here and when saving", async () => {
    expect((await get("/scripture/kjv/passages/PSA.23.7")).status).toBe(400);
    expect((await api("/me/saved/PSA.23.7", { method: "PUT", token })).status).toBe(400);
    expect((await api("/me/saved/PSA.23.6", { method: "PUT", token })).status).toBe(200);
  });
});

describe("search", () => {
  it("finds verses by words", async () => {
    const { body } = await get("/scripture/search?q=shepherd%20want");
    expect(body.results[0]).toEqual({ ref: "PSA.23.1", label: "Psalm 23:1", text: "The LORD is my shepherd; I shall not want." });
  });

  it("recognizes typed references", async () => {
    expect((await get("/scripture/search?q=John%203:16")).body.reference).toMatchObject({ ref: "JHN.3.16", label: "John 3:16" });
    expect((await get("/scripture/search?q=1%20cor%2013:4-7")).body.reference).toMatchObject({ ref: "1CO.13.4-7" });
    const psalm = (await get("/scripture/search?q=Psalm%2023")).body;
    expect(psalm.reference).toMatchObject({ ref: "PSA.23.1-6", label: "Psalm 23" });
    expect(psalm.results).toEqual([]); // no word-match noise for a reference
    expect((await get("/scripture/search?q=ps%20151")).body.reference).toBeNull();
  });

  it("handles odd input safely", async () => {
    expect((await get("/scripture/search?q=a")).status).toBe(400);
    expect((await get('/scripture/search?q=%22%20OR%20*%20NEAR(')).status).toBe(200); // FTS syntax is neutralized
    expect((await get("/scripture/search?q=zzzzqqq")).body.results).toEqual([]);
  });

  it("resolves book names and abbreviations", () => {
    expect(bookFromName("1 John")).toBe("1JN");
    expect(bookFromName("ps")).toBe("PSA");
    expect(bookFromName("Revelations")).toBe("REV");
    expect(bookFromName("phil")).toBe("PHP");
    expect(bookFromName("jo")).toBeNull(); // Joshua, Job, Joel, John, Jonah
  });
});

describe("offline BSB and WEB", () => {
  it("serves each translation's own text with the psalm title kept apart", async () => {
    const bsb = (await get("/scripture/bsb/PSA/23")).body;
    expect(bsb).toMatchObject({ title: "A Psalm of David.", verseCount: 6, translation: { id: "bsb", availability: "bundled" } });
    expect(bsb.verses[0]).toEqual({ verse: 1, text: "The LORD is my shepherd; I shall not want." });
    const web = (await get("/scripture/web/PSA/23")).body;
    expect(web.title).toBe("A Psalm by David.");
    expect(web.verses[0].text).toBe("The LORD is my shepherd; I shall lack nothing.");
    expect((await get("/scripture/kjv/PSA/23")).body.title).toBe("A Psalm of David.");
    expect((await get("/scripture/web/GEN/1")).body.verses[0].text).toBe("In the beginning, God created the heavens and the earth.");
  });

  it("keeps BSB's gaps where it omits verses absent from early manuscripts", async () => {
    const mat17 = (await get("/scripture/bsb/MAT/17")).body;
    expect(mat17.verseCount).toBe(26);
    expect(mat17.verses.map((v: any) => v.verse)).not.toContain(21);
    expect(mat17.verses.at(-1).verse).toBe(27);
    const missing = await get("/scripture/bsb/passages/MAT.17.21");
    expect(missing).toMatchObject({ status: 404, body: { error: "not_in_translation" } });
    expect(missing.body.message).toMatch(/Matthew 17:21 isn't in the BSB/);
    expect((await get("/scripture/kjv/passages/MAT.17.21")).status).toBe(200);
    expect((await get("/scripture/bsb/passages/MAT.17.20-22")).body.verses.map((v: any) => v.verse)).toEqual([20, 22]);
  });

  it("gives per-translation verse counts for the reader rail", async () => {
    const mat = (body: any) => body.books.find((b: any) => b.id === "MAT").verseCounts[16];
    expect(mat((await get("/scripture/books?translation=bsb")).body)).toBe(26);
    expect(mat((await get("/scripture/books?translation=web")).body)).toBe(27);
    expect(mat((await get("/scripture/books")).body)).toBe(27);
    expect((await get("/scripture/books?translation=nope")).status).toBe(404);
  });

  it("marks the words of Jesus for red-letter display", async () => {
    const check = async (path: string, verse: number, red: string) => {
      const v = (await get(path)).body.verses.find((x: any) => x.verse === verse);
      expect(v.wordsOfJesus.map(([s, l]: number[]) => v.text.slice(s, s + l))).toEqual([red]);
    };
    await check("/scripture/kjv/MAT/11", 28, "Come unto me, all ye that labour and are heavy laden, and I will give you rest.");
    await check("/scripture/web/MAT/11", 28, "“Come to me, all you who labor and are heavily burdened, and I will give you rest.");
    await check("/scripture/web/JHN/3", 16, "For God so loved the world, that he gave his only born Son, that whoever believes in him should not perish, but have eternal life.");
    const narration = (await get("/scripture/kjv/MAT/11")).body.verses.find((x: any) => x.verse === 1);
    expect(narration.wordsOfJesus).toBeUndefined();
  });

  it("searches the chosen offline translation", async () => {
    const bsb = (await get("/scripture/search?q=shepherd%20want&translation=bsb")).body;
    expect(bsb).toMatchObject({ translation: "bsb", results: [{ ref: "PSA.23.1", text: "The LORD is my shepherd; I shall not want." }] });
    expect((await get("/scripture/search?q=lack%20nothing&translation=web")).body.results[0].ref).toBe("PSA.23.1");
    expect((await get("/scripture/search?q=shepherd&translation=nope")).status).toBe(404);
  });
});

describe("online translations (API.Bible)", () => {
  afterEach(() => vi.restoreAllMocks());

  // Shape of API.Bible's content-type=json chapter content.
  const content = [
    { name: "para", type: "tag", attrs: { style: "p" }, items: [
      { name: "verse", type: "tag", attrs: { style: "v", number: "1" }, items: [{ type: "text", text: "1" }] },
      { type: "text", text: "The Lord is my ", attrs: { verseId: "PSA.23.1" } },
      { name: "char", type: "tag", attrs: { style: "nd" }, items: [{ type: "text", text: "shepherd", attrs: { verseId: "PSA.23.1" } }] },
      { type: "text", text: "; I have all that I need.", attrs: { verseId: "PSA.23.1" } },
      { name: "note", type: "tag", items: [{ type: "text", text: "footnote", attrs: { verseId: "PSA.23.1" } }] },
      { type: "text", text: "He lets me rest.", attrs: { verseId: "PSA.23.2" } },
    ] },
  ];

  it("assembles verse text and skips notes", () => {
    expect(versesFromContent(content, "PSA", 23)).toEqual([
      { verse: 1, text: "The Lord is my shepherd; I have all that I need." },
      { verse: 2, text: "He lets me rest." },
    ]);
  });

  it("fetches a chapter with the key, FUMS v3 and copyright", async () => {
    const spy = vi.spyOn(globalThis, "fetch").mockResolvedValue(
      Response.json({ data: { content, copyright: "© Example" }, meta: { fumsToken: "tok" } }),
    );
    const chapter = await fetchRemoteChapter({ ...env, API_BIBLE_KEY: "k" }, "bible-1", "PSA", 23);
    expect(chapter).toMatchObject({ copyright: "© Example", fumsToken: "tok" });
    expect(chapter.verses).toHaveLength(2);
    const [url, init] = spy.mock.calls[0] as [string, RequestInit];
    expect(url).toContain("/bibles/bible-1/chapters/PSA.23?");
    expect(url).toContain("fums-version=3");
    expect(new Headers(init.headers).get("api-key")).toBe("k");
  });

  it("explains when no provider is configured or the provider fails", async () => {
    await expect(fetchRemoteChapter({ ...env, API_BIBLE_KEY: "" }, "b", "PSA", 23)).rejects.toMatchObject({ status: 503 });
    vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response("busy", { status: 429 }));
    await expect(fetchRemoteChapter({ ...env, API_BIBLE_KEY: "k" }, "b", "PSA", 23)).rejects.toMatchObject({ status: 503 });
  });

  it("shows remote translations as needing a connection", async () => {
    await env.DB.prepare(
      `INSERT INTO translations (id, name, abbreviation, license, availability, provider, provider_bible_id, position)
       VALUES ('test', 'Test Version', 'TST', 'Licensed', 'remote', 'api_bible', 'bible-1', 2)`,
    ).run();
    const { body } = await get("/scripture/translations");
    expect(body.translations.find((t: any) => t.id === "test")).toMatchObject({ availability: "remote", online: false }); // no key in tests
    expect((await get("/scripture/test/PSA/23")).body.error).toBe("translation_unavailable");
    expect((await get("/scripture/search?q=shepherd&translation=test")).status).toBe(400); // search is offline-only
  });
});
