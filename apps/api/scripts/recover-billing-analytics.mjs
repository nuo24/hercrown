// Human-run repair for initial purchases already verified and retained by this Worker.
// Dry-run by default. Never trusts client checkout events or changes entitlements.
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const args = process.argv.slice(2);
const value = key => args[args.indexOf(key) + 1];
if (args.includes("--help")) {
  console.log("node apps/api/scripts/recover-billing-analytics.mjs --env production --since 2026-11-19T00:00:00-05:00 [--apply]");
  process.exit(0);
}
const environment = value("--env");
const since = Date.parse(value("--since"));
if (!args.includes("--env") || !["production", "staging"].includes(environment) || !args.includes("--since") || !Number.isFinite(since)) {
  throw new Error("Provide --env production|staging and an explicit --since ISO timestamp.");
}
const config = JSON.parse(readFileSync(new URL("../../../tinybird/.tinyb", import.meta.url)));
const readToken = process.env.TINYBIRD_READ_TOKEN || config.token;
const writeToken = process.env.TINYBIRD_TOKEN || config.token;
const host = config.host;
if (host !== "https://api.us-east.tinybird.co") throw new Error("Unexpected Tinybird region; review the configuration.");
function curl(path, token, data) {
  // Keep the token out of shell expansion, command-line arguments and output.
  const escaped = token.replaceAll("\\", "\\\\").replaceAll('"', '\\"');
  const input = `header = "Authorization: Bearer ${escaped}"\n`;
  const options = ["--silent", "--show-error", "--fail-with-body", "--max-time", "30", "--config", "-"];
  if (data !== undefined) options.push("--request", "POST", "--header", "Content-Type: application/x-ndjson", "--data-binary", data);
  return JSON.parse(execFileSync("/usr/bin/curl", [...options, host + path], { input, encoding: "utf8", maxBuffer: 4_000_000 }));
}
const sqlString = value => "'" + value.replaceAll("'", "''") + "'";
const sql = `SELECT m.payload, m.received_at, COALESCE(a.person_id,e.user_id) AS person_id
  FROM unmatched_store_events m JOIN webhook_events w ON w.id=m.id AND w.source='superwall'
  LEFT JOIN entitlements e ON e.original_transaction_id=m.original_transaction_id
  LEFT JOIN analytics_ids a ON a.user_id=e.user_id
  WHERE m.type='initial_purchase' AND m.received_at >= ${since} ORDER BY m.received_at`;
const stdout = execFileSync(process.execPath, [fileURLToPath(new URL("../node_modules/wrangler/bin/wrangler.js", import.meta.url)),
  "d1", "execute", "DB", "--env", environment, "--remote", "--command", sql, "--json"],
  { cwd: fileURLToPath(new URL("..", import.meta.url)), encoding: "utf8", maxBuffer: 4_000_000 });
const records = JSON.parse(stdout).flatMap(result => result.results || []);
let repaired = 0, missing = 0, skipped = 0;
for (const record of records) {
  const payload = JSON.parse(record.payload);
  const event = payload.event_data;
  // Recovery is intentionally limited to actual V2 store purchase facts.
  if (!event || payload.type !== "initial_purchase" || !event.original_transaction_id || !event.product_id ||
      !["PRODUCTION", "SANDBOX"].includes(event.environment) || !Number.isFinite(payload.occurred_at)) { skipped++; continue; }
  if (environment === "staging" && event.environment === "PRODUCTION") { skipped++; continue; }
  const name = event.period_type === "TRIAL" ? "trial_started" : "subscription_started";
  const legacyID = `${name}:${event.original_transaction_id}`;
  const id = `${environment}:${legacyID}`;
  const query = `SELECT count() AS n FROM events FINAL WHERE environment=${sqlString(environment)} AND event=${sqlString(name)}
    AND event_id IN (${sqlString(legacyID)},${sqlString(id)}) FORMAT JSON`;
  if (Number(curl("/v0/sql?" + new URLSearchParams({ q: query }), readToken).data[0].n) > 0) { skipped++; continue; }
  missing++;
  if (!args.includes("--apply")) continue;
  const timestamp = ms => new Date(ms).toISOString().replace("T", " ").replace("Z", "");
  const row = { event_id: id, event: name, timestamp: timestamp(payload.occurred_at), received_at: timestamp(Date.now()),
    environment, sandbox: event.environment === "SANDBOX" ? 1 : 0, source: "api", person_id: record.person_id,
    install_id: null, app_version: null, platform: null, country: null,
    props: JSON.stringify({ product_id: event.product_id, period_type: event.period_type, store: event.store,
      price: event.price ?? null, proceeds: event.proceeds ?? null }) };
  curl("/v0/events?name=events", writeToken, JSON.stringify(row));
  const verification = `SELECT count() AS n FROM events FINAL WHERE environment=${sqlString(environment)} AND event_id=${sqlString(id)} FORMAT JSON`;
  if (Number(curl("/v0/sql?" + new URLSearchParams({ q: verification }), readToken).data[0].n) !== 1) {
    throw new Error("Ingestion accepted but readback not confirmed. Rerun the dry-run before retrying.");
  }
  repaired++;
}
console.log(JSON.stringify({ environment, mode: args.includes("--apply") ? "apply" : "dry-run", examined: records.length, missing, repaired, skipped }));
