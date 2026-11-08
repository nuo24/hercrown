# Production deploy (owner runs this)

Production is humans only (AGENTS.md rule 6). This is the first-time setup; about 45 minutes. Do it after TestFlight works on staging and before submitting to the App Store.

Version 1.0 includes the $29.99 annual plan with a 7-day trial for eligible subscribers and the $2.99 weekly plan with no trial. Both $19.99 return offers are off for production. Leave the separate $19.99 subscription out of App Review and keep Superwall's legacy `paywall_decline` placement paused. The annual `trial_return_1999` offer can remain configured for sandbox testing. App Store Connect uses manual release.

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

The first two print an ID. Set them in `wrangler.jsonc` under `"production"`, replacing `REPLACE_WITH_PRODUCTION_D1_ID` and `REPLACE_WITH_PRODUCTION_KV_ID`. The R2 bucket and queue are referenced by name. Commit the binding changes before deploying.

## 2. Build the database (10 min)

```
npm run db:migrate:production
npm run seed:scripture:production       # KJV, BSB, WEB (large: a few minutes)
npm run build:study                     # only if seeds/study/ is missing any seed files
npm run seed:study:production
npm run seed:devotionals:production     # approved devotionals only
```

The migration command applies every pending migration through `0011_return_offers.sql`. Apply 0011 with the rest. It creates the table used by the staging offer flow, and the production Worker rejects those endpoints.

## 3. Secrets (15 min)

Each command asks you to paste the value. Paste it, press Enter. Nothing is saved in files or git.

| Secret | Where the value comes from |
|---|---|
| `BETTER_AUTH_SECRET` | **New** for production: run `openssl rand -base64 32` and paste the output. Never reuse staging's. |
| `OPENROUTER_API_KEY` | `apps/api/.dev.vars` |
| `APP_STORE_ISSUER_ID`, `APP_STORE_KEY_ID`, `APP_STORE_PRIVATE_KEY` | In-App Purchase credentials used for purchase verification and restore. The offer signer shares these credentials. There are no additional return-offer secrets for 1.0. |
| `APPLE_TEAM_ID` | `494RZLCNHQ` |
| `APNS_KEY_ID`, `APNS_PRIVATE_KEY` | `.dev.vars` (key CBVUDK44G6) |
| `APPLE_CLIENT_ID`, `APPLE_CLIENT_SECRET` | `.dev.vars` (renew the secret before 2027-05-02) |
| `TINYBIRD_TOKEN` | Tinybird ingest token. The Worker tags events with `environment=production`. |
| `TINYBIRD_READ_TOKEN` | Optional for normal app operation. The scheduled error-spike alert uses it to query the events data source. |
| `API_BIBLE_KEY` | Skip: there isn't one yet (only needed for extra online translations) |
| `SUPERWALL_WEBHOOK_SECRET` | Set this after creating the production webhook in step 5, before testing purchases. |

`EMAIL_FROM` is an optional Wrangler variable for Cloudflare email. With it empty, the app's support inbox still records messages and scheduled alerts go to Workers Observability. `AI_GATEWAY_URL` is optional. The default study configuration uses OpenRouter directly.

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
git status --short --untracked-files=no # expect no output before deploying
npm run deploy:production
```

Check that all four URLs return HTTP 200.

```sh
for path in health legal/privacy legal/terms legal/support; do
  curl -fsS -o /dev/null -w "%{http_code} /$path\n" "https://bible-scroll-api.bible-scroll-api.workers.dev/$path" || break
done
```

## 5. Superwall production webhook (5 min)

In Superwall → Integrations → Webhooks, add **Her Crown – Production**, version V2, with URL `https://bible-scroll-api.bible-scroll-api.workers.dev/webhooks/superwall`. Keep the staging webhook. The owner sets the new signing secret in Terminal using `npx wrangler secret put SUPERWALL_WEBHOOK_SECRET --env production`. Verify a signed delivery before release.

## 6. Point the app and the listing at production

After the production URLs pass, point Release builds at production and keep Debug pointed at staging. Update the app, Superwall Main and the App Store listing's legal and support URLs. Confirm Sandbox testing is hidden when the app points at production. For the owner-run smoke test, use a new test guest to sign in and read a chapter. Check a study answer with a verified Plus test account and confirm a Tinybird event has `environment=production`.

Archive from a clean commit after the partner's design pass. Use the production URLs in App Store Connect.

In the production-pointed TestFlight build, verify onboarding, free reading, sandbox checkout and sandbox restore on a fresh Her Crown profile. Confirm the production backend receives the sandbox purchase. Publish the reviewed privacy label and add the release build, subscription group, annual and weekly products to the same App Review submission. After approval and immediately before the owner presses Release, switch Superwall Main to all users without an active entitlement. Verify live checkout and restore separately after release.

## Safety

- Never run the `:staging` scripts with production ids or the other way round.
- The owner runs the production smoke checks with dedicated test accounts. Never use real user data for testing.
- `APP_STORE_ALLOW_SANDBOX` stays `"true"` in production: App Review and TestFlight purchases are sandbox purchases.

## November 8 additions (staging first)

Migrations now run through **0013**: 0012 adds only per-user prayer request counts; 0013 adds Community votes and private suggestions. No new secrets/vendors are required: personal prayers reuse OPENROUTER_API_KEY and the existing model configuration. Production does not expose the supplied fictional ballot profiles. Before enabling a live ballot, approve recipient identities, grant/tie rules, and a verified giving ledger. The owner reports $7,350 completed donations and a 30%-of-revenue commitment. Reconcile the financial records before launch. Review/publish the expanded App Privacy label for optional personal-prayer processing and private Community suggestions. This staging test release does not deploy these additions to production.
