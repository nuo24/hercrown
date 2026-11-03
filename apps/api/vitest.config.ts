import { cloudflareTest, readD1Migrations } from "@cloudflare/vitest-plugin";
import { generateKeyPairSync } from "node:crypto";
import { readFileSync } from "node:fs";
import { defineConfig } from "vitest/config";

export default defineConfig(async () => {
  const migrations = await readD1Migrations("./migrations");
  // Throwaway App Store Server API key so tests can check request signing (Apple itself is mocked).
  const appStoreKey = generateKeyPairSync("ec", { namedCurve: "P-256" });
  // A few chapters of each offline translation (seeds/*-test.sql), one SQL statement per entry.
  const kjvTestSeed = ["kjv", "bsb", "web"].flatMap((id) => readFileSync(`./seeds/${id}-test.sql`, "utf8")
    .split(/;\n/).map((s) => s.replace(/^--.*$/gm, "").trim()).filter(Boolean))
    // Study data subset (seeds/study-test.sql): note text can contain ";\n", so split only before each INSERT.
    .concat(readFileSync("./seeds/study-test.sql", "utf8").replace(/^--.*\n/, "").split(/;\n(?=INSERT )/)
      .map((s) => s.trim().replace(/;$/, "")).filter(Boolean));
  return {
    plugins: [
      cloudflareTest({
        wrangler: { configPath: "./wrangler.jsonc" },
        miniflare: {
          bindings: {
            TEST_MIGRATIONS: migrations,
            TEST_KJV_SEED: kjvTestSeed,
            API_BIBLE_KEY: "",
            APP_STORE_ISSUER_ID: "test-issuer-0000",
            APP_STORE_KEY_ID: "TESTKEY123",
            APP_STORE_PRIVATE_KEY: appStoreKey.privateKey.export({ type: "pkcs8", format: "pem" }).toString(),
            TEST_APP_STORE_PUBLIC_KEY: appStoreKey.publicKey.export({ type: "spki", format: "pem" }).toString(),
            APNS_KEY_ID: "APNSKEY123",
            APNS_PRIVATE_KEY: appStoreKey.privateKey.export({ type: "pkcs8", format: "pem" }).toString(), // Apple is mocked
            APPLE_TEAM_ID: "TEAM123456",
            OPENROUTER_API_KEY: "sk-or-test", // OpenRouter is mocked; never the real key from .dev.vars
            SUPERWALL_WEBHOOK_SECRET: "whsec_dGVzdC13ZWJob29rLXNlY3JldC0xMjM0NTY3ODkw", // base64("test-webhook-secret-1234567890")
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
