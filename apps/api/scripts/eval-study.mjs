// Runs the study-tool accuracy evals (evals/study-cases.json) against a running API and writes a report for review.
//
//   STUDY_EVAL_TOKEN=<bearer token of a Plus account> node scripts/eval-study.mjs [baseUrl] [report.md]
//
// For fresh answers, clear stored ones first (local: npx wrangler d1 execute DB --local --command "DELETE FROM study_answers").
// Automatic checks catch obvious failures. A person still reads every answer: the report includes them all.
import { readFileSync, writeFileSync } from "node:fs";

const base = process.argv[2] ?? "http://localhost:8787";
const out = process.argv[3] ?? new URL(`../../../docs/evals/study-${new Date().toISOString().slice(0, 10)}.md`, import.meta.url).pathname;
const token = process.env.STUDY_EVAL_TOKEN;
if (!token) throw new Error("Set STUDY_EVAL_TOKEN to the bearer token of a Plus account");
const { cases, global_exclude } = JSON.parse(readFileSync(new URL("../evals/study-cases.json", import.meta.url), "utf8"));

const LIMITS = {
  "Simple explanation": 140, "Key takeaway": 30, "Historical context": 140, "Original language": 120,
  "Life in biblical times": 110, "Related passages": 110, "Reflect": 40,
};
const NEEDS_CITATION = new Set(["Simple explanation", "Historical context", "Original language", "Related passages"]);
const words = (s) => s.replace(/\[[^\]]+\]/g, "").split(/\s+/).filter(Boolean).length;
const re = (p) => new RegExp(p, "iu");

const results = [];
for (const c of cases) {
  for (const tool of ["explain", "deeper"]) {
    const started = Date.now();
    const res = await fetch(`${base}/study/${c.ref}/${tool}`, { headers: { authorization: `Bearer ${token}` } });
    const ms = Date.now() - started;
    const body = await res.json().catch(() => ({}));
    const problems = [];
    if (res.status !== 200) problems.push(`HTTP ${res.status} ${body.error ?? ""}`);
    const sections = body.sections ?? [];
    const text = sections.map((s) => s.text).join("\n");
    if (res.status === 200) {
      if (c.include.length && !c.include.some((p) => re(p).test(text))) problems.push(`missing: ${c.include.join(" / ")}`);
      for (const p of [...c.exclude, ...global_exclude]) if (re(p).test(text)) problems.push(`contains: ${p}`);
      for (const s of sections) {
        if (NEEDS_CITATION.has(s.title) && !/\[[A-Za-z-]+\]/.test(s.text)) problems.push(`no citation in "${s.title}"`);
        if (words(s.text) > (LIMITS[s.title] ?? 150)) problems.push(`"${s.title}" is ${words(s.text)} words`);
      }
    }
    results.push({ ref: c.ref, label: body.label ?? c.ref, tool, ms, cached: body.cached, problems, sections, sources: (body.sources ?? []).map((s) => s.tag) });
    console.log(`${problems.length ? "✗" : "✓"} ${c.ref} ${tool} ${ms}ms ${problems.join("; ")}`);
  }
}

const passed = results.filter((r) => r.problems.length === 0).length;
const fresh = results.filter((r) => r.cached === false).length;
const lines = [
  `# Study tools eval: ${new Date().toISOString().slice(0, 10)}`,
  "",
  `Run: \`node scripts/eval-study.mjs ${base}\` · ${cases.length} verses × 2 tools · ${fresh} freshly generated, ${results.length - fresh} stored.`,
  "",
  `**Automatic checks: ${passed}/${results.length} passed.** They check the format, citations, length, an expected fact, and known wrong or overconfident claims. They don't prove an answer is right: read every answer below and mark it.`,
  "",
  "| Verse | Tool | Time | Sources cited | Automatic | Reviewer |",
  "|---|---|---|---|---|---|",
  ...results.map((r) => `| ${r.label} | ${r.tool} | ${(r.ms / 1000).toFixed(1)}s | ${r.sources.join(", ")} | ${r.problems.length ? `✗ ${r.problems.join("; ")}` : "✓"} | |`),
  "",
  "## Answers",
  ...results.flatMap((r) => [
    "", `### ${r.label}: ${r.tool === "explain" ? "Explain easier" : "Deeper study"}`, "",
    ...(r.sections.length ? r.sections.flatMap((s) => [`**${s.title}.** ${s.text}`, ""]) : [`_No answer: ${r.problems.join("; ")}_`, ""]),
  ]),
];
writeFileSync(out, lines.join("\n") + "\n");
console.log(`\n${passed}/${results.length} passed automatic checks. Report: ${out}`);
