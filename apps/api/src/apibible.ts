// API.Bible client for licensed online translations. Text is fetched per request and not stored.
// FUMS v3: every response carries a fumsToken that the app must report when it shows the text
// (GET https://fums.api.bible/f3 with device/session ids). See docs.api.bible "Fair use".
import { HttpError } from "./http";

export interface RemoteChapter {
  verses: { verse: number; text: string }[];
  copyright: string | null;
  fumsToken: string | null;
}

interface ContentNode {
  type?: string;
  name?: string;
  text?: string;
  attrs?: { verseId?: string; style?: string };
  items?: ContentNode[];
}

const unavailable = (message: string) => new HttpError(503, "translation_unavailable", message);

/** Collects text per verse from API.Bible's JSON content tree. Notes are skipped. */
export function versesFromContent(content: ContentNode[], book: string, chapter: number) {
  const byVerse = new Map<number, string[]>();
  const prefix = `${book}.${chapter}.`;
  const walk = (nodes: ContentNode[]) => {
    for (const node of nodes) {
      if (node.name === "note") continue;
      const id = node.attrs?.verseId;
      if (node.type === "text" && node.text && id?.startsWith(prefix)) {
        const n = Number(id.slice(prefix.length));
        if (Number.isInteger(n)) (byVerse.get(n) ?? byVerse.set(n, []).get(n)!).push(node.text);
      }
      if (node.items) walk(node.items);
    }
  };
  walk(content);
  return [...byVerse.entries()]
    .sort(([a], [b]) => a - b)
    .map(([verse, parts]) => ({ verse, text: parts.join("").replace(/\s+/g, " ").trim() }))
    .filter((v) => v.text);
}

export async function fetchRemoteChapter(env: Env, bibleId: string, book: string, chapter: number): Promise<RemoteChapter> {
  if (!env.API_BIBLE_KEY) throw unavailable("This translation needs an online provider that isn't configured yet");
  const params = new URLSearchParams({
    "content-type": "json",
    "include-notes": "false",
    "include-titles": "false",
    "include-chapter-numbers": "false",
    "include-verse-numbers": "false",
    "include-verse-spans": "false",
    "fums-version": "3",
  });
  const url = `${env.API_BIBLE_BASE_URL}/bibles/${encodeURIComponent(bibleId)}/chapters/${book}.${chapter}?${params}`;

  let res: Response;
  try {
    res = await fetch(url, { headers: { "api-key": env.API_BIBLE_KEY }, signal: AbortSignal.timeout(8000) });
  } catch {
    throw unavailable("The translation provider didn't respond. Try again, or read in KJV offline.");
  }
  if (res.status === 404) throw new HttpError(404, "not_found", "This chapter isn't available in this translation");
  if (!res.ok) {
    console.error("API.Bible", res.status, await res.text().catch(() => ""));
    throw unavailable(res.status === 429 ? "The translation provider is busy. Try again shortly." : "The translation provider returned an error");
  }

  const body = await res.json<{ data?: { content?: ContentNode[]; copyright?: string }; meta?: { fumsToken?: string } }>();
  const verses = versesFromContent(body.data?.content ?? [], book, chapter);
  if (verses.length === 0) throw unavailable("The translation provider returned no text for this chapter");
  return { verses, copyright: body.data?.copyright ?? null, fumsToken: body.meta?.fumsToken ?? null };
}
