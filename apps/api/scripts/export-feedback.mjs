import { execFileSync } from "node:child_process";
import { mkdirSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { resolve } from "node:path";

const environment = process.argv[2];
if (!["staging", "production"].includes(environment)) {
  throw new Error("Usage: node scripts/export-feedback.mjs staging|production [output.csv]");
}
const apiDirectory = fileURLToPath(new URL("..", import.meta.url));
const output = resolve(process.argv[3] ?? `feedback-${environment}-${new Date().toISOString().slice(0, 10)}.csv`);
const query = `SELECT id, category, message, app_version, status,
  datetime(created_at / 1000, 'unixepoch') AS created_utc
  FROM support_requests
  WHERE category IN ('Feedback', 'Something isn''t working')
  ORDER BY created_at DESC`;
const result = JSON.parse(execFileSync(process.execPath, [
  resolve(apiDirectory, "node_modules/wrangler/bin/wrangler.js"),
  "d1", "execute", "DB", "--env", environment, "--remote", "--command", query, "--json"
], { cwd: apiDirectory, encoding: "utf8", stdio: ["inherit", "pipe", "inherit"] }));
if (!Array.isArray(result) || result.some((entry) => !entry.success)) {
  throw new Error("Feedback export failed. No file was written.");
}
const columns = ["id", "category", "message", "app_version", "status", "created_utc"];
function cell(value) {
  let text = String(value ?? "");
  // Keep user-written messages as text when opened in a spreadsheet.
  if (/^[\s]*[=+@-]/.test(text) || /^[\t\r\n]/.test(text)) text = `'${text}`;
  return `"${text.replaceAll('"', '""')}"`;
}
const rows = result.flatMap((entry) => entry.results ?? []);
const csv = [columns, ...rows.map((row) => columns.map((column) => row[column]))]
  .map((row) => row.map(cell).join(",")).join("\r\n");
mkdirSync(resolve(output, ".."), { recursive: true });
writeFileSync(output, `\uFEFF${csv}\r\n`, { mode: 0o600 });
console.log(`Saved ${rows.length} feedback tickets to ${output}`);
