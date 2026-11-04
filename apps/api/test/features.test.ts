import { env } from "cloudflare:workers";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { VOTD_POOL, verseOfTheDayRef } from "../src/content";
import { markdownToHtml } from "../src/legal";
import { weeksInARow } from "../src/progress";
import { moveUserData } from "../src/users";
import { api, grantPremium, signInGuest } from "./helpers";

let token: string;
let userId: string;
beforeEach(async () => ({ token, userId } = await signInGuest()));
afterEach(() => vi.restoreAllMocks());

const call = (path: string, method = "GET", body?: unknown, t = token) =>
  api(path, { method, token: t, ...(body !== undefined ? { body: JSON.stringify(body) } : {}) });
const json = async (path: string, method = "GET", body?: unknown, t = token) => (await call(path, method, body, t)).json<any>();
const today = () => new Date().toISOString().slice(0, 10);

describe("reader preferences", () => {
  it("font size, words of Jesus in red, translation and widget verse", async () => {
    const res = await json("/me/preferences", "PATCH", { fontSize: "larger", wordsOfJesusInRed: false, translation: "bsb", widgetRef: "PSA.23.1" });
    expect(res).toMatchObject({ fontSize: "larger", wordsOfJesusInRed: false, translation: "bsb", widgetRef: "PSA.23.1" });
    expect((await json("/me")).preferences).toMatchObject({ fontSize: "larger", wordsOfJesusInRed: false, translation: "bsb" });
    expect((await call("/me/preferences", "PATCH", { fontSize: "huge" })).status).toBe(400);
    expect((await call("/me/preferences", "PATCH", { translation: "xyz" })).status).toBe(400);
    expect((await call("/me/preferences", "PATCH", { widgetRef: "PSA.23.1-3" })).status).toBe(400);
    expect((await json("/me/preferences", "PATCH", { widgetRef: null })).widgetRef).toBeNull();
  });

  it("remembers where she left off, ignoring an older save from another device", async () => {
    const now = Date.now();
    expect((await json("/me/position", "PUT", { ref: "JHN.3.16", at: now })).position.ref).toBe("JHN.3.16");
    expect((await json("/me/position", "PUT", { ref: "GEN.1.1", at: now - 60_000 })).position.ref).toBe("JHN.3.16");
    expect((await json("/me")).preferences.position).toEqual({ ref: "JHN.3.16", updatedAt: now });
  });
});

describe("notes", () => {
  it("auto-saves, lists newest first with the verse, and deletes when emptied", async () => {
    await call("/me/preferences", "PATCH", { translation: "kjv" });
    const saved = await json("/me/notes/JHN.3.16", "PUT", { text: "Wow. What love." });
    expect(saved).toMatchObject({ ref: "JHN.3.16", label: "John 3:16", text: "Wow. What love.", saved: true });
    await call("/me/notes/PSA.23.1", "PUT", { text: "My shepherd" });
    const list = await json("/me/notes");
    expect(list.notes.map((n: any) => n.ref)).toEqual(["PSA.23.1", "JHN.3.16"]);
    expect(list.notes[1].verse).toMatch(/^For God so loved the world/);
    expect((await json("/me/notes/JHN.3.16")).text).toBe("Wow. What love.");

    expect((await json("/me/notes/JHN.3.16", "PUT", { text: "old draft", at: Date.now() - 3_600_000 })).saved).toBe(false);
    expect((await json("/me/notes/JHN.3.16")).text).toBe("Wow. What love.");

    expect((await json("/me/notes/JHN.3.16", "PUT", { text: "   " })).deleted).toBe(true);
    expect((await call("/me/notes/JHN.3.16")).status).toBe(404);
    expect((await call("/me/notes/PSA.23.1", "DELETE")).status).toBe(204);
    expect((await call("/me/notes/PSA.23.1-2", "PUT", { text: "x" })).status).toBe(400);
    expect((await call("/me/notes/PSA.23.1", "PUT", { text: "x".repeat(10_001) })).status).toBe(400);
  });

  it("keeps the newer note when a guest signs in", async () => {
    const account = await signInGuest();
    await call("/me/notes/PSA.23.1", "PUT", { text: "account, older", at: Date.now() - 10_000 }, account.token);
    await call("/me/notes/PSA.23.1", "PUT", { text: "guest, newer" });
    await call("/me/notes/JHN.3.16", "PUT", { text: "guest only" });
    await moveUserData(env, userId, account.userId);
    const notes = (await json("/me/notes", "GET", undefined, account.token)).notes;
    expect(notes.map((n: any) => [n.ref, n.text]).sort()).toEqual([["JHN.3.16", "guest only"], ["PSA.23.1", "guest, newer"]]);
  });
});

describe("library", () => {
  it("counts saved verses, notes, saved studies and studied verses", async () => {
    await grantPremium(userId);
    await call("/me/saved/PSA.23.1", "PUT");
    await call("/me/notes/PSA.23.1", "PUT", { text: "note" });
    await call("/study/JHN.3.16/related");
    await call("/study/GEN.1.1/original");
    expect((await call("/me/studies/JHN.3.16/explain", "PUT")).status).toBe(200);
    expect((await call("/me/studies/JHN.3.16/original", "PUT")).status).toBe(400);
    expect(await json("/me/library")).toEqual({ savedVerses: 1, notes: 1, studies: 1, studied: 2, total: 3 });

    const studied = (await json("/me/studied")).studied;
    expect(studied.map((s: any) => [s.ref, s.tools])).toEqual([["GEN.1.1", ["original"]], ["JHN.3.16", ["related"]]]);
    expect((await json("/me/studies")).studies).toEqual([expect.objectContaining({ ref: "JHN.3.16", tool: "explain", label: "John 3:16" })]);
    expect((await call("/me/studies/JHN.3.16/explain", "DELETE")).status).toBe(204);
    expect((await json("/me/library")).studies).toBe(0);
  });
});

describe("Bible progress", () => {
  it("chapters read of 1,189, days opened vs read, this year, weeks in a row", async () => {
    const day = today();
    await call("/me/opened", "POST", { localDay: day });
    expect((await call("/me/chapters/JHN/3/complete", "POST", { localDay: day, timeZone: "UTC" })).status).toBe(200);
    await call("/me/chapters/JHN/3/complete", "POST", { localDay: day }); // twice = once
    await call("/me/chapters/PSA/23/complete", "POST", { localDay: day });
    const p = await json(`/me/progress?today=${day}`);
    expect(p.bible).toMatchObject({ chaptersRead: 2, totalChapters: 1189, percent: 0.2 });
    expect(p.bible.books.find((b: any) => b.id === "JHN")).toEqual({ id: "JHN", name: "John", testament: "NT", chapters: 21, chaptersRead: 1 });
    expect(p).toMatchObject({ daysOpened: { total: 1, current: 1 }, daysRead: { total: 1, current: 1 }, daysThisYear: 1, weeksInARow: 1, devotionalsRead: 0 });
    expect((await json(`/me/streak?today=${day}`)).streak.readToday).toBe(true); // finishing a chapter is reading

    expect((await json("/me/chapters?book=JHN")).completed).toEqual([{ chapter: 3, localDay: day }]);
    expect((await call("/me/chapters/JHN/3/complete", "DELETE")).status).toBe(204);
    expect((await json(`/me/progress?today=${day}`)).bible.chaptersRead).toBe(1);

    expect((await call("/me/chapters/JHN/22/complete", "POST", { localDay: day })).status).toBe(400);
    expect((await call("/me/opened", "POST", { localDay: "2999-01-01" })).status).toBe(400);
  });

  it("counts weeks in a row (Monday to Sunday)", () => {
    // 2026-11-02 is a Monday.
    expect(weeksInARow(["2026-11-03", "2026-10-28", "2026-10-20"], "2026-11-04")).toBe(3);
    expect(weeksInARow(["2026-10-28", "2026-10-20"], "2026-11-04")).toBe(2); // not yet this week: still counts
    expect(weeksInARow(["2026-10-20"], "2026-11-04")).toBe(0); // missed last week
    expect(weeksInARow([], "2026-11-04")).toBe(0);
  });
});

describe("verse of the day, random verse, widget", () => {
  const dayFor = (ref: string) => {
    for (let n = 0; n < 400; n++) {
      const day = new Date(Date.UTC(2027, 0, 1) + n * 86_400_000).toISOString().slice(0, 10);
      if (verseOfTheDayRef(day) === ref) return day;
    }
    throw new Error(`${ref} never comes up`);
  };

  it("is the same verse for everyone on a date, in her translation", async () => {
    const day = dayFor("PSA.23.1");
    const votd = await json(`/scripture/verse-of-the-day?date=${day}&translation=kjv`);
    expect(votd).toMatchObject({ date: day, ref: "PSA.23.1", label: "Psalm 23:1", text: "The LORD is my shepherd; I shall not want.",
      theme: "Peace", reflection: "Where could you make a little room for rest today?", saved: false });
    const other = await signInGuest();
    expect((await json(`/scripture/verse-of-the-day?date=${day}&translation=kjv`, "GET", undefined, other.token)).ref).toBe("PSA.23.1");
    expect((await json(`/scripture/verse-of-the-day?date=${day}&translation=bsb`)).text).toBe("The LORD is my shepherd; I shall not want.");
    expect(new Set(VOTD_POOL).size).toBe(VOTD_POOL.length);
    expect(VOTD_POOL.length).toBeGreaterThan(100);
  });

  it("gives a random curated verse, and the widget's verse", async () => {
    expect(VOTD_POOL).toContain((await json("/scripture/random")).ref);
    const widget = await json("/me/widget");
    expect(widget.source).toBe("verse_of_the_day");
    // The phone's day picks the same verse Home shows for that day.
    const onDay = await json("/me/widget?date=2026-03-01");
    expect(onDay).toMatchObject({ date: "2026-03-01", ref: (await json("/scripture/verse-of-the-day?date=2026-03-01")).ref });
    await call("/me/preferences", "PATCH", { widgetRef: "JHN.3.16" });
    expect(await json("/me/widget?translation=kjv")).toMatchObject({ source: "chosen", ref: "JHN.3.16", text: expect.stringMatching(/^For God so loved/) });
  });
});

describe("Discover", () => {
  it("filters by theme, with reflections kept apart from the verse", async () => {
    const res = await json("/discover?filter=Peace&translation=kjv");
    expect(res.filters.map((f: any) => f.id)).toEqual(["for-you", "Peace", "Purpose", "Faith", "Relationships", "Identity", "Anxiety", "Gratitude", "Hope", "Wisdom"]);
    expect(res.cards.length).toBeGreaterThan(0);
    expect(res.cards.every((c: any) => c.theme === "Peace" && c.text && c.reflection)).toBe(true);
    expect(res.cards[0]).toMatchObject({ ref: "PSA.23.1", text: "The LORD is my shepherd; I shall not want." });
    expect((await call("/discover?filter=Gossip")).status).toBe(400);
  });

  it("puts her topics first in For you", async () => {
    await call("/me/preferences", "PATCH", { topics: ["Anxiety"] });
    const cards = (await json("/discover?translation=kjv")).cards;
    expect(cards[0].theme).toBe("Anxiety");
    const themes = cards.map((c: any) => c.theme);
    expect(themes.lastIndexOf("Anxiety")).toBeLessThan(themes.findIndex((t: string) => t !== "Anxiety"));
  });

  it("shows her current plan's passages", async () => {
    expect((await json("/discover?filter=plan")).cards).toEqual([]);
    await grantPremium(userId);
    await call("/plans/peace/start", "POST");
    const res = await json("/discover?filter=plan&translation=kjv");
    expect(res.plan).toMatchObject({ id: "peace" });
    expect(res.filters[1]).toMatchObject({ id: "plan" });
    expect(res.cards.map((c: any) => c.ref)).toEqual(["MAT.11.28", "PSA.23.1", "PRO.3.5"]);
  });
});

describe("devotionals", () => {
  it("shows today's approved devotional with its passage, and counts it as read", async () => {
    await env.DB.prepare("DELETE FROM devotionals").run();
    expect((await call("/devotionals/today")).status).toBe(404);
    await env.DB.prepare(
      `INSERT INTO devotionals (id, position, title, ref, tag, minutes, body, reflection, origin, sources, approved_by, updated_at)
       VALUES ('forget-not', 0, 'Forget Not His Benefits', 'PSA.23.1-2', 'Give Thanks', 1, 'Some days gratitude…', 'What benefit will you remember?', 'written', '[]', 'Owner', 1)`,
    ).run();
    const d = await json("/devotionals/today?translation=kjv");
    expect(d).toMatchObject({ id: "forget-not", title: "Forget Not His Benefits", label: "Psalm 23:1–2", tag: "Give Thanks", minutes: 1, readAt: null });
    expect(d.passage).toMatch(/^The LORD is my shepherd; I shall not want\. He maketh me/);
    expect((await call("/me/devotionals/forget-not/read", "POST", { localDay: today() })).status).toBe(200);
    expect((await json("/devotionals/forget-not")).readAt).toEqual(expect.any(Number));
    expect((await json(`/me/progress?today=${today()}`)).devotionalsRead).toBe(1);
    expect((await call("/me/devotionals/nope/read", "POST", { localDay: today() })).status).toBe(404);
  });
});

describe("support", () => {
  it("stores the request with a reference and emails the team inbox", async () => {
    const sent: any[] = [];
    vi.spyOn(env.EMAIL, "send").mockImplementation(async (m: any) => (sent.push(m), { messageId: "m1" }));
    const res = await call("/me/support", "POST", { category: "Subscription & billing", message: "I was charged twice", contactEmail: "her@example.com" });
    expect(res.status).toBe(201);
    const { id } = await res.json<any>();
    expect(id).toMatch(/^HC-[2-9A-HJ-NP-Z]{8}$/);
    await vi.waitFor(() => expect(sent).toHaveLength(1));
    expect(sent[0]).toMatchObject({ to: "team@biblescroll.test", subject: `[${id}] Subscription & billing`, replyTo: "her@example.com",
      from: { email: "hello@biblescroll.test", name: "Her Crown" } });
    expect(sent[0].text).toContain("I was charged twice");
    await vi.waitFor(async () => expect(await env.DB.prepare("SELECT delivered_at FROM support_requests WHERE id = ?1").bind(id).first()).toEqual({ delivered_at: expect.any(Number) }));
    const list = await json("/me/support");
    expect(list.requests).toEqual([expect.objectContaining({ id, status: "received", category: "Subscription & billing" })]);
    expect(list.categories).toContain("Study tools");
  });

  it("validates and limits", async () => {
    vi.spyOn(env.EMAIL, "send").mockImplementation(async () => ({ messageId: "m" }));
    expect((await call("/me/support", "POST", { category: "Gossip", message: "hi" })).status).toBe(400);
    expect((await call("/me/support", "POST", { category: "Other", message: "" })).status).toBe(400);
    expect((await call("/me/support", "POST", { category: "Other", message: "hi", contactEmail: "not-an-email" })).status).toBe(400);
    for (let i = 0; i < 5; i++) expect((await call("/me/support", "POST", { category: "Other", message: `m${i}` })).status).toBe(201);
    expect((await call("/me/support", "POST", { category: "Other", message: "one more" })).status).toBe(429);
  });
});

describe("email sign-in", () => {
  it("emails a 6-digit code; signing in as a guest keeps her data", async () => {
    const sent: any[] = [];
    vi.spyOn(env.EMAIL, "send").mockImplementation(async (m: any) => (sent.push(m), { messageId: "m2" }));
    await call("/me/saved/PSA.23.1", "PUT");
    const email = `reader-${crypto.randomUUID().slice(0, 8)}@example.com`;
    const send = await call("/api/auth/email-otp/send-verification-otp", "POST", { email, type: "sign-in" });
    expect(send.status).toBe(200);
    expect(sent[0]).toMatchObject({ to: email, subject: expect.stringMatching(/^\d{6} is your Her Crown code$/) });
    const otp = /^(\d{6})/.exec(sent[0].subject)![1]!;

    expect((await call("/api/auth/sign-in/email-otp", "POST", { email, otp: otp === "000000" ? "111111" : "000000" })).status).toBe(400);
    const signIn = await call("/api/auth/sign-in/email-otp", "POST", { email, otp });
    expect(signIn.status).toBe(200);
    const accountToken = signIn.headers.get("set-auth-token")!;
    const me = await json("/me", "GET", undefined, accountToken);
    expect(me.user).toMatchObject({ isAnonymous: false, email });
    expect((await json("/me/saved", "GET", undefined, accountToken)).saved.map((s: any) => s.ref)).toEqual(["PSA.23.1"]);
  });
});

describe("legal pages", () => {
  it("serves privacy, terms, refunds, credits and support without signing in", async () => {
    for (const page of ["privacy", "terms", "refunds", "credits", "support"]) {
      const res = await api(`/legal/${page}`);
      expect(res.status, page).toBe(200);
      expect(res.headers.get("content-type")).toContain("text/html");
    }
    expect(await (await api("/legal/privacy")).text()).toContain("<h1>Privacy Policy</h1>");
    expect(await (await api("/legal/credits")).text()).toContain("CC BY 4.0");
    expect(await (await api("/legal/terms?format=md")).text()).toMatch(/^# Terms of Use/);
    expect((await api("/legal/cookies")).status).toBe(404);
  });

  it("renders the Markdown we use", () => {
    expect(markdownToHtml("# T\n\nA **b** _c_ [d](https://e.org)\n\n- one\n  - nested\n- two")).toBe(
      '<h1>T</h1>\n<p>A <strong>b</strong> <em>c</em> <a href="https://e.org">d</a></p>\n<ul><li>one<ul><li>nested</li></ul></li><li>two</li></ul>',
    );
    expect(markdownToHtml("<script>")).toBe("<p>&lt;script&gt;</p>");
  });
});

describe("account deletion", () => {
  it("removes notes, studies, progress, devices and support requests", async () => {
    vi.spyOn(env.EMAIL, "send").mockImplementation(async () => ({ messageId: "m" }));
    await call("/me/notes/PSA.23.1", "PUT", { text: "private" });
    await call("/me/chapters/PSA/23/complete", "POST", { localDay: today() });
    await call("/me/opened", "POST", { localDay: today() });
    await call("/me/support", "POST", { category: "Other", message: "hi" });
    expect((await call("/api/auth/delete-user", "POST", {})).status).toBe(200);
    for (const table of ["verse_notes", "chapter_completions", "app_open_days", "support_requests", "study_history", "preferences"]) {
      expect(await env.DB.prepare(`SELECT count(*) AS n FROM ${table} WHERE user_id = ?1`).bind(userId).first(), table).toEqual({ n: 0 });
    }
  });
});
