import type { D1Migration } from "cloudflare:test";

declare global {
  namespace Cloudflare {
    interface Env {
      TEST_MIGRATIONS: D1Migration[];
      TEST_KJV_SEED: string[];
      TEST_APP_STORE_PUBLIC_KEY: string;
    }
  }
}
