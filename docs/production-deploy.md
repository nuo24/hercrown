# Production deploy (owner runs this)

Production is humans only (AGENTS.md rule 6). This is the first-time setup; about 45 minutes. Do it after TestFlight works on staging and before submitting to the App Store.

The production server will be **https://bible-scroll-api.bible-scroll-api.workers.dev** (already set as `BETTER_AUTH_URL` in `apps/api/wrangler.jsonc`). When the domain exists, it can move there.

Run everything from `apps/api` in Terminal:

```
cd ~/Downloads/bible-scroll-ios-build-kit/apps/api
npx wrangler whoami        # should show your Cloudflare account; if not: npx wrangler login
```

## 1. Create the production storage (5 min)

```
npx wrangler d1 create bible-scroll-db
npx wrangler kv namespace create bible-scroll-kv
npx wrangler r2 bucket create bible-scroll-files
npx wrangler queues create bible-scroll-events
```

The first two print an id. Paste them into `wrangler.jsonc` under `"production"`, replacing `REPLACE_WITH_PRODUCTION_D1_ID` and `REPLACE_WITH_PRODUCTION_KV_ID`. (Or send them to Claude to paste; ids aren't secret.)

## 2. Build the database (10 min)

```
npm run db:migrate:production
npm run seed:scripture:production       # KJV, BSB, WEB (large: a few minutes)
npm run build:study                     # only if apps/api/seeds/study/ is empty
npm run seed:study:production
npm run seed:devotionals:production     # approved devotionals only
```

## 3. Secrets (15 min)

Each command asks you to paste the value. Paste it, press Enter. Nothing is saved in files or git.

| Secret | Where the value comes from |
|---|---|
| `BETTER_AUTH_SECRET` | **New** for production: run `openssl rand -base64 32` and paste the output. Never reuse staging's. |
| `OPENROUTER_API_KEY` | `apps/api/.dev.vars` |
| `APP_STORE_ISSUER_ID`, `APP_STORE_KEY_ID`, `APP_STORE_PRIVATE_KEY` | `.dev.vars` (the In-App Purchase key, BH6NN72SQZ) |
| `APPLE_TEAM_ID` | `494RZLCNHQ` |
| `APNS_KEY_ID`, `APNS_PRIVATE_KEY` | `.dev.vars` (key CBVUDK44G6) |
| `APPLE_CLIENT_ID`, `APPLE_CLIENT_SECRET` | `.dev.vars` (renew the secret before 2027-05-02) |
| `TINYBIRD_TOKEN`, `TINYBIRD_READ_TOKEN` | `.dev.vars` (same workspace; events are tagged `production`) |
| `API_BIBLE_KEY` | Skip: there isn't one yet (only needed for extra online translations) |
| `SUPERWALL_WEBHOOK_SECRET` | From step 5 (new webhook) |

```
npx wrangler secret put BETTER_AUTH_SECRET --env production
npx wrangler secret put OPENROUTER_API_KEY --env production
# …one line per secret in the table
```

For the multi-line private keys (`APP_STORE_PRIVATE_KEY`, `APNS_PRIVATE_KEY`), pipe the file instead of pasting:

```
npx wrangler secret put APP_STORE_PRIVATE_KEY --env production < ~/Documents/hercrown-keys/SubscriptionKey_BH6NN72SQZ.p8
npx wrangler secret put APNS_PRIVATE_KEY --env production < ~/Documents/hercrown-keys/AuthKey_CBVUDK44G6.p8
```

## 4. Deploy and check (5 min)

```
npm run check && npm test
npm run deploy:production
curl https://bible-scroll-api.bible-scroll-api.workers.dev/health
```

Open these in a browser; each should load:
- https://bible-scroll-api.bible-scroll-api.workers.dev/legal/privacy
- https://bible-scroll-api.bible-scroll-api.workers.dev/legal/terms
- https://bible-scroll-api.bible-scroll-api.workers.dev/legal/support

## 5. Superwall production webhook (5 min)

Superwall → Settings → Webhooks → **Add**: name "Her Crown – Production", version V2, URL `https://bible-scroll-api.bible-scroll-api.workers.dev/webhooks/superwall`. Copy its signing secret into `npx wrangler secret put SUPERWALL_WEBHOOK_SECRET --env production`. Keep the staging webhook too.

## 6. Point the app and the listing at production (Claude)

Tell Claude production is live. Claude will:
- set the iOS app's App Store and TestFlight builds to the production server (Debug builds stay on staging),
- change the privacy, terms and support links in `docs/app-store-listing.md` and the legal pages,
- run a check against production (sign-in, Bible, study tools, events reaching Tinybird).

Then upload a new TestFlight build and use those links in App Store Connect.

## Safety

- Never run the `:staging` scripts with production ids or the other way round.
- Production data is real people's: no test commands against it. Testing happens on staging.
- `APP_STORE_ALLOW_SANDBOX` stays `"true"` in production: App Review and TestFlight purchases are sandbox purchases.
