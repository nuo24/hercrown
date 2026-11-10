# Production deploy (owner runs this)

Production is humans only (AGENTS.md rule 6). Production storage and the initial deployment already exist. For the current release, follow the refresh checklist below; do not recreate resources or rotate existing auth secrets. The numbered first-time setup is retained for disaster recovery only.

Version 1.0 includes the $39.99 annual plan with a 7-day trial for eligible subscribers and the $5.99 monthly plan with no trial. Weekly is retired from new checkout. Both $19.99 return offers are off for production. Leave the separate $19.99 subscription out of App Review and keep Superwall's legacy `paywall_decline` placement paused. The annual `trial_return_1999` offer remains parked; the app disables both return offers globally. App Store Connect uses manual release.

The production server will be **https://bible-scroll-api.bible-scroll-api.workers.dev** (already set as `BETTER_AUTH_URL` in `apps/api/wrangler.jsonc`). When the domain exists, it can move there.

Run everything from `apps/api` in Terminal:

```
cd ~/Downloads/bible-scroll-ios-build-kit/apps/api
npx wrangler whoami        # should show your Cloudflare account; if not: npx wrangler login
```

## Current release refresh (verified 2026-11-10)

Production currently serves version `2492147a-dce3-4d05-b311-c29636298b09` from November 6. `/health`, `/legal/privacy`, `/legal/terms` and `/legal/support` all return 200. This does not verify the new endpoints. Production secret names include the existing auth, Apple, APNs, OpenRouter, Superwall and Tinybird keys, but **not API_BIBLE_KEY**.

1. Owner: from `apps/api`, run `npm run db:migrate:production` to apply the three pending migrations. Do not repeat storage creation or the large Scripture/study seeds.
2. Owner: rotate the previously shared API.Bible key in its dashboard, then run `npx wrangler secret put API_BIBLE_KEY --env production`. Enter the value privately.
3. Confirm publisher permissions for the enabled reading, sharing, snapshots and widget uses. Review the expanded App Privacy label for optional personal prayer processing and private suggestions.
4. From a tested clean commit, owner runs `npm run deploy:production`. Record the source SHA and returned Cloudflare version in `docs/progress.md`.
5. Recheck public endpoints. Test new production endpoints with dedicated test accounts: prayer, licensed chapter, feedback, Community empty-ballot state, and a Tinybird event tagged production. Verify the owner-reported giving total against records; production ballots remain disabled until real recipients are approved.
6. Archive the final iOS Release candidate without `HC_STAGING_TESTFLIGHT`. Debug and staging beta builds continue pointing at staging. Verify checkout, restore, signed webhook delivery, notifications and account deletion in the production-connected TestFlight candidate.
7. Refresh screenshots and review notes for the final UI. Select the tested candidate for 1.0, attach annual/monthly subscriptions, and retain manual release. Review current Superwall audiences before submission so App Review can reach checkout. Do not activate parked discount campaigns.
8. Submit for review only after these checks. After approval, confirm the Main audience includes intended users without an active entitlement before the owner manually releases. Verify public App Store checkout/restore separately.

## First-time recovery setup (not needed for this refresh)

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

The migration command applies every pending migration through `0014_licensed_translations.sql`. The current production database has 0001–0011 applied; 0012–0014 were confirmed pending on 2026-11-10. These add prayer request counts, Community tables and online translation metadata. Do not edit applied migrations.

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
| `API_BIBLE_KEY` | Required for NKJV, MSG, AMP and NLT. Set a regenerated commercial API.Bible key; never ship it in iOS or commit it |
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

In the production-pointed TestFlight build, verify onboarding, free reading, sandbox checkout and sandbox restore on a fresh Her Crown profile. Confirm the production backend receives the sandbox purchase. Publish the reviewed privacy label and add the release build, subscription group, annual and monthly products to the same App Review submission. After approval and immediately before the owner presses Release, switch Superwall Main to all users without an active entitlement. Verify live checkout and restore separately after release.

## Safety

- Never run the `:staging` scripts with production ids or the other way round.
- The owner runs the production smoke checks with dedicated test accounts. Never use real user data for testing.
- `APP_STORE_ALLOW_SANDBOX` stays `"true"` in production: App Review and TestFlight purchases are sandbox purchases.

## November 8 additions (staging first)

Migrations now run through **0013**: 0012 adds only per-user prayer request counts; 0013 adds Community votes and private suggestions. No new secrets/vendors are required: personal prayers reuse OPENROUTER_API_KEY and the existing model configuration. Production does not expose the supplied fictional ballot profiles. Before enabling a live ballot, approve recipient identities, grant/tie rules, and a verified giving ledger. The owner reports $7,350 completed donations and a 30%-of-revenue commitment. Reconcile the financial records before launch. Review/publish the expanded App Privacy label for optional personal-prayer processing and private Community suggestions. This staging test release does not deploy these additions to production.

## Licensed online translations (build 18; production pending)

Migrations now run through **0014**. For production, the owner must apply 0014 and set `API_BIBLE_KEY` using `npx wrangler secret put API_BIBLE_KEY --env production`, then deploy a clean committed checkout. Use a regenerated key before launch because the original was shared in chat. Do not seed NKJV/MSG/AMP/NLT text into D1 or bundle it. The reader fetches chapters through the Worker; the selected translation also applies to Home/Discover Scripture through the existing translation resolver. Verify online translation changes and offline bundled fallback in the release candidate. Verify publisher permissions for each intended sharing/widget usage before production launch. NIV and ESV are not enabled.
