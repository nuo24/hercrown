import { applyD1Migrations } from "cloudflare:test";
import { env } from "cloudflare:workers";

await applyD1Migrations(env.DB, env.TEST_MIGRATIONS);
await env.DB.batch(env.TEST_KJV_SEED.map((sql) => env.DB.prepare(sql)));
