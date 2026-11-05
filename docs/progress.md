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
- [x] Sign in with Apple on staging: key CBVUDK44G6, client id `com.hercrown.app`; server rejects bad tokens (checked 2026-11-03)
- [ ] **Renew `APPLE_CLIENT_SECRET` before 2027-05-02** (Apple caps it at 6 months; regenerate from AuthKey_CBVUDK44G6.p8)
- [ ] Verify Apple sign-in end to end from the iOS app

## Phase 5: AI study tools — ✅ on staging ([docs/study-tools.md](study-tools.md))
- [x] Sources loaded: STEPBible Greek/Hebrew + lexicons, OpenBible cross-references, JFB / Matthew Henry / Adam Clarke (verified build, checksums)
- [x] `ai.ts`: DeepSeek v4.1 Flash via OpenRouter, fallback model, streaming, timeouts, `ai_call` cost events, daily limit
- [x] Explain Easier, Deeper Study, Original Language, Related Verses: generated once per verse, stored, cited, labeled, reportable
- [x] Evals: 26 verses × 2 tools, 51/52 automatic ([report](evals/study-2026-11-03.md)); ~$0.0003 per answer
- [x] OpenRouter key on staging
- [ ] **[HUMAN]** Read the eval report; decide on sensitive passages (hand-reviewed answers?) and Tyndale Open Study Notes (CC BY-SA)
- [ ] Optional: Cloudflare AI Gateway (`AI_GATEWAY_URL`); complete Matthew Henry from CCEL

## Phase 7: iOS — in progress ([apps/ios](../apps/ios/README.md))
- Fixed the native staging guest restart by sending bearer authentication without web cookies. Reproduced the stale-cookie rejection against staging, verified a clean guest reports Free, and installed a diagnostic build that clears Superwall's cached user state on a fresh start. The onboarding paywall and Apple sandbox checkout still need a phone retest.
- Reflection now reserves keyboard-visible space for notes and removes its reading-completion button. Discover confirms completion and shows marked passages under Saved → Studied on the same device, with access to their notes. Streak detail uses the original flame and an illustrated reading journal. Verified the streak screen in light and dark on iPhone 17 Pro simulator, installed the staging build on iPhone 14 Pro, and passed all 166 API tests. Phone verification of the note and Discover interactions is pending.
- Batch 1 follow-up: verify the open Translation menu, compare the Chapter picker and selected onboarding states, and close the remaining Reader and Dock icon differences. The six shared onboarding updates are in one commit.
- Matched the Reader more closely to the supplied recording with a wider verse column, smaller contextual illustrations, and more compact controls.
- Refined native onboarding against the supplied mockup recording using the bundled illustrations, with a smaller scroll-intro composition and more room for the question layouts. Restored the Community header with Saved passages and Settings.
- [x] Xcode project (iOS 17+, SwiftUI, Xcode 26.6), artwork catalog, offline KJV/BSB/WEB bundled from the verified seeds
- [x] Foundation: API client (bearer + app headers), Keychain session, guest sign-in, `/me` sync, analytics queue → `/events`
- [x] Design system: tokens, Baskerville, shared gradient (exact port of gradient-theme.js), floating neutral dock, capsule buttons
- [x] Bible reader: verse-per-page paging, persistent verse rail (drag / VoiceOver adjustable), translation + chapter pickers, red letters, psalm titles, contextual art, save/share/reflect, bookmark position, reading days + chapter completion
- [x] Onboarding: all 8 steps per the mockup, skip/back, guest path, daily reminder (local notification after opt-in), answers saved, completion
- [x] Study sheets: Explain easier and Deeper study (streaming), Original language, Related verses, widget verse, save, report
- [x] Home: greeting + streak, streak card with Mark today as read, verse of the day, verse search, Today's Reading (plan sheet; Plus), "For the season you're in" → Discover, today's devotional (labeled AI-assisted and reviewed), streak/progress sheet. Placeholder app icon (crown of thorns)
- [x] Legal pages on the Worker (`/legal/privacy|terms|refunds|credits|support`): sole proprietor, contact email only, New Jersey law. Owner's legal name still to fill in; legal review before launch
- [x] Discover: filters (For you, plan, nine themes), themed artwork, Scripture cards with reflections (not Scripture), Home topic handoff
- [x] Library: saved verses, notes, saved studies, studied; auto-saved notes on the reflection sheet
- [x] Settings: profile + photo, Sign in with Apple (links guest data), delete account, subscription + Restore Purchases (StoreKit 2 → server verify), appearance, topics, reading pace, reminder + time, translation, font size, red letters, Contact & Support (email for now), FAQs, legal pages in app
- [x] Superwall (SuperwallKit 4.19): configure, identify with our user id, placements (onboarding_complete, study_*, plan_start, settings*), purchase → server verify, events → analytics; Home trial notice; push registration (PUT /me/devices) offered when a trial starts
- [x] Home-screen widget (small/medium/large): her widget verse or today's, via App Group `group.com.hercrown.app`
- [ ] Superwall dashboard: campaigns per placement, paywall_decline → $19.99 offer (owner)
- [ ] On a phone: Sign in with Apple, push token, purchase in sandbox (TestFlight), widget on the home screen
- Note: unit tests build; running them from the agent's terminal hangs (simulator test-runner connection) — run with ⌘U in Xcode

## Phase 8: Payments & entitlements — ⚠️ server side built locally
- [x] `POST /webhooks/superwall`: Svix signature verified, processed once, out-of-order safe → `entitlements`
- [x] `GET /me/entitlements` (also in `GET /me`) is the only Premium check; trial / active / grace / expired / refunded
- [x] Reading, saving and streaks free; reading plans need Plus (`premium_required`)
- [x] Subscription follows a guest who links an account
- [x] **Restore Purchases** (`POST /me/restore`): verified with Apple's App Store Server API, ownership transfer + log, retry-safe — [docs/restore-purchases.md](restore-purchases.md)
- [x] Webhooks accept Superwall V2 (current) and V1; refunds handled in both
- [x] In-App Purchase key BH6NN72SQZ on staging; Apple sandbox accepts it; production answers 401 until the app is live (server falls back to sandbox)
- [x] Push key CBVUDK44G6 on staging; APNs sandbox + production accept it (checked 2026-11-03)
- [x] App Store Connect: app 6830437910, group Plus, products `hercrown.plus.yearly` / `.weekly` / `.yearly.offer`
- [ ] Sandbox test: purchase → reinstall → Restore → Plus returns (needs the key + products)
- [x] Superwall: app 59373 (Indie plan), public key in the iOS app; webhook "Her Crown – Staging" (V2) → staging, signature verified (signed 200, forged 401) 2026-11-03
- [ ] App Store Server Notifications URL from Superwall → App Store Connect (Production + Sandbox, V2)
- [ ] iOS: `Superwall.shared.identify(userId:)` with our user id right after guest sign-in; paywall placements; decline offer
- [x] Trial-ending reminder: push 2 days before + in-app notice + Settings line ([docs/trial-reminder.md](trial-reminder.md)); needs the APNs key to send

## Phase 9: Analytics & errors — ⚠️ built locally ([docs/analytics.md](analytics.md))
- [x] `POST /events` → Queue → Tinybird Events API; server events for onboarding, verified billing, restore outcomes, features, errors
- [x] Dedup ids (one trial per subscription, V1 = V2), sandbox flag, person id kept across guest → account link, no profile or reading data
- [x] Tinybird data source + endpoints: funnel (with denominators), installs, revenue, restores, errors
- [x] Tinybird workspace `hercrown` (us-east): data source + 7 endpoints deployed (deployment #1, 2026-11-04), tokens `hercrown_append` (server) / `hercrown_read` (alerts) on staging; staging events verified arriving; all endpoints return
- [x] Staging analytics intake accepts all 40 events emitted by iOS (2026-11-05). Verified the live endpoint accepted the full batch and rejected a client-supplied verified billing event. The test suite checks the Swift event inventory and strips private props.
- [ ] Staging run-through from the iOS app: every funnel event and a thrown test error appear in Tinybird
- [ ] Cron alert on error / webhook-failure spikes
- [ ] iOS: headers, on-disk event queue, Superwall delegate → paywall events

## Next, in order
1. ~~Restore Purchases~~ ✅ (local)
2. ~~Offline BSB and WEB~~ ✅ (local; words of Jesus + psalm titles too). CPDV pending a decision ([0005](decisions/0005-offline-translations.md))
3. ~~Tinybird analytics~~ ✅ (local; needs a Tinybird workspace to deploy)
4. ~~Trial-ending reminder~~ ✅ (local; push needs the APNs key + a phone)
5. ~~AI study tools~~ ✅ (staging; owner review of the eval report pending)

## Gaps found in the competitor recording ([walkthrough](research/scroll-the-bible-walkthrough.md)) — ✅ server side built (2026-11-03)
- [x] Notes per verse (auto-saved, newest wins across devices) and "Your library" (saved verses, notes, saved studies, studied)
- [x] Bible progress: chapters completed of 1,189; days opened vs days read; weeks in a row; days this year; devotionals read
- [x] Verse of the Day (122-verse rotation), random verse, widget verse; Discover by theme / For you / plan (72 cards + reflections)
- [x] Today's Devotional: 29 approved by owner + cofounder and live on staging; Luke 1:45 awaits review ([docs/content.md](content.md))
- [x] Preferences: font size (4 steps), Words of Jesus in red, system theme, reading translation, bookmark (position)
- [x] Email sign-in (6-digit code via Cloudflare Email Service) — off until the domain is set up
- [x] Contact & Support: stored with a reference, emailed to the team inbox; legal pages served at /legal/*
- [x] API reference for the iOS app: [docs/api.md](api.md)
- [x] Name: Her Crown ([decision 0009](decisions/0009-name-her-crown.md)); support/alerts inbox macnatephil@gmail.com
- [x] Hourly alerts: error spikes, AI spend, unmatched purchases → email
- [ ] **[HUMAN]** Domain → Cloudflare Email Service → set `EMAIL_FROM`; fill company name/address/governing law in legal drafts + legal review; optional AI Gateway + `TINYBIRD_READ_TOKEN`
- [ ] App Tracking Transparency prompt for ad attribution (marketing decision, iOS)

## Phases 10–14 — not started

## 2026-11-05 staging and TestFlight

- Staging Worker deployed from clean commit `1634e9c34e264ddc7ca4aece14b836e770aa2982`. Cloudflare version `db5dd379-09e2-4073-92ac-a79c9694674b`.
- iOS 1.0 build 2 archived from the same clean commit and uploaded to App Store Connect. Apple build ID `df65a5ac-559e-4753-a831-5eb37fc3d13c`. All 168 API tests passed.
- [Staging study eval](evals/study-2026-11-05.md) passed 45/52 automatic checks (Explain Easier 26/26, Deeper Study v2 19/26). The same 26 Deeper Study passages averaged $0.000604 per stored answer in v2, up from $0.000335 in v1. Review the seven flagged v2 answers before launch.
- [ ] On build 2, test onboarding paywall → decline → $19.99 offer → purchase → Plus unlock → reinstall and restore.
- [ ] Test trial return separately by turning off auto-renew during an active sandbox trial and reopening the app. The offer stays staging-only pending a launch decision.

## Open owner decisions
- Licenses for the 10 online translations (NLT, NLTCE, AMP, NASB, NASB95, NKJV, CSB, CEV, GNT, NIV) — [decisions/0004](decisions/0004-scripture-sources.md)
- API.Bible caching terms (ask support@api.bible)
- Community tab direction ([later.md](later.md))
- Final bundle id (placeholder `com.hercrown.app`)

- Before launch, decide whether to enable either delayed offer and how long to wait. Keep the legacy Superwall `paywall_decline` placement paused. Switch the Main audience only after the production launch decision.
- Superwall: Main and Decline offer use the rebuilt template paywalls (289087 and 289090), published to sandbox-only audiences on 2026-11-05. Verified both published previews and their purchase actions in the editor. The catalog metadata warning and on-device sandbox checkout are still open. The legacy Decline placement is now paused; see the build 3 notes below.

## Sandbox return offer and Deeper Study v4

- The legacy Superwall `paywall_decline` placement is paused. Apple’s US catalog lists $19.99 upfront for the first year of `hercrown.plus.yearly.offer`, renewing at $29.99/year.
- Staging migration `0011_return_offers.sql` is applied. Worker source `aa7a87d6b458cf4fe88fced45712bd62e9113a65`, Cloudflare version `be252e65-b917-4ff0-8fce-52238dcd5d16`. A staging guest decline recorded successfully and did not immediately reserve an offer.
- [Deeper Study v4 eval](evals/study-2026-11-05-v4.md): 25/26 (96.2%), up from 19/26 in v2 and 23/26 in v3. 26 fresh answers, $0.016554 total / $0.000637 average. Explain Easier passed 26/26 from cache. Ephesians 5:22 still has a wording flag. 174 API tests passed.
- iOS 1.0 build 3 archived from `bef0213efe9171edf0ef65901ff160c62507017e`. Offer preview checked on iPhone 17 Pro in light and dark. Uploaded through Xcode Organizer and verified in App Store Connect (build ID `a1599f25-54fd-420c-8680-6a2f76b94567`).
- [ ] On build 3, use an intro-eligible US sandbox tester: decline Main, confirm the reader opens, background the app, wait two minutes, reopen, then check that dismissing the offer suppresses it for 24 hours. Verify purchase and restore separately.
- [ ] Test `trial_return_1999` on a still-active annual sandbox trial with auto-renew off. Both return paths remain staging/sandbox only pending a launch decision.

## Fresh onboarding for internal testing

- iOS 1.0 build 4 archived from `30f612ce865234606680507c30af0d18636168a4` and verified in internal TestFlight (build ID `ca46b665-9692-46a7-a50a-5d0db27f6241`). **Settings → Sandbox testing → Start fresh onboarding** opens onboarding with a separate staging guest. **Return to previous account** restores the prior Her Crown session and its local reading state. Apple sandbox purchase eligibility is separate.
- The simulator build and all 174 API tests passed. The Settings entry was checked on the iPhone 17 Pro simulator. Full purchase and offer verification still requires a physical iPhone with an eligible sandbox tester.

## Subscription reconciliation and release audit

- iOS 1.0 build 5 archived from `9ede6d75d71813894b487c1a39e1e13c4e8321f7` and uploaded to internal TestFlight (build upload ID `bbefe907-cf36-40a7-9ae7-d644f92f9dd9`). A verified active Apple subscription now leads to an explicit restore action instead of a new checkout when the current Her Crown account is Free. Restoring may transfer Plus from a different Her Crown account, so it requires the user to act.
- Simulator build and all 174 API tests passed. Checked the Free subscription screen on iPhone 17 Pro. The Apple-active / Her-Crown-Free path and a completed sandbox purchase and restore still need verification on a physical iPhone.
- App Store Connect, 2026-11-05: build 5 is valid and assigned to the Team internal TestFlight group. App Store Connect showed build 5 installed under the owner’s tester account. App Store version 1.0 remains Prepare for Submission with build 1 selected and six iPhone listing screenshots.
- Saved the private App Review contact and notes for 1.0 and review notes for all three subscriptions. Drafted the App Privacy label for review against the release build. Apple accepted the three private review screenshots. The annual and weekly plans have U.S. storefront availability and show Ready to Submit. The $19.99 fallback product remains staging-only and shows Missing Metadata because no storefront availability is configured for it.
- Apple shows the Paid Apps Agreement, bank account and tax form as Active. The weekly plan currently has a one-week introductory trial in Apple’s U.S. catalog, while the main paywall describes weekly billing without a trial. Reconcile these before submission.
- iOS 1.0 build 6 archived from `3ac063c` and verified valid in the Team internal TestFlight group (build ID `cb879b82-92c4-45d0-8b40-b7dc356563f6`). A build 5 crash report showed a SwiftUI environment assertion during return to the original account. Settings now stays attached to the root during account switches. The simulator build launched and all 174 API tests passed. The StoreKit sign-in prompt prevented a full simulator round trip. Retest the account switch and fallback on iPhone.
- Before submission: set up the production Worker and purchase notifications, configure and select a production release build, publish the reviewed privacy label, and reconcile the weekly trial. Keep both return paths in staging pending a launch decision.
