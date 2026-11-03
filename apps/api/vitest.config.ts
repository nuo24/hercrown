import { cloudflareTest, readD1Migrations } from "@cloudflare/vitest-plugin";
import { readFileSync } from "node:fs";
import { defineConfig } from "vitest/config";

export default defineConfig(async () => {
  const migrations = await readD1Migrations("./migrations");
  // A few KJV chapters (seeds/kjv-test.sql), one SQL statement per entry.
  const kjvTestSeed = readFileSync("./seeds/kjv-test.sql", "utf8")
    .split(/;\n/).map((s) => s.replace(/^--.*$/gm, "").trim()).filter(Boolean);
  return {
    plugins: [
      cloudflareTest({
        wrangler: { configPath: "./wrangler.jsonc" },
        miniflare: {
          bindings: {
            TEST_MIGRATIONS: migrations,
            TEST_KJV_SEED: kjvTestSeed,
            API_BIBLE_KEY: "",
            BETTER_AUTH_SECRET: "test-secret-test-secret-test-secret-00",
            APPLE_CLIENT_ID: "",
            APPLE_CLIENT_SECRET: "",
          },
        },
      }),
    ],
    test: { setupFiles: ["./test/apply-migrations.ts"] },
  };
});
