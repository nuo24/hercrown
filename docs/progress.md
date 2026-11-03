# Progress

Playbook phases ([ai-app-playbook AGENTS.md](https://github.com/blakeandersonw/ai-app-playbook/blob/main/AGENTS.md)) adapted to Bible Scroll. Updated 2026-11-03.

## Phase 0–1: Niche & brief — ⏭️ skipped on purpose
Product, design and mockup already exist (this kit). Pricing decided: see [decisions/0003](decisions/0003-trial-hard-paywall-decline-offer.md).

## Phase 2: Accounts & repo — ⚠️ mostly done
- [x] `apps/api` scaffolded from the playbook templates
- [x] `AGENTS.md`, `CLAUDE.md`, `docs/progress.md`, `docs/decisions/`, `docs/later.md`
- [x] Root scripts: `dev`, `check`, `test`, `deploy:staging`
- [x] Local git repository and first commit
- [x] GitHub: https://github.com/nuo24/new (pushed)
- [x] Apple Developer account
- [x] Cloudflare (Workers Paid, R2 on), OpenRouter (key in staging)
- [x] Apple: W-9 active; Paid Apps agreement + bank processing (submitted 2026-11-03)
- [ ] **[HUMAN]** Apple Small Business Program, Superwall, Tinybird
- API.Bible: not now ([decision 0008](decisions/0008-launch-translations.md))
- [ ] `apps/ios` (port `starter-ios`)

## Phase 3: Backend + database — ✅ on staging
- [x] D1 migrations: auth, app tables, Scripture catalog (`apps/api/migrations/`)
- [x] `GET /health`, JSON errors, rate limits on auth
- [x] Core API: profile, avatar, preferences, onboarding, saved passages, reading events + streak, plans
- [x] Scripture: KJV, BSB, WEB offline (verified builds), chapters, passages, per-translation search, API.Bible connector
- [x] Words of Jesus (red letters) for KJV and WEB; psalm titles kept separate from verse 1
- [x] Error events to Tinybird (Phase 9)
- [x] Staging: https://bible-scroll-api-staging.bible-scroll-api.workers.dev — D1 migrated + KJV/BSB/WEB seeded, KV, R2, queue, secrets (auth, OpenRouter); `/health` 200, guest sign-in, Scripture, search, plans, events checked 2026-11-03

## Phase 4: Auth — ⚠️ built locally
- [x] Anonymous sign-in, bearer tokens, account deletion, guest → account merge (tested)
- [x] Sign in with Apple (code ready; switched off until keys exist)
- [ ] **[HUMAN]** Apple Services ID + key → `wrangler secret put APPLE_CLIENT_ID / APPLE_CLIENT_SECRET`
- [ ] Verify Apple sign-in end to end on staging

## Phase 5: AI study tools — ✅ on staging ([docs/study-tools.md](study-tools.md))
- [x] Sources loaded: STEPBible Greek/Hebrew + lexicons, OpenBible cross-references, JFB / Matthew Henry / Adam Clarke (verified build, checksums)
- [x] `ai.ts`: DeepSeek v4.1 Flash via OpenRouter, fallback model, streaming, timeouts, `ai_call` cost events, daily limit
- [x] Explain Easier, Deeper Study, Original Language, Related Verses: generated once per verse, stored, cited, labeled, reportable
- [x] Evals: 26 verses × 2 tools, 51/52 automatic ([report](evals/study-2026-11-03.md)); ~$0.0003 per answer
- [x] OpenRouter key on staging
- [ ] **[HUMAN]** Read the eval report; decide on sensitive passages (hand-reviewed answers?) and Tyndale Open Study Notes (CC BY-SA)
- [ ] Optional: Cloudflare AI Gateway (`AI_GATEWAY_URL`); complete Matthew Henry from CCEL

## Phase 7: iOS — not started

## Phase 8: Payments & entitlements — ⚠️ server side built locally
- [x] `POST /webhooks/superwall`: Svix signature verified, processed once, out-of-order safe → `entitlements`
- [x] `GET /me/entitlements` (also in `GET /me`) is the only Premium check; trial / active / grace / expired / refunded
- [x] Reading, saving and streaks free; reading plans need Plus (`premium_required`)
- [x] Subscription follows a guest who links an account
- [x] **Restore Purchases** (`POST /me/restore`): verified with Apple's App Store Server API, ownership transfer + log, retry-safe — [docs/restore-purchases.md](restore-purchases.md)
- [x] Webhooks accept Superwall V2 (current) and V1; refunds handled in both
- [ ] **[HUMAN]** In-App Purchase key (App Store Connect → Integrations) → `APP_STORE_ISSUER_ID`, `APP_STORE_KEY_ID`, `APP_STORE_PRIVATE_KEY`
- [ ] Sandbox test: purchase → reinstall → Restore → Plus returns (needs the key + products)
- [ ] **[HUMAN]** App Store Connect products (see restore doc): yearly $29.99 + 7-day trial, weekly $2.99 + 7-day trial, yearly.offer with $19.99 first-year intro price; Family Sharing on; Superwall project + **V2** webhook → `wrangler secret put SUPERWALL_WEBHOOK_SECRET`
- [ ] iOS: `Superwall.shared.identify(userId:)` with our user id right after guest sign-in; paywall placements; decline offer
- [x] Trial-ending reminder: push 2 days before + in-app notice + Settings line ([docs/trial-reminder.md](trial-reminder.md)); needs the APNs key to send

## Phase 9: Analytics & errors — ⚠️ built locally ([docs/analytics.md](analytics.md))
- [x] `POST /events` → Queue → Tinybird Events API; server events for onboarding, verified billing, restore outcomes, features, errors
- [x] Dedup ids (one trial per subscription, V1 = V2), sandbox flag, person id kept across guest → account link, no profile or reading data
- [x] Tinybird data source + endpoints: funnel (with denominators), installs, revenue, restores, errors
- [ ] **[HUMAN]** Tinybird workspace → `tb --cloud deploy --check` → append-only token → `wrangler secret put TINYBIRD_TOKEN`; region host in `TINYBIRD_HOST`; `wrangler queues create bible-scroll-events-staging`
- [ ] Staging run-through: every funnel event and a thrown test error appear in Tinybird
- [ ] Cron alert on error / webhook-failure spikes
- [ ] iOS: headers, on-disk event queue, Superwall delegate → paywall events

## Next, in order
1. ~~Restore Purchases~~ ✅ (local)
2. ~~Offline BSB and WEB~~ ✅ (local; words of Jesus + psalm titles too). CPDV pending a decision ([0005](decisions/0005-offline-translations.md))
3. ~~Tinybird analytics~~ ✅ (local; needs a Tinybird workspace to deploy)
4. ~~Trial-ending reminder~~ ✅ (local; push needs the APNs key + a phone)
5. ~~AI study tools~~ ✅ (staging; owner review of the eval report pending)

## Gaps found in the competitor recording ([walkthrough](research/scroll-the-bible-walkthrough.md))
- [ ] Notes per verse (auto-saved) and a "library" (studies, studied, saved, notes)
- [ ] Bible progress: chapters completed of 1,189; days opened vs days read; weeks in a row; days this year
- [ ] Verse of the Day and Today's Devotional (+ devotionals-read count)
- [ ] Preferences: font size (4 steps), Words of Jesus in red toggle (data ✅ for KJV/WEB), system theme
- [ ] Email sign-in (they use email only; we have Apple — add email OTP/magic link)
- [ ] App Tracking Transparency prompt for ad attribution (marketing decision)

## Phases 10–14 — not started

## Open owner decisions
- Licenses for the 10 online translations (NLT, NLTCE, AMP, NASB, NASB95, NKJV, CSB, CEV, GNT, NIV) — [decisions/0004](decisions/0004-scripture-sources.md)
- API.Bible caching terms (ask support@api.bible)
- Community tab direction ([later.md](later.md))
- Final bundle id (placeholder `com.biblescroll.app`)
