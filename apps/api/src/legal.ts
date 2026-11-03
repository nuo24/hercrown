// Public legal pages (App Store needs privacy policy and terms URLs): GET /legal/{privacy|terms|refunds|credits}.
// Written in Markdown (src/legal/*.md), served as simple HTML. `?format=md` returns the Markdown for in-app rendering.
import credits from "./legal/credits.md";
import privacy from "./legal/privacy.md";
import refunds from "./legal/refunds.md";
import terms from "./legal/terms.md";
import { escapeHtml } from "./email";

export const LEGAL_PAGES: Record<string, string> = { privacy, terms, refunds, credits };

/** Minimal Markdown → HTML: headings, paragraphs, two-level lists, bold, italics, links. Input is our own files only. */
export function markdownToHtml(md: string): string {
  const inline = (s: string) => escapeHtml(s)
    .replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")
    .replace(/(^|[^\w*])_(.+?)_(?=[^\w]|$)/g, "$1<em>$2</em>")
    .replace(/\*(.+?)\*/g, "<em>$1</em>")
    .replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+)\)/g, '<a href="$2">$1</a>');
  const out: string[] = [];
  let items: { text: string; children: string[] }[] = [];
  const flush = () => {
    if (!items.length) return;
    out.push(`<ul>${items.map((i) => `<li>${i.text}${i.children.length ? `<ul>${i.children.map((c) => `<li>${c}</li>`).join("")}</ul>` : ""}</li>`).join("")}</ul>`);
    items = [];
  };
  for (const line of md.split("\n").map((l) => l.trimEnd())) {
    const item = /^(\s*)- (.*)$/.exec(line);
    if (item) {
      if (item[1]!.length >= 2 && items.length) items[items.length - 1]!.children.push(inline(item[2]!));
      else items.push({ text: inline(item[2]!), children: [] });
      continue;
    }
    flush();
    const heading = /^(#{1,3}) (.*)$/.exec(line);
    if (heading) out.push(`<h${heading[1]!.length}>${inline(heading[2]!)}</h${heading[1]!.length}>`);
    else if (line.trim()) out.push(`<p>${inline(line)}</p>`);
  }
  flush();
  return out.join("\n");
}

export function legalPage(page: string, url: URL): Response {
  const md = LEGAL_PAGES[page];
  if (!md) return Response.json({ error: "not_found" }, { status: 404 });
  if (url.searchParams.get("format") === "md") return new Response(md, { headers: { "content-type": "text/markdown; charset=utf-8" } });
  const title = /^# (.*)$/m.exec(md)?.[1] ?? "Bible Scroll";
  const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(title)} · Bible Scroll</title>
<style>:root{color-scheme:light dark;--fg:#2a2230;--muted:#6e6375;--bg:#fbf9fb;--accent:#8a4a73}
@media (prefers-color-scheme:dark){:root{--fg:#eee7f0;--muted:#a99daf;--bg:#1b171d;--accent:#d79bc2}}
body{margin:0;background:var(--bg);color:var(--fg);font:17px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}
main{max-width:42rem;margin:0 auto;padding:32px 20px 64px}h1{font-size:1.9rem;line-height:1.2}h2{font-size:1.25rem;margin-top:2rem}
a{color:var(--accent)}em{color:var(--muted)}li{margin:.3rem 0}</style></head><body><main>${markdownToHtml(md)}</main></body></html>`;
  return new Response(html, { headers: { "content-type": "text/html; charset=utf-8", "cache-control": "public, max-age=3600" } });
}
