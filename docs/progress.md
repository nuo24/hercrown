# Progress

- Discover layout follow-up: tightened featured and list spacing, narrowed list titles, and restored the Reflection label beside the verse reference where a prompt exists. Verified the layout in the iPhone simulator. Build and API checks passed (202 tests).

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
- [x] **[HUMAN]** Approved the Ephesians 5:22 Deeper Study answer on 2026-11-06. The automatic wording flag remains in the [v4 eval](evals/study-2026-11-05-v4.md).
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

## Paywall dismissal and cancellation follow-up

- Build 7 (`2a6512a`) saves a pending paywall dismissal per profile and retries it when the app returns to the foreground. The existing two-minute staging delay and rolling 24-hour limit still apply. The annual promotional offer can now be considered after Apple verifies cancellation of a trial or paid plan, including subscriptions that expired after auto-renew was turned off. The backend excludes revocations and billing-related expirations.
- Internal TestFlight build 7 uploaded successfully (Apple upload ID `c000bacf-d81e-40bd-b42d-b2cb9b2c9225`).
- Staging Worker deployed from `2a6512a`, version `f25c019f-2d72-416c-b985-c0612d4c0df3`. Typecheck and 175 tests passed. The iOS simulator build ran; the Apple sign-in dialog prevented a full visual check. The Free reading value now uses the standard plan row and the butterfly illustration remains in the header.
- Apple has the annual `trial_return_1999` promotional offer configured. The separate $19.99 introductory product still has no storefront availability. Verify both paths on a physical iPhone before relying on them. Do not include the separate product in a public submission without a launch decision.
- Follow-up on November 5, 2026: verified U.S.-only availability on the separate draft $19.99 product after the owner authorized sandbox testing. The first release remains scoped to annual and weekly. Production is the next priority: its public health check returned HTTP 404, Wrangler still has production D1 and KV placeholders, and the app points at staging. See [the owner-run production checklist](production-deploy.md).

- Internal TestFlight build 8 archived from clean source `4ac126ef05ae8f4296aff17e7f1aed1f195b77c1` and uploaded to Apple (upload ID `fc0f9ed6-2675-45e6-bced-fd257596538f`). Fresh sandbox onboarding routes Start reading to Superwall again even if the Apple account has an active purchase. Regular onboarding retains the restore prompt. Typecheck and all 175 API tests passed. Verify paywall presentation on a physical iPhone.

## Version 1.0 launch checklist

- [x] Owner changed version 1.0 to automatic release after approval on November 10; Apple API verified `AFTER_APPROVAL`. Submission remains paused until final asset approval. This supersedes the earlier manual-release decision.
- [x] App Store Connect weekly plan has no introductory offer in any territory and is Ready to Submit. Yearly retains its 7-day trial for eligible subscribers. Superwall Main publishes the matching weekly disclosure.
- [x] App Store Connect age rating is 4+ and the third-party content rights declaration is saved.
- [x] Both $19.99 return offers are off for version 1.0. The app requires a sandbox receipt, the Worker endpoints require staging, and Superwall's legacy `paywall_decline` placement is paused. Exclude the separate $19.99 product from the 1.0 submission.
- [x] App Privacy published in App Store Connect on 2026-11-06. The label covers country-level analytics and device IDs used for analytics and notifications. Switch the privacy policy URL to production after the Worker is live.
- [x] Provisioned production D1, KV, R2 and the events queue on 2026-11-06. Production bindings are recorded in `apps/api/wrangler.jsonc`.
- [x] Owner applied all 11 production D1 migrations and seeded KJV, BSB, WEB, all four study datasets and 29 approved devotionals. Wrangler confirmed the initial production Worker secrets, including both Sign in with Apple settings.
- [x] Owner deployed the production Worker on 2026-11-06 (version `af0c194b-8287-4c12-ad5a-b62675f18081`). Health, privacy, terms and support returned HTTP 200.
- [x] Created the production Superwall V2 webhook at `/webhooks/superwall`.
- [x] Owner uploaded the production Superwall signing secret. The endpoint returned `401 invalid_signature` for an unsigned request.
- [x] Production Tinybird aggregate verification on November 10 found server-only verified billing events and sandbox restore completion; earlier no-delivery status is superseded. Superwall V2 does not send synthetic test events.
- [x] Release now points at production and uses its legal and support URLs. The production build disables sandbox testing and both return offers.
- [ ] Verify first-run onboarding on an iPhone that has never had Her Crown installed. The Sandbox testing menu is hidden in production builds. Complete the production smoke checks.
- [x] Owner confirmed production-connected TestFlight purchase → Plus unlock → restore; verified billing/restore aggregates seen in production Tinybird. TestFlight purchases are flagged sandbox. Public App Store checkout remains a separate post-release test.
- [x] November 10: Superwall Main active in production for users without active entitlements, allocation 100%, holdout 0%; decline placement remains paused. Automatic release requires checkout ready before approval.
- [ ] Production checkout and restore from the public App Store build. Verify the entitlement and purchase event on the production backend.

## November 6 design handoff

- Ported the new native Home, Discover, Community, reader chrome, dock, streak detail, app icons, and eight onboarding pages from `her-crown-full-handoff-2026-11-06.zip` onto the current release branch. Imported the supplied artwork, glyphs and DM Sans. Reader bookmarks now live on the device by Her Crown account, separately from the existing synced Saved passages.
- Ported the onboarding artwork reveals, headline timing, and light haptic feedback, plus the crown growth and flower animation for subsequent cold launches. The crown uses the supplied composited artwork. The archive did not include the layered illustration master.
- Built and ran the app on an iPhone 17 Pro simulator and installed and launched a signed staging Debug build on Nathan’s iPhone 2 (iPhone 14 Pro). Visually checked the four tabs in light and dark, the eight onboarding layouts, and the cold-launch animation in the simulator. Typecheck and all 175 API tests passed.
- [ ] Review the onboarding haptics and cold-launch transitions on hardware. Compare secondary Settings and study sheets against the handoff before calling the design pass complete.
- [ ] Polish the Main paywall separately using the approved launch prices and trial terms, then archive a clean TestFlight candidate and complete checkout, restore, and the launch sweep.
- Follow-up on November 6: the dock now uses the four silhouettes embedded in the handoff preview. Explain Easier and Deeper Study use the handoff’s centered Scripture header and expandable source list with live, validated study content. Installed the signed Debug build on iPhone 2 and checked the dock in the simulator.
- Reproduced the Psalm 90:12 Deeper Study failure on staging. A bracketed word in the Hebrew gloss collided with the citation syntax. Staging deploy `3a909313-bea9-4cc5-a53c-6b5cf858e225` from `39d203e` returned a validated answer for the verse. The temporary staging Plus account was removed. Typecheck and all 177 API tests passed.

## Bookmarks, Notes, and Plus pricing follow-up

- Source `3ddc6bc` updates the Bookmarks and Notes empty states and simplifies the native $19.99 offer. Installed the staging Debug build on iPhone 2 and previewed the offer in the simulator. Typecheck and all 177 API tests passed. The staging Worker with monthly entitlement support is version `d674dd71-6610-425d-a2e1-79a039cc201c`.
- Superwall Main has a saved draft with $39.99/year, a 7-day trial for eligible accounts, and $5.99/month without a trial. Verified the light and dark previews and switched between plans in the editor. The published Main still uses annual and weekly. Before publishing the new draft, verify the monthly product is ready in Apple’s catalog and have the owner deploy monthly entitlement support to production. Apple processed the private monthly review screenshot and still shows Missing Metadata.
- Archived TestFlight build 8 points at staging. Its reset menu needs a loaded Her Crown session and a verified Apple sandbox app transaction. Current Release builds point to production and hide the reset menu. The $19.99 return offers remain sandbox/staging only. Delayed presentation and checkout still need an on-device test.
- Matched the chapter picker and native decline offer to the latest handoff screenshots (`d45c308`, `c214096`). Checked the picker and both offer appearances in the simulator. The Superwall Main draft now uses the requested right-aligned weekly equivalents with the actual yearly and monthly charges under the plan names. Verified the plan selection and trial eligibility states in the editor. The draft remains unpublished. Before release, reconcile its price emphasis with Apple's guidance, verify monthly catalog readiness, and exercise checkout, restore and the delayed offer on a physical iPhone.
- Reduced the Main draft's secondary pricing labels and the native offer disclosure. Rechecked the draft's product order after finding the legacy weekly reference in slot two. The editor now lists annual first and monthly second. Apple still reports Missing Metadata for monthly despite a complete review image, English localization, $5.99 US pricing and US availability. Monthly has one price record versus 175 on the ready weekly product. This is a diagnostic lead. The reason for Apple's status still needs confirmation before publishing the draft or uploading a new build.
- Inspected the signed-in App Store Connect dashboard on November 6. Both Monthly and Weekly show Prepare for Submission with Add for Review enabled, even though the API reports Monthly as `MISSING_METADATA` and Weekly as `READY_TO_SUBMIT`. Verified Monthly's $5.99 US price, one-territory availability, localization and review screenshot. Saved precise reviewer instructions and rechecked the API. The discrepancy persists. Superwall also reports `MISSING_METADATA`. Ask Apple to identify the failed field if sandbox StoreKit cannot load the product or App Store Connect rejects attaching it to 1.0.
- On November 6, Apple reported Monthly `READY_TO_SUBMIT` after the owner saved all 175 price records. Sales availability remained US-only. A temporary diagnostic built from `5d77e10` plus a local debug-only screen on iPhone 2 loaded `hercrown.plus.monthly` at $5.99 in the US with no introductory offer. Apple displayed an existing Monthly sandbox subscription, while StoreKit returned a verified Yearly transaction and the regular restore restored Yearly on staging. Monthly purchase and Monthly restore still need a clean US sandbox tester. Typecheck and all 177 tests passed.
- The owner-deployed production Worker version `2492147a-dce3-4d05-b311-c29636298b09` serves 100% of traffic and includes `hercrown.plus.monthly` in `PLUS_PRODUCT_IDS`. Health and all three public legal pages returned 200. The deployment log did not identify a source commit.
- On November 6, iPhone 2 passed the U.S. Monthly StoreKit purchase and Restore Purchases on a fresh staging profile. The diagnostic verified Apple's sandbox transaction for `hercrown.plus.monthly`, staging granted the matching Plus entitlement, and the restore returned “Welcome back to Plus” with the same Monthly product ID. This test called StoreKit directly. Checkout through the new Superwall Main paywall still needs verification.
- On November 6, published Main revision 9 to the audience for unsubscribed sandbox users. It keeps Yearly and Monthly and removes the duplicate close glyph. Verified the remaining close action and both annual price states in the editor. The trial preview shows $0.00 with the $39.99 annual renewal below the plan name. The paid Yearly preview shows $39.99 due at confirmation. The eligible trial layout and Monthly checkout still need verification on an iPhone.
- Archived internal TestFlight build 9 from clean source `4b872252e3c6c3a121b08eb2c529821b56ee8508` and uploaded it to Apple on November 6. The `HC_STAGING_TESTFLIGHT` compilation condition points the archive to staging and uses Apple sandbox checkout through Superwall. Verified the version and staging URL in the archive. Typecheck and all 177 tests passed.
- Updated the native Subscription layout with a Free reading heading, primary Explore Plus button, and purchase rows. Verified the screen in light and dark in the iPhone simulator. The onboarding paywall requests light appearance. Other placements follow the app appearance preference, with System delegated to iOS. Verified both Superwall palettes in its editor and the onboarding rule in the local handoff preview. The native paywall appearance still needs an iPhone check.
- Archived and uploaded internal TestFlight build 10 from clean source `f2bb6e2b4735d9f0140008e576e4d352d91a94e5` on November 6. App Store Connect shows build `877d2192-4574-4477-9463-46adacc42b4b` as valid and available to Team. It uses staging and includes the Subscription and paywall appearance changes. Check onboarding on a physical iPhone before cutting the production archive.
- Matched the native Your account screen to the handoff: outlined photo controls and profile fields, a filled Save button, a shield row leading to Apple sign-in, and a separate Delete account button. Verified the guest screen in light and dark on the iPhone simulator. Typecheck and all 177 API tests passed. This change was made after build 10.
- Rechecked Main against the published Superwall runtime and Apple’s U.S. catalog. Annual is configured for a seven-day introductory free trial and a $39.99 annual price; Superwall uses automatic eligibility and publishes both the trial and immediate-charge layouts. The owner's build 10 screenshot showed the paid layout. Validate the trial branch and Apple checkout on an unused U.S. sandbox tester before release.
- Archived internal TestFlight build 11 from clean source `338bcda5d47584d2c3f0a8013e4bbd41d61abbaf` and uploaded it on November 6 (Apple build ID `424cbc13-fada-486d-aa39-53a63159cad9`). App Store Connect verified the build as valid and available to Team. This staging build includes the Account UI, loads Superwall paywalls at presentation, and adds **Settings → Sandbox testing → Check yearly trial** to compare StoreKit’s current offer and eligibility with Superwall’s most recent presentation. Typecheck and all 177 API tests passed. The simulator launched but prompted for an Apple account. The eligible trial still needs verification on a physical iPhone.

## November 6 Discover and feedback follow-up

- Discover now uses editorial headings for every one of the 72 configured passages, with small references below. The nine handoff titles remain the visual source, including “A softer place to land”; additional passages have new editorial copy for owner review. Scripture text stays unchanged. The pinned filters have an opaque background (neutral gray in dark appearance) and the feed is clipped to its viewport.
- Added Settings → Suggestions & bugs with feature/bug categories, a defined message field, submission errors, ticket references and the sender's report history. It uses the existing authenticated support API and D1 table. Email delivery remains unconfigured. `node scripts/export-feedback.mjs staging /tmp/hercrown-feedback-staging.csv` exports a spreadsheet-compatible ticket file from `apps/api`. Verified the export against staging without logging message contents.
- Added Create a snapshot to the existing share controls in the reader, Home verse, Discover passage and Saved passages. The preview renders the already-loaded Bible text, reference and translation over the app's light sage/sky palette. Free snapshots carry a Her Crown watermark; server-verified Plus members can turn it off. Text sharing remains available. Snapshot preview opens emit `verse_snapshot_opened`, without passage text or reference.
- Added an extra upward swipe at the end of a chapter to schedule the next chapter after a 450 ms pause, with a 700 ms transition. It cancels if the reader moves away or changes passages. Reduce Motion removes the transition. The end-of-chapter tap control remains available. The owner confirmed the extra upward swipe followed by the gentle transition.
- Debug iOS build and all 177 API tests passed. Captured and inspected Discover in light/dark, the feedback form and the snapshot preview in Simulator. Interactive scrolling, keyboard submission, snapshot sharing/watermark controls and the chapter gesture still need a device check in TestFlight build 12.
- Offer timing remains at the current staging-only 20 minutes for testing. The owner confirmed that a partner saw the delayed offer. Production 1.0 offers remain off. Timing for free readers and canceled subscribers is pending a product decision. Achievements are parked for V2 in `docs/later.md`.
- Deployed clean source `86808df` from an isolated checkout to staging, Cloudflare version `22417442-0ba0-45ca-af9a-5b4183d93880`. Health returned `env=staging`; `/events` accepted the new snapshot event. Verified both ticket categories through live staging POST/GET on a disposable guest, then removed that guest and its tickets. Also inspected the feedback form in dark appearance. Production deployment and a new TestFlight archive are still pending.

- Archived and uploaded internal TestFlight **1.0 (12)** from clean isolated source `3613884161d52f4b144e105b8b663248df22f8cb` using `HC_STAGING_TESTFLIGHT` on November 6. Apple build ID `b576fa6b-f3e0-4f85-aaee-d04999fdeb1a`; verified `VALID`, Team membership, `IN_BETA_TESTING`, automatic notifications enabled, and saved English testing notes. App and widget both use build 12. This build points to staging; staging backend remains clean source `86808df`, Cloudflare version `22417442-0ba0-45ca-af9a-5b4183d93880`. Typecheck and all 177 tests passed before archive. Includes Discover titles/filter clipping, feedback tickets, verse snapshots, and the owner-approved extra-swipe chapter transition. Hardware interaction checks listed above remain pending; production and App Store release were not changed.

## November 7 direct study paywall

- Removed the study upsell → Subscription → paywall detour. Explain Easier, Deeper Study, Original Language and Related Verses now request their existing `study_*` placement directly for free accounts, including entries from Discover and Saved. No pricing, campaign audience or server entitlement changes.
- Added a presentation completion callback: purchase/restore completes the existing server verification before the study reloads; decline, skip or presentation error dismisses the locked study to its previous screen. Existing Apple purchases retain the restore-account safeguard.
- Debug simulator build succeeded; `npm run check && npm test` passed all 177 tests. Launched the study flow in the iPhone 17 Pro simulator; Apple's sign-in prompt blocked live paywall verification. On-device purchase → selected study and close → previous screen checks remain pending. This source change is newer than TestFlight build 12 and has not been uploaded yet.

- November 7: internal TestFlight **1.0 (13)** archived from clean isolated source `fa4f4e60543d227ac41eb93dc4de01931cae8af3`; Apple build ID `1e9258bf-f135-46b1-a721-1dff28c564a2`. Verified `VALID`, Team availability, `IN_BETA_TESTING`, and saved testing notes. This staging build includes direct study paywall navigation (`a2e0aee`) and all build 12 changes. Checks and all 177 tests passed. On-device purchase/restore continuation still needs verification.

## November 7 Reflection layout correction

- Matched the supplied Discover Reflection reference: plain Back left / Done right, left-aligned Reflection heading, supplied `intention-heart` illustration above the centered reference and Scripture, full translation label, separated reflection prompt, and a defined notes field. Discover notes now include the reflection prompt; they still open notes rather than study tools. Moved Discover's study-sheet Done control to the right as well.
- Retained automatic note focus and existing save/server behavior. Keyboard layouts use a compact illustration/type layout and a 104 pt editor; longer passages can scroll rather than truncate Scripture. Full-height layouts use a 24 pt serif passage and 180 pt editor. Debug-only review flag `hcPreviewReflectionNoKeyboard` allows full-height screenshot inspection without changing normal focus behavior.
- Built and launched the simulator. Inspected light/dark full-height screens and dark keyboard layout with Proverbs 31:25 from the bundled KJV. Verified reference, verse, reflection prompt/label and notes remain visible with the keyboard for this passage. Very long passages use the scroll fallback and still need device review. Typecheck and all 177 tests passed. Newer than build 13.

## November 7 continuous reader and app tutorial

- Replaced the 450 ms overscroll delay plus whole-ScrollView push transition with a continuous paged feed containing neighbouring chapters. Verse pages have canonical reference IDs; crossing a chapter updates the toolbar/rail and extends the feed without replacing existing pages. Swiping down naturally returns to the preceding chapter; book boundaries and Bible start/end are respected. The accessible Next button uses the same scroll target.
- Added a four-page, skippable tutorial to both first-reading onboarding paths, plus Settings → How Her Crown works replay. Uses supplied illustrations/glyphs, bundled Scripture and existing design fonts. Reading remains free; tutorial completion follows the selected onboarding/guest path and cannot grant Plus. Added privacy-safe `tutorial_step` / `tutorial_finished` analytics to the API allowlist and docs.
- Rechecked existing return-offer tests: first eligibility at 20 minutes after decline, one atomic impression per rolling 24 hours, active subscribers excluded from the decline path, and offer endpoints unavailable outside staging. Updated the older decision's stale two-minute wording to 20 minutes. No offer prices, campaign settings or production eligibility changed.
- Validation: `npm run check && npm test` passed all 177 API tests; all 7 native XCTest cases passed, including new chapter-window tests for extending forwards/backwards without changing existing page IDs, book boundaries and BSB's omitted verse numbering. Built and launched the app; inspected the reader at Genesis 1:31 plus tutorial light/dark screenshots. Native computer control cannot access a Simulator app even after the Mac was unlocked, so physical swipe feel, tutorial taps/skip and post-tour paywall still need on-device review. These changes and the Reflection layout correction are newer than TestFlight build 13.

- Deployed clean source `f061c5b` to staging only, Cloudflare version `448206ce-9a9f-4645-9a72-503ad28d9567`. Verified `/health` returns 200 with `env=staging`; a tutorial page/completion event smoke returned 202 with 2 accepted and no rejected events. Production must receive the analytics allowlist via a human-approved deploy before the tutorial ships there.

- Archived internal TestFlight **1.0 (14)** from clean isolated source `286c880fdf4ab24fdeb65aca2292bfc31b138008` using `HC_STAGING_TESTFLIGHT`. Apple build ID `2c59a200-d59f-455d-a392-6253ebb7db2b`; verified `VALID`, Team availability, `IN_BETA_TESTING`, automatic notifications enabled and English test notes saved. App/widget both use build 14. Includes the Reflection correction, continuous reader, short tutorial and build 13's direct study paywall fix. Staging backend is version `448206ce-9a9f-4645-9a72-503ad28d9567` from `f061c5b`. Phone checks remain: swipe feel both directions/book boundaries, chapter picker/translation/bookmarks after swiping, tour Continue/Back/Skip on both onboarding paths, post-tour paywall, and notes with longer passages. Production was not deployed or enabled for return offers.

## November 7 Discover backdrop and return-offer invitation

- Discover's pinned filter header now uses the opaque page canvas in both appearances: black in dark mode and white in light mode, replacing the gray dark-mode strip. Existing clipping and filter behavior are unchanged. Inspected the running dark Discover screen; Apple’s simulator sign-in prompt blocked the interactive pinned-scroll check.
- Added a two-stage native return-offer presentation using the existing `prayer-envelope` illustration and Baskerville/DM Sans: an invitation with explicit reveal and free-reading controls, followed by the existing product/terms/purchase screen. Back returns to the invitation; Done/free reading close. The crossfade respects Reduce Motion. Existing presentation/impression analytics and purchase callbacks remain in place. No price, eligibility, delay, frequency or production offer settings changed. The separate parked offer product still has its existing renewal terms; reconcile these before enabling production offers.
- Debug simulator build succeeded; `npm run check && npm test` passed all 177 tests. Inspected invitation light/dark screenshots. The revealed offer was launched using the DEBUG-only `--preview-return-offer-revealed` switch, but Apple's sign-in modal obscured its center. Reveal/Back/Close taps, large text and the complete purchase flow still need a hardware check. No archive or deployment made.
- Next: replace the current illustrated tutorial with original short recordings of Her Crown's reader navigation, save/note controls, passage insights and Discover/Home flow. The competitor recording confirms moving feature demonstrations and an immediate $29.99 offer in that session; it does not prove their repeat cadence or explain their earlier $19.99 offer. No competitor footage will ship. Capture clean app footage before wiring playback; current tutorials remain illustrated slides.

## November 7 external TestFlight distribution

- Apple reports build 14 as `INTERNAL_ONLY`, which cannot be assigned to external groups. At the owner's request to update external Beta testers to build 14's app, archived the exact same clean source `286c880fdf4ab24fdeb65aca2292bfc31b138008` as **1.0 (15)** using the explicit archive override `CURRENT_PROJECT_VERSION=15` and `HC_STAGING_TESTFLIGHT`. Verified both app/widget build numbers and the staging endpoint in the archived executable. No additional feature changes from after build 14 are in this archive.
- Uploaded with `testFlightInternalTestingOnly=false`. Apple build ID `a3351430-a2f3-48ef-826d-e0bfad3760de` is `VALID` and `APP_STORE_ELIGIBLE`. Assigned to existing external group **Beta** (`20c28d43-2861-4a95-a0be-dc4cc303e4af`); English testing notes copied from build 14 with the replacement build number and external-distribution explanation.
- Submitted Beta App Review; Apple reports review `APPROVED` and external state `BETA_APPROVED`. Automatic tester notifications are enabled (Apple also confirmed this when a manual notification returned “Auto-notify already enabled”). Existing public invite remains https://testflight.apple.com/join/cK478Yxy. External installation/update propagation still needs a tester check. Internal Team retains access. No App Store release submission, production deployment or production data changes.
- `npm run check && npm test` passed all 177 tests. Archive and upload succeeded. Next upload must use build **16 or higher**; the source project still records 14 because build 15 was an explicit archive setting override, preserving the requested build 14 feature source.

## November 8 final handoff — implementation and test build

- Imported the November 8 partner reference and illustration catalog. New 14-screen onboarding replaces the old flow and appended reader tour; supplied demonstration video is bundled natively. Back/Skip/guest behavior retained; optional personal questions do not block free reading.
- Server-only personal prayer uses existing OpenRouter/DeepSeek: fixed-choice context plus optional text, no quotation-wrapped raw input, validation before display, no raw-input persistence/analytics, three attempts per user/day, Retry/simple-prayer recovery. A provider/use disclosure and simple-prayer alternative precede generation. Prayer is saved locally per account and supports hold-to-hear with slow soft haptics. Reduce Motion/background/exit stop feedback. Physical feel remains an owner test.
- Community gallery retains Her Safe Place, Open Doors for Girls, The Motherhood Fund and Grace Church Pantry with supplied photos. Owner confirms $7,350 completed donations and 30% of revenue to donations. Staging ballot and private nomination/editing endpoints replace prototype local storage, with one member/month vote, confirmed changes, retry deduplication and account-linking support. No fixture vote counts or payment actions. The handoff calls these fictional profiles: preserve preview labeling and keep the ballot out of production until recipient identities/grant allocation are confirmed.
- API migrations 0012–0013 added; no new vendors or secrets. All 187 API tests and the first 10 native XCTest cases passed. Native life-season screen was launched and inspected. Final build/deployment identifiers and on-device review status will follow below.
- [ ] Before production: reconcile reported giving with financial records and approve real recipients/funding rules; review/publish App Privacy changes for optional personal-prayer context and private Community nominations. Production was not deployed by this work.
- First live staging prayer check returned 3/5 validated results: two ordinary inputs were rejected. Exact-path synthetic provider diagnostics then returned valid prayers, confirming a nondeterministic validation/repetition issue. Added one internal repair attempt (each call logs its own cost), and stopped rejecting naturally named groups of loved ones. Retesting before distribution. Community photo rows also aligned to the top after simulator inspection.
- Staging: applied 0012–0013 and deployed clean source `f76e1a32e35ff10e0fa895bebce01767b69feb6c`, version `3d818044-f229-4b2e-81d1-7c9a7c7cdf95`. After repair tests passed all **188** API cases, deployed clean source `148e2628a6769f24f425c0371cef6006f97ec1fa`, version `f249e89b-b411-4f64-9ff3-c7de68dd40b7`. Health/privacy/credits returned 200. Live repaired prayer check passed **5/5** synthetic cases in 817–1460 ms; reviewed samples in `docs/evals/prayer-2026-11-08.md`. Existing 10 native tests passed. Captured onboarding season, live Community and actual generated prayer in Simulator; corrected prayer to the reference's heading/art row for space and parity.
- Build **16** archived successfully (app and widget both 16, supplied demo video bundled, staging condition). Upload failed: Xcode account requires re-authentication; API-key fallback cannot use cloud-managed distribution certificates and no local distribution private key was available. Owner was asked to unlock Mac and re-authenticate Xcode → Settings → Apple Accounts. **Not yet in TestFlight.** Refresh final archive after the last prayer-heading correction, then upload and assign Team/Beta; do not present build 15 as this update.

- Final build 16 refreshed from clean source `fcd15cb` after prayer-heading correction: `/tmp/hercrown-build16-ready/HerCrown.xcarchive` (`ARCHIVE SUCCEEDED`; app build 16). Final generated-prayer layout inspected in Simulator. Upload remains blocked by the Apple account/cloud-signing errors above; no build 16 availability is claimed. Local partner reference preview verified HTTP 200 at http://127.0.0.1:8895/ios-preview.html.

- November 8, 18:53 EST: owner completed Xcode Apple Accounts sign-in; upload of final build **1.0 (16)** from clean source `fcd15cb02c13c8c7da7328be8c9502486fe10899` succeeded (`/tmp/hercrown-build16-ready-upload.log`, `EXPORT SUCCEEDED`). External-eligible export; Apple processing and Team/Beta assignment still pending at upload completion. This supersedes the account upload blocker above; no App Store release submission or production deploy.

- Build **1.0 (16)** processed `VALID` / `APP_STORE_ELIGIBLE`, Apple build ID `38aaf5a5-2504-4668-8161-4094871e07b4`. Updated English test notes, assigned external **Beta**, enabled automatic notifications, submitted Beta App Review and verified `APPROVED`. Apple reports both internal/external states `IN_BETA_TESTING`. Team group has access to all builds. Existing external invite: https://testflight.apple.com/join/cK478Yxy. Testers should update to 1.0 (16), then Settings → Sandbox testing → Start fresh onboarding; physical haptics, prayer playback and full flow remain tester checks. No production deployment or App Store release submission.

## November 8 build 16 feedback follow-up

- Rebuilt onboarding demo lifecycle around a retained AVQueuePlayer; explicit Play/Pause is available in Reduce Motion, backgrounding pauses it, and the first four seconds of the supplied recording loop instead of its long stationary ending. A native test verified the bundled recording's playhead advances.
- Hold-to-hear no longer stops when the long-press recognizes: it holds until release. Spoken-audio playback activates the audio session so the silent switch does not suppress it, with ducking, stop/release/background cleanup and an inline startup error. Slow reveal/haptic pacing retained. Physical audio and haptic feel still require a phone check.
- Personal prayers display as exactly two balanced paragraphs while preserving their words. Saved prayers and the simple fallback use the same formatter; provider prompt also requests two paragraphs and treats “my mom, Grace” as one person. No raw personal text added to logs.
- Community confirmation captures the selected cause value, waits for a story sheet to dismiss, bounds image/button hit regions and ignores stale account responses. The intermittent crossed-vote report was not reproduced interactively; verify rapid alternate taps on a phone.
- Discover Read & reflect opens the paywall directly for a free account, then opens Deeper Study after entitlement verification. Existing illustration mapping left intact after owner confirmed the normal feed is correct.
- Home's daily passage now rotates within the reader's selected topics (no topics = shared daily pool). Onboarding persists choices before completing; Home reloads when topics change and widgets refresh to the same selection. Biblical text remains sourced from the existing Bible repository.
- Devotional follows the reference's 20 pt UI title / centered 90 pt journal illustration; removed the AI banner, retained source attribution and “separate from Scripture”, reflection and context-reading action. Added passage sharing/Snapshot Studio entry. No devotional or Scripture text rewritten.
- Native Snapshot Studio replaces the fixed single-card share screen: portrait/square/story, gradient presets/custom colors/intensity/direction, local photo backgrounds/shade/focus, typeface/size/ink/alignment, 34 supplied illustrations (up to six layers), drag and position/size/rotation controls, duplicate/remove/bring forward, reset, per-account local draft, and native image sharing. Plus watermark removal uses verified membership. Export tests caught and fixed Story's fractional-size rounding; final PNG canvases are exactly 1080×1440, 1080×1080 and 1080×1920. User-selected photos stay on device and are removed with the account's local draft.
- `npm run check && npm test`: all 189 API tests pass. Native tests: 13 pass, including actual demo playback, two-paragraph word preservation and all three PNG sizes. Simulator Snapshot Studio inspected; staging deployment/build identifiers follow after final packaging. Widget Studio redesign and licensed translations remain parked in docs/later.md. No new dependency/vendor, license purchase or production deployment.

- Packaged follow-up source `fef92f2` from the clean isolated checkout. Staging deployed version `2bce0451-bdd3-453d-a484-2b3b9de969d5`; `/health` returned 200/staging. Disposable synthetic guest smoke verified topic=Peace, matching widget reference, nonempty bundled passage and 200 personal prayer with two paragraphs / 94 words; guest deleted afterwards.
- Final Debug build passed; inspected looping demo and devotional screenshots plus Snapshot Studio text tools. Build **17** archive succeeded at `/tmp/hercrown-build17/HerCrown.xcarchive`, source `fef92f2` (app build 17). Upload returned `Failed to Use Accounts` / team `494RZLCNHQ`; computer tool confirmed Mac locked. Requested unlock before retry. **Build 17 is not yet uploaded; TestFlight remains on 16.**

- November 8: unlock alone did not resolve CLI export's account lookup. Xcode UI showed Nathan Okolo signed in with the Admin team; opened the existing clean-source build 17 archive in Organizer and distributed via App Store Connect. Xcode confirmed **HerCrown 1.0 (17) uploaded**. Apple processing/assignment pending at upload completion. This supersedes the locked-Mac upload blocker; no rebuild, new certificate, App Store release submission or production deploy.

- Build **1.0 (17)** is processed `VALID` / `APP_STORE_ELIGIBLE`, Apple build ID `365ef74e-256c-4714-9d39-c6769a5972dd`. English feedback test notes updated; assigned external Beta group with automatic notifications. Beta review submitted and both internal/external states verified `IN_BETA_TESTING`. Internal Team has all-build access. Existing partner invite: https://testflight.apple.com/join/cK478Yxy. Owner should update to 17 and verify prayer audio, demo motion, rapid alternating votes and Snapshot Studio sharing on a phone. No production changes.

### November 8 evening: onboarding and Home sheet feedback sweep
- Replaced the old four-second onboarding loop with the owner's new full 12.56-second reader/Community/Home recording. Bundled silent H.264; cropped the recorded status bar. Typing now uses gentle 90 ms pulses (160 ms for the prayer), retaining the existing 48/40 ms text cadence and Reduce Motion behavior. The time-statistic phrase uses the supplied preview's rose-red `#A94F75`.
- Owner requested removal of text to speech: removed the prayer listening button, speech/audio lifecycle and browser-preview listening control. Prayer text, two paragraphs and paced haptics remain.
- Devotional metadata sits below its title; Scripture uses 20 pt serif instead of 28 pt. Plain Back/Done controls and 46 pt rectangular context button. Removed dashes from authored devotional prose/prompts only; references, Scripture and sources preserved. Revised seed pending staging import below.
- Shared red-letter renderer applies only verified bundled ranges to exactly matching passages, honoring the existing preference. Added to Home, Discover, Saved, reflection and study surfaces; unmatched online text stays untouched.
- Reading Plans now uses the supplied vertical illustrated catalogue, with journal hero, serif headings, small metadata and Explore plan cards. Details have numbered grouped rows and a Start with Plus action; browsing stays free. List-to-detail presentation waits for dismissal rather than presenting two sheets simultaneously. Empty plans no longer index into an empty steps array.
- Verification: `npm run check && npm test` passed (189 API tests); final native suite passed (13 tests, including actual demo playback). Simulator inspected plans in light/dark, plan detail, Matthew 11:28–30 red-letter devotional and prayer without speech controls. Screenshots `/tmp/hercrown-{plans,plans-dark,plan-detail,devotional}-sweep.png` and `/tmp/hercrown-prayer-no-speech.png`. Physical haptic feel and the intermittent tap-navigation behavior need owner device verification. No new archive/upload in this sweep; TestFlight remains build 17.
- Staging devotional seed imported from clean source `893bd88` into D1 `147a2d66-7f1e-452e-9532-5274b678486d` (bookmark `0000031c-00000036-0000511e-80e9c17782a3f3fe606e5556be26e8c3`). No Worker redeploy or production write; this is a content-only staging update.


### Nov 8: onboarding Scripture, Settings and Widget Studio sweep

- Added a parchment scroll card on the final onboarding page. A reviewed on-device passage selector prioritizes the typed concern, then loved ones/topics/prayer keywords; all displayed Scripture comes unchanged from the bundled KJV. No extra LLM call or new vendor. Save-a-copy remains available when a prayer has been generated.
- Home empty Notes opens the Bible reader. Read & reflect in Discover and Saved opens the insights menu for both free and Plus users. Locked study tools offer an explicit Explore Her Crown Plus action instead of the automatic Opening Plus spinner/dismissal. Normal Subscription Explore uses the same designed paywall in Debug and Release; dedicated sandbox testing remains separate.
- Settings now links to Saved passages (Verses / Notes / Studies / Studied, counts and illustrated cards) and Widget Studio after Appearance/App Icon. Topics use heart controls; Apple sign-in uses a checked shield; feedback heading is smaller; streak dismissal is an X. Free Subscription retains a wide contrasting Explore Her Crown Plus button even when Apple finds a purchase that has not been connected to the current profile.
- Widget Studio reuses the Snapshot Studio background/photo, typography, alignment and draggable illustration controls. Optional personal captions are separate from immutable Scripture. Save renders small/medium/large PNGs into the existing App Group and reloads WidgetKit; widget providers read those images. Drafts are per profile, refreshed with the widget passage, and active artwork is cleared on account change/deletion. No personal text or images enter analytics.
- Verification: npm run check and all 189 API tests passed. All 16 native tests passed, including curated passage selection, three-family rendering, backward-compatible draft decoding, shared-container publishing and account-change cleanup. Simulator inspected onboarding scroll, light topic hearts, dark Saved sections, dark Subscription CTA and Widget Studio. Screenshots: /tmp/hercrown-ready-scripture.png, /tmp/hercrown-heart-topics-light.png, /tmp/hercrown-saved-sections-dark.png, /tmp/hercrown-subscription-action-dark.png, /tmp/hercrown-widget-studio-dark.png.
- Owner device checks still needed: add each widget size and confirm saved designs refresh, edit/reopen a design, and exercise the free-user insights-to-paywall flow. These screenshots do not prove physical-device gestures or haptics. No new archive/upload in this sweep; TestFlight remains build 17. API.Bible/licensed translations remain parked.
- Staging Worker deployed from clean source `62cc73ad1c6d5505c0db7cf1d737b4caa975956e`: version `4efba76e-16fa-463f-9aac-da8889ef3b71`. Includes the allowlisted `widget_studio_opened` and `widget_studio_saved` events. Staging /health verified after deploy; no production deploy.

### Nov 8: Widget Studio control styling refinement

- Matched supplied studio controls: visible Ink/White/Slate/Olive/Rose plus custom swatch; right-aligned 14 pt typeface menu; native adjustable circular-thumb sliders; labeled alignment buttons; custom family selector; five named gradient preset squares and three visible color stops with Third on control. Headers use the reference 23/20 pt serif sizes. Library shows all 34 usable illustrations in manifest order, with 88 pt artwork in three columns and a selected-layer strip. Shared Snapshot Studio benefits from the same controls.
- Expanded tray scales with screen height; text alignment controls fit above the fixed Save footer at 402 pt. Lightened the onboarding Scripture scroll to near-white ivory, with softer edges/shadow.
- Verification: npm run check and all 189 API tests passed; all 16 native tests passed; final simulator build passed after spacing/library-order adjustment. Simulator inspected dark Text, Background and Illustrations trays, and the lighter onboarding scroll. Screenshots /tmp/hercrown-widget-palette-dark.png, /tmp/hercrown-widget-background-dark.png, /tmp/hercrown-widget-library-dark.png and /tmp/hercrown-scripture-scroll-light.png. No archive/upload; TestFlight remains build 17.
- Exported current floral crown app icon as 1024x1024 JPEG at /tmp/her-crown-logo.jpg for owner download. No API.Bible changes.

### 2026-11-08 · Build 18: licensed online translations
- Owner confirmed NKJV, MSG, AMP and NLT on API.Bible Pro Commercial. Added migration 0014, server-only credential, translation menus, asynchronous reader loading/retry, six-chapter memory cache, publisher attribution and preserved MSG verse bridges. NIV/ESV are not enabled. Existing offline KJV/BSB/WEB and public-domain study grounding stay available. Home/Discover editorial passages continue using explicitly labeled bundled editions.
- Production migration/secret/deploy remain owner-run and pending; build 18 targets staging. API key was shared in chat; rotate it before launch.
- Final source `fe6739a23a534636acfd785be7f03603a04ca808`: staging Worker version `fec4450e-da7b-4145-a908-79050b01761c`; migration 0014 applied to staging only. All four live Psalm 23 requests returned 200 with publisher attribution/no-store; MSG verse 2 correctly resolves to the intact 1–3 bridge. Temporary staging smoke account deleted.
- Verification: npm run check; 191 API tests; 17 native tests; Debug simulator build; inspected NLT and MSG reader views, including Psalm 23:1–3 range. Regression covers missing licensed chapters never falling back silently and paragraph boundaries. API credential scan found no key in tracked files.
- Release archive **1.0 (18)** built from the same clean source with `HC_STAGING_TESTFLIGHT`. Xcode Organizer confirmed upload to Apple on Nov 8 at 11:02 PM EST. Apple processing/tester-group availability being checked; not an App Store release.
- Post-upload Apple check: build 18 was not yet exposed in the builds API during the bounded processing check. Tester group assignment/beta review are **pending Apple processing**, not verified complete. Existing build 17 remains available. Prepared build 18 test notes and assignment script locally; no background poll remains running.


### Nov 8 late: onboarding and studio feedback corrections

- Onboarding uses prepared light typing feedback with stronger pulses (prayer remains slower/gentler). Bridge text now reveals through the same typing path. Analytics no longer blocks page reveal; background interruptions settle non-prayer pages so Continue cannot remain hidden, with Back independent of reveal. Added explicit Baskerville semibold emphasis to the three time-intro phrases, retaining the rose accent; raised the welcome footer 12 pt. Three chosen topics disable and dim unselected choices while allowing deselection.
- Replaced the demo with the owner’s Nov 8 23:35 recording, retaining the full reader/notes/study sequence at 1.39x speed (21.13 seconds), muted. Preserved the recording’s 1180:2556 phone proportions and Dynamic Island; centered play/pause.
- Settings topics are list rows with small hearts. Widget/Snapshot Studio handle now tracks vertical drag to expand/collapse; caption editing has a Done return key and Done typing control. Safe-area footer stays above the keyboard; tray height uses usable height rather than adding the keyboard inset. Preview avoids negative/tiny dimensions when keyboard space is limited.
- Study Save/Note/Copy/Share actions use neutral icon-and-label controls instead of inherited blue. Devotional quotation marks are presentation-only, with a regression ensuring canonical words remain unchanged and quotes are not duplicated. Fixed Subscription Explore’s callback: dismissal no longer incorrectly marks an Apple subscription as found; the verified-active-Apple-subscription restore guard remains.
- Visual checks: new video and playback, welcome footer, Settings heart list, selected-three disabled state, bridge Continue, widget keyboard with Save and Done visible, and keyboard Done dismissal. Screenshots: /tmp/hc-ui-demo.png, /tmp/hc-welcome-footer.png, /tmp/hc-topics-list.png, /tmp/hc-topics-limit.png, /tmp/hc-onboarding-time.png, /tmp/hc-widget-keyboard-fixed.png. Drawer expanded/collapsed layouts checked; coordinate drag automation was unavailable, so physical swipe feel and typing haptics need an iPhone check. No production deploy or new archive in this pass.
- Build 18 carryover completed: Apple build `610f8e58-c40b-4479-8a20-457ac8abaf29` is VALID, assigned to internal groups and external Beta (`20c28d43-2861-4a95-a0be-dc4cc303e4af`); Apple’s final buildBetaDetail reports IN_BETA_TESTING for both. This uploaded build remains source `fe6739a`; the latest corrections above are subsequent work and are not in build 18.
- Verification: final `npm run check && npm test` passed (191 API tests); native suite passed all 18 tests, including actual new-video playback and presentation quotation regression. No new dependencies. UI corrections await the next TestFlight archive; build number remains 18.


### Nov 9: TestFlight build 19 upload

- Release archive 1.0 (19) succeeded from clean isolated source `0178c48e30485ce57e765d7add084fed54b5d8fb`, with `HC_STAGING_TESTFLIGHT`. Includes the onboarding/studio feedback corrections above; backend unchanged. Prior validation: check, 191 API tests, 18 native tests and simulator visual checks passed.
- Upload verified in Xcode Organizer and Apple’s API: build `a1549b52-5e2a-4c6e-9b9c-d919b79b6602` is VALID / APP_STORE_ELIGIBLE, assigned to internal testers and external Beta (`20c28d43-2861-4a95-a0be-dc4cc303e4af`). Final beta detail reports IN_BETA_TESTING for both internal and external testers. No duplicate archive created.


### Nov 9: selected editions, compact credits and prayer overflow

- Daily Scripture and library snippets now resolve the selected NKJV/MSG/AMP/NLT edition through API.Bible, rather than explicitly falling back to KJV online. Home, Discover, devotional quotations, notes, insights and saved verses use this edition; devotional commentary and study generation remain separate and grounded in public-domain sources. MSG bridges remain intact and display their actual range. Licensed Discover fetches 12-card pages, with four provider calls in flight per response and lazy native pagination. Provider failures are surfaced instead of relabeling KJV as another edition.
- Replaced the reader’s long repeated notice with a readable 10 pt edition/© credit; licensed quotations elsewhere have the same compact credit. Full notices remain in Settings → Credits & Licenses and sharing retains attribution. Offline sessions with an online-only preference use KJV; bundled BSB/WEB remain available offline.
- Prayer typing no longer lays out invisible future text. Its clipped scroll area follows the revealed text and ends above the reserved Keep this prayer footer. Simulator checked typing and the completed two-paragraph prayer with the last line above the button (`/tmp/hc-prayer-footer-fixed.png`). Physical haptic feel is unchanged: light typing intensity 0.5, prayer 0.3, UIKit maximum parameter 1.0; these are not calibrated vibration percentages.
- Verification: `npm run check`, all 198 API tests and all 19 native tests passed; final simulator build succeeded. API regressions cover all four editions on Home/Discover/devotional, provider failure, deduplicated chapter calls and intact MSG bridges. Test-only guest sign-ins use unique synthetic IPs to avoid exhausting the auth limiter. After unlock, inspected the NLT reader’s compact 10 pt credit (`/tmp/hc-reader-compact-credit.png`); full repeated paragraph is gone. This work is newer than TestFlight 19 and has not been archived or uploaded. Production unchanged.

- Live staging smoke caught MSG lettered bridge endpoints (`PSA.4.6–7a`, `7b–8`) being discarded by the older parser. Numeric span parsing now accepts suffixes without changing the supplied words; added a regression for these groups and merged span extension.

- Staging deployed from clean isolated source `512587d`: Worker version `477249e8-57e9-4fe4-8d85-96a7aa73bf3b`. Live authenticated smoke passed all four editions on Home, NLT Discover pagination (12 cards / nextOffset 12) and the NLT devotional passage. MSG Psalm 4:8 resolves to its intact 7–8 group with correct label/attribution. Temporary smoke account deleted (200). No production deploy and no new TestFlight archive.

- Nov 9 owner adjustment: onboarding typing intensity raised to 0.7 and prayer to 0.5; pacing unchanged. Typecheck, all 198 API tests and iOS simulator build passed. Physical feel needs an iPhone check in the next build; not in TestFlight 19.

### Nov 9: TestFlight build 20

- Archive 1.0 (20) succeeded from clean isolated source `30eb518f07633dc3a275ffd2dd29119c5acc2877`, using `HC_STAGING_TESTFLIGHT`; staging backend is `512587d` / Worker `477249e8-57e9-4fe4-8d85-96a7aa73bf3b`. Includes selected editions across daily content, compact credits, preserved Message bridges, prayer reveal scrolling and requested typing/prayer intensities 0.7/0.5. Validation: check, 198 API tests, 19 native tests, simulator build and visual/live staging checks. Command-line upload failed with saved-account / API cloud-signing permission errors; Organizer successfully uploaded this same archive and displayed “HerCrown 1.0 (20) uploaded”. Apple processing completed: build `993e9dca-c105-4458-af3b-f279e0d1a313` is VALID / APP_STORE_ELIGIBLE. Test notes and automatic notifications set; assigned to internal groups and external Beta (`20c28d43-2861-4a95-a0be-dc4cc303e4af`), beta review submitted. Final API status is IN_BETA_TESTING for both internal and external testers. No App Store release.

- Nov 9: onboarding demonstration now plays at 1.5× (approximately 14 seconds for the bundled clip), including resume and loop item changes. Required check / 198 API tests passed; actual AVPlayer simulator test passed for advancing playback, rate 1.5, pause and resume. Committed for the next build; uploaded TestFlight 20 unchanged.

- Nov 9: owner reconfirmed approval of the remaining Ephesians 5:22 Deeper Study passage; the v4 report already records approval (2026-11-06). Automated score remains 51/52.
- Nov 9: onboarding demo remains paused while its headline reveals and its video is hidden. Activation now seeks exactly to the first frame before autoplay at 1.5×; leaving cancels pending playback, and returning rewinds. Manual pause/resume retains position. Verification: check and all 198 API tests passed; actual AVPlayer simulator test passed for hidden pause, rewind, 1.5× playback/resume and stale-callback cancellation. Ran and visually inspected the onboarding demo page (/tmp/hercrown-demo-restart.png). Committed for the next build; TestFlight 20 is unchanged.

### Nov 9: onboarding, Studio and notification follow-up (after TestFlight 20)

- Parked both return-offer paths in native configuration, including staging: no scheduling, decline synchronization or foreground presentation while `returnOffersEnabled` is false. Design preview remains available. Legacy Superwall decline placement was previously paused; dashboard state was not changed in this pass.
- Onboarding removes the name prefix from five questions; welcome text types again and its footer is raised. Artwork fades/slides in after the text on welcome, time intro, bridge and question/prayer pages. Video is centered between heading and footer, with its original aspect ratio and a clean status strip over the recording indicator; first-frame seek and 1.5× playback remain. Fast prayer requests now wait for anonymous-session startup, ignore stale/canceled results, expose useful API errors and hide Keep this prayer on failure. Provider failures and the existing three-per-day generation limit can still produce an error; rushing was not proven to be the cause of the owner's screenshot.
- Scripture sharing includes Widget Studio. Snapshot header has additional inset; illustrations support pinch resizing while retaining drag. Widget exports doubled from 600 to 1200 pixels wide with high-quality interpolation. Existing saved widgets must be saved again to replace older images; physical Home Screen sharpness and pinch feel still need an iPhone check.
- Discover lesson details now use the current reflection sheet (Back left / Done right, heart art, reference, Scripture, prompt and notes), without automatically opening the keyboard. Its study action opens the insights menu; marking studied confirms and saves changed notes first. Online editions fetch their passage instead of displaying an empty quotation. Online reader loading indicators remain intentional while a passage loads; canonical Scripture is unchanged.
- Notification crash: owner reproduced tapping a two-day-old notification with the app in the background. Replaced the async notification delegate bridge with a nonisolated completion callback, acknowledging the system promptly and delivering UI changes on MainActor. Added regression for invocation from a background queue, main-thread delivery, completion and repeated opens. This is a candidate fix, not confirmation of the original crash's cause. Apple's API currently exposes only an unrelated build-5 crash report from Nov 5; today's notification crash is not yet available. Physical background and cold-launch notification taps remain a release blocker until verified with the new binary / crash report.
- Validation: required `npm run check && npm test` passed (198 API tests); final native suite passed all 21 tests, including background-queue notification handling, 1200-pixel exports and actual AVPlayer behavior (`/tmp/hc-nov9-notification-test.log`). Ran and inspected demo and Snapshot Studio screenshots (`/tmp/hc-nov9-demo.png`, `/tmp/hc-nov9-studio.png`). Reflection launched with the new header, but an Apple StoreKit sign-in dialog obscured full visual inspection (`/tmp/hc-nov9-reflection.png`); do not treat that as full UI acceptance. No production deploy or archive. Uploaded TestFlight 20 is unchanged; these changes await a new build.

### Nov 9: early prayer preparation and reading-paced onboarding

- Prayer preparation starts when the loved-ones answer is submitted, during the rhythm page and its acknowledgment. Request identity excludes reading pace (which is not part of the model input), so choosing pace or moving into prayer does not cancel/restart it. Relevant-answer changes, explicit retries and the simple-prayer choice invalidate the request. Stale results remain ignored. This overlaps generation with the next page; it is not network token streaming and cannot guarantee zero wait on a slow provider.
- Main prayer text stays empty until its reveal begins, then types at 55 ms/character with sentence/comma/paragraph pauses and a one-second pause before closing Amen. Haptic intensities remain typing 0.7 / prayer 0.5. Reduced Motion continues to bypass animation. Simple prayer after a generation error uses the same reveal path.
- Acknowledgments now fade out over 350 ms after their reading hold before the next question appears. Removed the OpenRouter/DeepSeek footer wording; a short truthful provider-use notice is shown beside the optional burden/loved-ones inputs before early generation starts. Privacy-policy disclosure remains unchanged.
- Reminder switch uses a separate fixed-size control with trailing inset. Final ready page now says “A verse for what’s on your heart” and explicitly connects the verse to what the user shared; saved-prayer sharing remains available. Licensed reader edition/© credit remains: API.Bible requires attribution alongside copyrighted Scripture, so it was not removed.
- Verification: `npm run check && npm test` passed (198 API tests); all 23 native tests passed, including request identity not changing with pace, retry/relevant-input changes and pauses before Amen. Ran and inspected the reminder with its full switch (`/tmp/hc-reminder-inset.png`) and actual generated prayer mid-reveal (`/tmp/hc-prayer-reading-reveal.png`). Physical haptic feel and acknowledgment animation acceptance remain iPhone checks. No backend deploy, archive or TestFlight upload; build 20 unchanged.

### Nov 9: notification crash reports received and completion-thread correction

- Apple's newly available crash feedback confirms the owner's two notification crashes in 1.0 (20): incident `6CE436A2-CEC9-4127-BDA5-062EBEA9A721` (12:30:54, iPhone15,2) and `8257DF71-8F82-4E0D-9797-1BA56F54C451` (12:41:38, iPhone18,5). Both SIGABRT exception backtraces show UIKit state restoration / snapshot updates invoked from the compiler-generated `AppDelegate.userNotificationCenter(_:didReceive:)` completion on a worker thread. No prayer/provider involvement is shown in these crashes.
- Corrected the earlier candidate implementation: the system completion handler itself now runs inside MainActor, after external-open delivery. Moving only the app state to main was insufficient because UIKit performs its own work in that completion. Regression now asserts that both notification delivery and the completion execute on the main thread when entered from a background queue; all 23 native tests pass. Required check and all 198 API tests pass. The identified cause is addressed in source; actual background and cold-start notification taps still require the new binary on an iPhone. TestFlight 20 still contains the crashing async bridge.
- Audit follow-up: welcome collage now also waits for the text before its fade/slide reveal, matching the other onboarding illustrations. Compact licensed-edition credits are 9 pt instead of 10 pt in the reader, shared Scripture component and saved library snippets; attribution remains readable, with full notices retained. No publisher notices were removed and no Scripture was altered. No production change or TestFlight upload.
- Final simulator inspection: welcome screenshot during typing shows the collage hidden; completed headline screenshot shows the collage revealed and the raised footer fully visible (`/tmp/hc-welcome-reveal-early.png`, `/tmp/hc-welcome-reveal-complete.png`). Final simulator build succeeded; `git diff --check` clean.

### Nov 9: paywall spacing and notification retest trigger

- Published Superwall Main paywall 289087 with header top padding increased from 50 to 94 px, moving content lower. Shortened the annual trial, annual immediate-charge and monthly renewal paragraphs while preserving dynamic Apple product prices, automatic renewal and cancellation wording. Confirmed Main's actual audience filter is `device.isSandbox = true`, unsubscribed users only; no audience changes. Editor publish dialog uses a stale Untitled/100% label, so checked the campaign's actual filter before publishing. Preview saved at `/tmp/hc-paywall-balanced-published.png`; on-device layout review still required. No offer paywall changes.
- Staging/Debug only: completing onboarding schedules one local test notification 60 seconds later if notification permission is already authorized/provisional. Replaces the pending test with the same identifier; no extra permission prompt, no production test notification. Uses the same notification-response delegate as remote notifications. Requires a new binary and physical background/cold-start tests; current TestFlight20 remains unchanged.
- Publisher edition/© credits remain readable at 9 pt; not reduced to unreadable 4 pt. Final ready page remains the personalized verse page from the preceding sweep; no further removal requested/implemented.
- Verification: required typecheck and 198 API tests passed; native XCTest suite succeeded including the main-thread notification completion regression. No production deploy or archive/upload.


### Nov 9: onboarding handoff and Discover expansion for build 21

- Removed the visible play/pause overlay from the onboarding recording. Retains first-frame activation, 1.5× playback and paused behavior under Reduce Motion.
- Top-aligned question text and artwork and unified the question top inset (20 pt). Name, life season and other question headings now share one vertical anchor instead of centering against the illustration height.
- Final Open my Bible requests the onboarding paywall over the final onboarding page; local/server onboarding completion and reader navigation happen after its completion callback (dismiss/purchase/skip/error). Guest reading remains direct. Button stays disabled while presentation is pending.
- Prayer heading has an independent character counter with the existing typing haptics. Prayer auto-scroll only starts when the prayer body is revealing, not during the title.
- Discover lesson opens the existing cited seven-section Deeper Study for Plus members; free readers see the study-tool menu with Plus labels. Notes remain a separate action. Study sections use spaced 18 pt rounded cards; source citations, separate-from-Scripture notice and report remain. No new source content or competitor text copied.
- Verification: required check and all 198 API tests passed; all 23 native tests passed. Simulator inspected question alignment, control-free video and prayer heading/loading/error layout. Screenshots: /tmp/hc-aligned-name.png, /tmp/hc-aligned-season.png, /tmp/hc-demo-no-controls.png, /tmp/hc-prayer-title-finished.png. Existing review account hit the prayer daily limit during repeated preview checks; the supplied error and simple-prayer path remain available. Physical haptics, real paywall handoff, notification taps and full Plus study navigation require the next iPhone build. Build number bumped to 21; archive/upload recorded separately when successful. No production deployment.

- Build 21 follow-up before upload: Studio drawer now uses a 2 pt drag threshold and fixed global coordinates, holds an explicit height while dragging, and keeps the tool content mounted. Removed the Button wrapper from the handle (tap and accessibility adjustment remain supported); release settles to an endpoint with an interactive spring. Shared by Snapshot and Widget Studio. Required check, 198 API tests and 23 native tests passed. Direct touch smoothness/hold-and-release acceptance remains an iPhone check. The earlier 5be592a archive was not uploaded; the final archive must use the follow-up source commit instead.


### Nov 9: build 21 archive awaiting upload

- Final archive 1.0 (21) succeeded from clean isolated checkout `dddb75d55a42c7de50f46c1bc63942454596d7ab`, using `HC_STAGING_TESTFLIGHT`: `/private/tmp/hercrown-build21-final/HerCrown.xcarchive`. Includes all preceding post-build20 fixes and the continuous Studio drag follow-up. The earlier 5be592a archive was not uploaded.
- Checks: required typecheck, 198 API tests and 23 native tests passed. Inspected expanded Studio layout at `/tmp/hc-studio-continuous-drawer.png`; finger-drag feel remains physical testing. No production change.
- Upload pending: Xcode Organizer computer control reports Mac locked. Command-line export/upload fails `Failed to Use Accounts` for team `494RZLCNHQ` (`/private/tmp/hercrown-build21-upload.log`). Asked owner to unlock Mac and leave Xcode open; retry the same final archive rather than making another build. No claim of TestFlight21 availability yet. Current confirmed uploaded build remains20.

### Nov 9: build 21 uploaded and available to testers

- Uploaded the final clean-source archive `dddb75d55a42c7de50f46c1bc63942454596d7ab` through Xcode Organizer after the Mac was unlocked. Apple accepted 1.0 (21), build ID `4b7dbd13-9808-4e8a-acdc-c34802bb750f`; processing `VALID`, audience `APP_STORE_ELIGIBLE`.
- Added build-specific testing notes, enabled tester notifications, and assigned the existing internal groups and external Beta group. Apple API confirms both internal and external states `IN_BETA_TESTING`. This is the staging TestFlight build; no production deployment or App Store release.
- iPhone acceptance checks remain: continuous Studio handle drag/hold/release; first-frame 1.5× video without controls; consistent onboarding headings and prayer typing haptics; paywall before reader; notification taps from background and cold start using the staging onboarding test notification. Automated verification remains 198 API tests and 23 native tests passed.

### Nov 9: follow-up after build 21 review

- Welcome artwork no longer sits behind a whole-collage reveal that hid its individual entrances. The seven masks enter 120 ms apart (flowers, Bible, small flower, cup, olive, journal, cloud), settling over 560 ms while the heading types. Inactive launch state no longer permanently marks art animations complete. Welcome typing is 32 ms/character (was 48); explicit lines are Less / doomscrolling. / More Scripture. Prayer pacing is unchanged. Time-intro cutouts now have individual 0/140/280/420 ms reveal delays after the heading. Other question artwork retains its post-heading entrance.
- Removed the name prefix from the loved-one question to avoid repeating the preceding acknowledgement.
- Snapshot and Widget Studio now apply pinch to the whole canvas for the selected illustration; changing selection resets the pinch baseline. Individual illustration selection and dragging remain. Widget Studio loading is a plain spinner, with navigation controls only on a recoverable error. Matching owner/edition cached widget passage opens immediately without blocking on an online refresh.
- Onboarding paywall skip is not declared fixed without a device trace: added staging-only outcome details to the existing Yearly trial check for server Plus, active Apple subscription, busy/unconfigured Billing, and Superwall skip/error. Existing entitlement and campaign rules are preserved.
- Verification: npm run check and all 198 API tests passed; 23 native tests passed, including a final build with DEBUG + HC_STAGING_TESTFLIGHT. Inspected running simulator welcome layout and successive frames (/tmp/hc-stagger-1.png, /tmp/hc-stagger-2.png, /tmp/hc-welcome-stagger-final.png), confirming early flowers/Bible while lower pieces are hidden and later full composition. Native computer control cannot resolve the Simulator app; screenshots used simctl. Two-finger feel, widget-load latency on device and real onboarding campaign skip remain phone checks. No new TestFlight archive/upload in this follow-up; installed build 21 does not contain these edits yet.

### Nov 9: build 22 choreography cross-check

- Owner timing correction: time-intro cutouts lead text in a 0/140/280/420 ms stagger, with heading typing starting after 220 ms. Christ bridge keeps text first and flower afterward. Walkthrough mounts/plays when the page enters before heading typing; Continue stays gated until typing completes. Name journal and comparison magnifier also lead their headings; later page and prayer sequencing is unchanged.
- Includes the post-build21 changes in 4d99cea: individually staggered welcome art, faster three-line welcome heading, reduced name repetition, canvas-wide selected-illustration pinch, clean Widget Studio loading and matching owner/edition cache, staging paywall skip diagnostics.
- Version bumped to 1.0 (22). Required check and 198 API tests passed; 23 native tests passed with DEBUG + HC_STAGING_TESTFLIGHT. Archive source and TestFlight delivery will be recorded after upload. No production deployment.

### Nov 9: build 22 available in TestFlight

- Archived from clean isolated source commit `4c36a9984e4c5c59e16d98804e6de30445dc5650` with `HC_STAGING_TESTFLIGHT`: `/private/tmp/hercrown-build22/HerCrown.xcarchive`. Xcode Organizer confirmed HerCrown 1.0 (22) uploaded. Apple build ID `60fc0042-18f8-4432-8c2b-eea37c80aa3e`, processing `VALID`, audience `APP_STORE_ELIGIBLE`.
- Added build-specific test notes, enabled tester notifications, assigned existing internal groups and external Beta group, and submitted beta review. Apple API then confirmed both internal and external states `IN_BETA_TESTING`. No App Store release or production deployment.
- Verification: required check, 198 API tests and 23 native tests passed. Running simulator screenshot `/tmp/hc22-demo-entrance.png` confirms the walkthrough is already visible/playing while the heading is still typing and Continue remains hidden. Physical checks remain: entrance cadence/haptics, canvas-wide pinch on a tiny selected illustration, notification taps from background/cold start, and onboarding paywall outcome diagnostics if skipped.

### Nov 9: onboarding alignment, playback readiness and paywall diagnosis

- Question headings from the walkthrough onward share the same top inset, including acknowledgements. Text owns the heading height; the accompanying illustration is overlaid at its bottom trailing edge so short headings do not shift downward to accommodate art. Prayer uses the same heading component.
- Study menu/detail, reflection, devotional and plan sheets use a consistent high Back/Done row with 44-point touch targets. Chapter picker, plans list and saved-sheet header top padding was aligned as well.
- Walkthrough waits for AVPlayerItem readiness before rewinding and autoplaying, including with Reduce Motion enabled. Added a regression test for autoplay and rewind on reentry; existing paused-entry and inactive-player tests remain passing.
- Read-only staging Tinybird inspection found build 22 onboarding_complete skipped at 2026-11-09 21:07:35 UTC because the user did not match an audience. Superwall Main audience 199478 in campaign 116616 is active, sandbox-only, excludes active entitlements and has onboarding_complete enabled. Owner screenshot reports an existing Apple subscription. No audience or entitlement protection was changed. A new app onboarding session does not reset Apple's subscription.
- Staging diagnostics now persist the last paywall result across relaunch/account switching; guest and pre-presentation guard exits also record a reason. These local changes are not in installed TestFlight build 22 yet.
- Verification: npm run check and 198 API tests passed; all 24 native tests passed with DEBUG + HC_STAGING_TESTFLIGHT. Running simulator screenshots /tmp/hc23-question-aligned.png and /tmp/hc23-study-controls.png confirm heading/art alignment and higher control row; /tmp/hc23-demo.png confirms recording playback. No deployment or archive performed.

### Nov 9: build 23 preparation

- Owner confirmed the onboarding paywall now appears and requested reduced presentation delay. Final onboarding page now explicitly preloads only onboarding_complete through Superwall's supported preloadPaywalls API, with light styling and a loaded non-Plus identity. It does not register/present the placement early; checkout and audience/subscription checks remain at the button action. Automatic broad preloading is disabled so sandbox identity is established first. Device/network timing still requires a phone check.
- Includes commit 3629057: shared question/acknowledgement top alignment, bottom-aligned heading illustrations, higher Back/Done sheet controls, readiness-aware walkthrough autoplay, persistent staging paywall diagnostics. Studio headers now use the matching high inset as well.
- Version 1.0 (23). Required check and 198 API tests passed; all 24 native tests passed. Simulator screenshots inspected for onboarding, study-menu controls and Snapshot Studio header. Archive/upload source SHA and Apple delivery status will be recorded after delivery. No production deployment.

### Nov 9: build 23 delivered to TestFlight

- Archived from clean isolated source `df66d28c0e2b29e54d7b076d5d6df4297c957a28` at `/private/tmp/hercrown-build23/HerCrown.xcarchive`, Release + HC_STAGING_TESTFLIGHT. Verified app Info.plist version 1.0, build 23. CLI export failed with account access; the same archive uploaded successfully through Xcode Organizer.
- Apple build ID `49706f26-e5d8-448d-8647-c65217013a52`, processing VALID, audience APP_STORE_ELIGIBLE. Updated build-specific test notes, enabled tester notifications, assigned existing groups including external Beta and submitted beta review. Final API status confirms internal and external IN_BETA_TESTING.
- Phone verification: finish onboarding as an eligible non-subscriber, allow the last verse page to remain visible briefly, then tap Open my Bible and compare presentation delay; check question/acknowledgement/icon baselines, higher Back/Done controls and walkthrough autoplay. Preloading does not guarantee zero delay on slow networks. No production deployment or public App Store release.

### Nov 9: build 24 illustration entrances

- Owner confirmed build 23 heading/icon alignment and notification taps work. Restored a visible fade, 14-point upward entrance and subtle scale-in for side illustrations on every onboarding question page, including prayer. Art leads the heading slightly and continues entering while text types. Each heading illustration has page-specific identity and commits a hidden mounted frame before revealing, preventing SwiftUI from mounting it already fully visible. Alignment and existing intro collage/Christ bridge choreography remain intact; Reduce Motion remains immediate.
- Version 1.0 (24). Required check, 198 API tests and all 24 native tests passed. Simulator recording `/tmp/hc24-art-entry.mp4` and frame contact sheet `/tmp/hc24-art-entry-frames.jpg` visually confirm the entrance on the familiarity page during typing. No production changes. Clean archive/upload identifiers will follow delivery.

### Nov 9: build 24 delivered to TestFlight

- Clean archive source `348121c6e43c4e6f42ae61026041edb0617b7ad3` at `/private/tmp/hercrown-build24-source`; Release + HC_STAGING_TESTFLIGHT archive `/private/tmp/hercrown-build24/HerCrown.xcarchive`. Verified Info.plist version 1.0 (24). Xcode Organizer confirmed successful upload after owner unlocked the Mac.
- Apple build `a2296ad6-d813-4268-9b6a-3d49cd048e26` processed VALID, APP_STORE_ELIGIBLE. Build-specific test notes saved, tester notifications enabled and existing internal/external Beta groups assigned. Submitted beta review; final API status internal IN_BETA_TESTING and external IN_BETA_TESTING. No production deployment or App Store release.

### Nov 9: fix question flash after acknowledgement

- Build 24's illustration entrance introduced a 220 ms wait between replacing an acknowledgement with the next question and resetting the typing character count. The acknowledgement's old count could briefly reveal the question before typing restarted. Reset the count before mounting the question; keep the illustration entrance and aligned heading layout.
- Verification: npm run check and all 198 API tests passed; all 24 native tests passed. Corrected app launched and its onboarding question screen was inspected in the simulator. After owner unlocked the Mac, recorded an actual Social media response → acknowledgement → season question transition in `/tmp/hc24-flash-verified.mp4`. Inspected frame sequence `/tmp/hc24-flash-sequence.jpg`: acknowledgement fades, question starts blank, illustration fades in, then the question progressively types without a full-text flash or restart. This correction is local, not in the installed TestFlight build 24; no new archive/upload or production changes.

### Nov 9: onboarding pacing and reader handoff polish (local)

- Welcome subtitle fades in; time-cost slide fades out before the Christ bridge. Non-prayer typing is about 10% faster (29/43 ms); prayer reading pauses remain unchanged. Prayer characters now use relative delays to avoid catch-up bursts suppressing haptic pulses; intensity stays 0.5. Physical haptic feel requires owner verification.
- Pace page adds “A gentle place to start” below 5 minutes, replaces the prayer footnote with “Your pace. You can change it anytime.”, removes the extra simple-prayer action, and reserves a consistent footer height. Prayer prefetch no longer hides Continue on earlier pages or after backtracking.
- Onboarding completion selects the Bible reader synchronously. Superwall's will-dismiss callback replaces onboarding under the still-visible paywall so purchase/free-reading dismissal should reveal the reader directly; entitlement verification remains separate. Live device checkout/dismissal still needs checking.
- Verification: npm run check, 198 API tests and 25 native tests passed, including reader handoff without granting Plus. Simulator pace page/backtracking inspected; recorded intro fade sequence at `/tmp/hc-intro-fades.mp4`. No new TestFlight archive/upload; installed build 24 does not include these local corrections.

### Nov 9: verse sharing and full-screen studios (local)

- Share now opens a dedicated verse-preview sheet with Share verse text, Snapshot Studio (“Create an image of this verse”), and Set as widget verse using the bookmark symbol. Both studio choices present a full-screen editor. Studio titles/reference lines sit left-aligned beside the chevron Back button, with Done at the far right and safe top padding (owner’s Nov 9 screenshot correction). Header edition labels use the short code, e.g. KJV.
- Snapshot Studio adds a separate download button left of Share snapshot, saves to Photos using add-only permission, and handles denied/failed saves without claiming success. Text tools include an on/off Her Crown signature for all users; exports use a transparent floral-crown cutout derived from the existing logo, with no white tile or border. Existing saved draft field remains compatible.
- Added allowlisted, non-personal `verse_share_opened` and `verse_snapshot_downloaded` analytics and documented their semantics. Production deployment remains human-only.
- Verification: npm run check, 198 API tests and 25 native tests passed after the header correction. Visually checked both full-screen studio headers in the simulator against the owner’s screenshot: left-aligned title beside chevron, short reference beneath, Done at far right. Interactively verified Share verse → both studios, signature toggle removes the crown, snapshot download completes with “Snapshot saved to Photos”, native snapshot share sheet opens, and widget save reports “Widget design saved”. Photos add-only usage description verified in built Info.plist. Header screenshot: `/tmp/hercrown-widget-header.png`. No new TestFlight archive/upload yet.
- Staging analytics deployed from clean detached checkout `/tmp/hercrown-share-staging-15a667b`, source `15a667b86882250394ace5d39be891f44e9dfb20`, Cloudflare version `f9625e26-c71f-4d32-9f93-ad9482bcd230`. Production unchanged; its new analytics allowlist will require the normal human-run production deployment before a production release of these features.

### Nov 9: unsaved studio exit panel

- Both Snapshot Studio and Widget Studio now show the reference-style “Keep your changes?” bottom panel over a dimmed editor when Back or Done is pressed after unsaved edits. Save & Close persists the snapshot draft or publishes the widget design before closing; Discard changes leaves the last saved draft untouched; Keep editing preserves the current canvas. Unchanged designs close immediately.
- Removed Snapshot Studio's unconditional save-on-disappear so discarding edits cannot silently overwrite the saved version. Photo replacement/removal participates in dirty-state tracking; failed saves keep the editor open with an error.
- Verification: npm run check, 198 API tests and 25 native tests passed. Simulator visually confirmed the panel layout and verified Keep editing retains the changed alignment and Save & Close returns to Share verse. After unlock, reopened Snapshot Studio confirmed the saved alignment persisted; changing it again and discarding restored the last saved alignment. Unchanged designs close immediately. Widget Studio also displayed the same panel after a background edit. Preparing build 25 with this addition and the preceding onboarding/share fixes; no production changes.

### Nov 9: study and account reference corrections for build 25

- Study tool pages retain a centered selected passage, including online translations. Related verses use one shared broken-chain outline in the menu and each compact reference row; empty results say “No related verses.” Removed the inline cross-reference credit from this page; OpenBible attribution remains in Settings → Credits & Licenses. Original-language cards keep the actual word, transliteration, gloss and Strong number with a detail chevron, without fixture copy.
- Commentary sections now expand/collapse independently; sources and study notes remain a collapsed disclosure. The existing server returns published cached answers immediately; first-generation Deeper Study still waits for generation and citation validation (and a retry when needed). No latency guarantee or backend/model change was made.
- The insights widget row now uses the reference book icon and chevron and opens the full-screen Widget Studio with that passage, rather than silently changing the widget preference.
- Account photo selection opens an explicit drag/pinch crop preview before uploading; Choose photo spans the form width with the reference outline. The sign-in helper fits one line. Removed the inline deletion warning and retained it in the destructive confirmation. Active membership uses a regular serif heading, small status/plan text and a primary Manage subscription link, with real renewal details retained.
- Verification: npm run check and 198 API tests passed; 25 native tests passed. Simulator verified centered selected passage and insights → Widget Studio preserving Psalm 23:1. Account photo picker opened; a temporary debug preview with a bundled flower verified the crop layout and Use photo → “Photo updated.” upload/return path. The temporary preview hook was removed. Physical pinch/drag feel still needs the iPhone check. Paid study rows/collapse and active-membership layout still need device verification with Plus. No production changes.

### Nov 9: build 25 delivered to TestFlight

- Archived from clean isolated checkout `/tmp/hercrown-build25-source`, source `fdc6be6c8e632a899e87d9da3b0293782a574f93`. Final archive `/private/tmp/hercrown-build25-upload/HerCrown.xcarchive`, Release + HC_STAGING_TESTFLIGHT; verified version 1.0 (25). Xcode Organizer confirmed successful Apple upload. The earlier local build 25 archives were superseded and not uploaded.
- Apple build `8a57b502-39dd-4ff7-b713-cba8268250f8` processed VALID, APP_STORE_ELIGIBLE. Saved build-specific testing notes, enabled tester notifications, assigned existing internal groups and external Beta, and submitted beta review. Final API status confirms internal IN_BETA_TESTING and external IN_BETA_TESTING.
- Includes the preceding onboarding/reader handoff, verse sharing, studio header/signature/download/save-discard, study layout/disclosure and profile crop/membership changes. Required checks and 198 API tests plus 25 native tests passed; final archive compilation succeeded after the membership button's reference-outline adjustment. Device checks remain: continuous prayer haptics, paywall checkout/free dismissal, crop pinch/drag feel, and paid study disclosure/related rows. No production deployment or public App Store release.

### Nov 9: cropped profile photo replacement fix (build 26)

- Fixed stale avatars: Avatar now fetches the server's versioned `/me/avatar?v=…` path rather than the same day-cached `/me/avatar` URL. A successful upload applies the returned profile and crop bytes directly to shared app state, so every avatar updates without a redundant full-profile fetch. Session changes clear the local image; failed uploads preserve the previous photo.
- Use photo now has a full-width tappable label, an immediate saving indicator and duplicate-tap protection. The crop stays open until the upload succeeds; errors remain visible there with the crop available to retry. Cancel/Reset are disabled during saving.
- Verification: required check and 198 API tests passed; 26 native tests passed, including two sequential replacements and failed-upload preservation using a stubbed upload endpoint. In the running simulator, used bundled artwork through a temporary debug selector to save a flower, then replace the existing flower with a dove: each single tap showed Saving photo and returned with Photo updated and the new avatar visible. Temporary selector removed before delivery. Real photo-picker grid and physical pinch/drag still need the owner's iPhone check. No server or production deployment.

### Nov 9: build 26 delivered to TestFlight

- Archived from clean isolated checkout `/tmp/hercrown-build26-source`, source `db00793a6313afcc708463a02b0a6ebf8b660ee7`. Archive `/private/tmp/hercrown-build26/HerCrown.xcarchive`, Release + HC_STAGING_TESTFLIGHT; verified version 1.0 (26). Xcode Organizer confirmed Uploaded to Apple.
- Apple build `6b226000-431b-4d26-8140-6f89516a7a4c` processed VALID, APP_STORE_ELIGIBLE. Saved photo-fix testing notes, enabled tester notifications, assigned existing internal groups and external Beta, and submitted beta review. Final API status confirms internal IN_BETA_TESTING and external IN_BETA_TESTING.
- Includes the cropped-avatar replacement and single-tap save fix described above, plus all build 25 changes. Required check, 198 API tests and 26 native tests passed; archive compilation succeeded. Owner should test a real photo replacement, reopening Account and relaunching to confirm persistence. No production deployment or public release.

### Nov 9: compact verse sharing and visible illustration removal (local)

- Share verse opens at three-quarter height, with optional expansion for long passages; removed the gray grouped-row background and muted action-row styling. Snapshot and Widget Studio remain full-screen editors.
- Added a visible X to each placed illustration thumbnail in both studios. Removal clears the selected layer and active transform state when relevant; the existing Save/Discard flow still controls persistence.
- Verification: required check and all 198 API tests passed; simulator build succeeded. Inspected the shorter Share verse sheet with plain white rows, then opened Widget Studio and used the new X to remove its olive illustration (count 1 → 0, canvas removed it), and added a Cosmos to inspect the X placement. Shared implementation covers Snapshot Studio. These corrections are local and are not included in TestFlight build 26 yet.

### Nov 9: photo crop safe-area header (local)

- Moved Adjust photo controls into a dedicated top safe-area inset with a 44-point X target (“Cancel photo crop”), centered title and Reset. Constrained crop content to the available viewport so it cannot push the header above the display; only the black background extends behind system areas.
- Verification: simulator screenshot confirmed X/title/Reset below the status bar and Use photo above the home area. Tapping X returned to Your account without saving. Used a temporary bundled-image preview because the native photo-picker grid is not accessible to the computer tool; removed that preview from source. Required check and all 198 API tests passed. This correction is local, not in TestFlight 26.

### Nov 9: prepare TestFlight build 27

- Build 27 includes the shorter plain-row Share verse sheet, visible illustration thumbnail removal in both studios, and the crop screen's safe-area header/X, plus all build 26 photo-save fixes.
- Required check and all 198 API tests passed; the preceding simulator builds and interactive UI checks passed. Archive will use a clean isolated checkout with HC_STAGING_TESTFLIGHT. No production deployment or public release.

### Nov 9: build 27 delivered to TestFlight

- Archived from clean isolated checkout `/tmp/hercrown-build27-source`, source `228f76e8f764ec1bba7e7e23ee07833a4b8b4e0e`. Archive `/private/tmp/hercrown-build27/HerCrown.xcarchive`, Release + HC_STAGING_TESTFLIGHT; verified version 1.0 (27). Xcode Organizer confirmed Uploaded to Apple.
- Apple build `ecc65dae-03b1-4290-97c3-1937396e5443` processed VALID, APP_STORE_ELIGIBLE. Saved build-specific testing notes, enabled tester notifications, assigned existing internal groups and external Beta, and submitted beta review. Final API status confirms internal IN_BETA_TESTING and external IN_BETA_TESTING.
- Includes the three-quarter-height plain-row Share verse sheet, visible illustration removal in both studios, and the safe-area photo crop header with X, plus build 26 photo replacement fixes. Required check and 198 API tests passed; simulator UI checks and final archive compilation succeeded. Real-device crop/pinch and photo replacement remain owner checks. No production deployment or public App Store release; return offers remain off.


### Nov 9: post-build-27 crop, saved appearance and Discover completion corrections (local)

- Replaced the crop header's SwiftUI inset assumption with measured window safe-area overlap and a reserved header/content viewport. Verified X/title/Reset below the status bar in a full-window simulator presentation; X exits without saving. Physical-device confirmation is still needed because build 27 showed the original overlap there.
- Saved passages now opens full-screen from all five entry points, honors the chosen Light/Dark/System preference, and closes through Done. Verified white in Light and black in Dark in the running app.
- Standardized widget actions on the four-square icon in Share verse, study tools and the Widget Studio save control; Settings already uses it. Verified Share verse visually.
- Added circle-check controls to Discover's featured passage and each list entry. Tapping fills the themed check, briefly enlarges it, fades the passage, then moves it below unread entries in completion order while the list closes the gap. Completed passages remain readable/searchable and can be moved to the end again. Progress uses existing per-account studied storage; emits discover_card_read. Reduce Motion skips decorative animation.
- Verification: iOS simulator build succeeded; npm run check and all 198 API tests passed. In the running app marked 1 Peter 4:10, confirmed removal from its original position and placement after the other loaded entries, relaunched, then searched for it and confirmed the persisted filled check. No new TestFlight upload or production change yet.


### Nov 9: prepare TestFlight build 28

- Includes the post-build-27 crop window-safe-area correction, full-screen Saved passages honoring appearance, consistent four-square widget icons, and Discover circle-check completion with fade/reordering and persisted studied state.
- The feature commit passed npm run check, all 198 API tests and an iOS simulator build; running-app checks are recorded above. This commit bumps app and widget to 1.0 (28). Archive uses a clean isolated checkout with Release + HC_STAGING_TESTFLIGHT. No production deployment.


### Nov 9: build 28 archived; upload verification waiting for Mac unlock

- Clean archive source `8df0168` from `/tmp/hercrown-build28-source`; archive `/private/tmp/hercrown-build28/HerCrown.xcarchive`. Archive succeeded; verified app version 1.0 (28) and staging API URL in the archived executable.
- Started Xcode Organizer App Store Connect distribution (eligible for internal and external TestFlight). Latest visible stage: Waiting for App Store Connect analysis response, Uploading. Mac then locked; requested owner unlock. Apple API does not yet return build 28, so delivery and tester access are not confirmed.
- Prepared `/private/tmp/hercrown-external28.mjs` to save build notes, assign existing tester groups and submit beta review once Apple returns the valid build. No production deployment or public release.


### Nov 9: build 28 delivered to TestFlight

- Xcode Organizer confirmed HerCrown 1.0 (28) uploaded. Apple build `2015c91e-ecd8-4dd8-9dca-cc288f3fbbb6` processed VALID, APP_STORE_ELIGIBLE. Clean archive source `8df0168`, archive `/private/tmp/hercrown-build28/HerCrown.xcarchive`, Release + HC_STAGING_TESTFLIGHT.
- Saved build-specific testing notes, enabled automatic tester notifications, assigned existing internal groups and external Beta, and submitted beta review. Final Apple API status confirms internal IN_BETA_TESTING and external IN_BETA_TESTING.
- Includes Discover circle-check completion/fade/reordering with persisted progress, full-screen appearance-aware Saved passages, four-square widget action icons and the measured-window-safe-area photo crop header. Prior feature checks passed npm run check, all 198 API tests, simulator build and interactive checks. Real-device crop controls remain an owner verification item. No production deploy or public release.

### Nov 9: compact Home search and share-sheet spacing
- Replaced Home’s full-height search card/wheel pickers with the reference pull-up: small Back/Done controls, Book menu, Chapter/Verse menus, and a wide bottom Study this verse button. Starts at 58% height and can expand for longer/accessibility content; follows appearance.
- Raised the share actions by tightening the verse/action spacing and increasing bottom breathing room. Kept the three-quarter sheet, plain rows, and consistent four-square widget icon.
- Verified in UI Review simulator: chapter menu selection opened Psalm 1:1 in the study menu; inspected Home search and the updated dark share sheet visually. Simulator build succeeded; npm run check passed; npm test passed (198 tests). These changes are local and are not included in the already-delivered TestFlight build 28.

### Nov 10: reader like animation and double tap
- Bible reader now shows a springing heart that fades away when saving with the heart button or double-tapping the verse area. Double tap only saves, never unsaves; the heart button retains unlike behavior. Uses appearance-aware colors, light haptic feedback, and an opacity-only transition for Reduce Motion.
- Uses the existing saved-passage persistence/API and server `passage_saved` analytics event. No new vendor or dependency.
- Verification: simulator build succeeded; npm run check and all 198 tests passed. In UI Review, double tap saved Psalm 23:1, a repeat double tap retained it, and the heart button unsaved/saved correctly. Haptic feel needs a physical iPhone check. Not yet uploaded to TestFlight.

### Nov 10: red heart bloom refinement
- Replaced the monochrome like pulse with a red gradient heart: spring bloom, delicate expanding ring and six small sparks, then an upward drift and fade. The saved reader heart is red too. Reduce Motion omits the spatial animation.
- Captured a held expanded frame from the native simulator for visual review (debug-only preview flag, reset afterward). Simulator build and required typecheck/tests passed (198 tests). Not uploaded to TestFlight.
- Follow-up: removed the decorative ring and all sparkles from the like effect at the owner’s request. Kept only the red heart bloom, upward drift and fade. Visually checked in the simulator; build, typecheck and 198 tests passed.


## Production preflight — November 10, 2026

Owner requested the move toward production. Read-only checks confirmed:

- [x] Release points at production unless explicitly built with HC_STAGING_TESTFLIGHT; returnOffersEnabled is false. Latest TestFlight 28 is a staging beta, not the final production candidate.
- [x] Production health/privacy/terms/support return HTTP 200.
- [ ] Update production: active Worker is still `2492147a-dce3-4d05-b311-c29636298b09` (November 6); migrations 0012_onboarding_prayer, 0013_community and 0014_licensed_translations are pending. API_BIBLE_KEY is absent from production secret names. Owner must apply migrations, privately set a regenerated key, then deploy a tested clean commit. No production writes were performed by the agent.
- [x] Apple API confirms version 1.0 is Prepare for Submission, releaseType MANUAL, and age rating FOUR_PLUS.
- [ ] Review/publish privacy details for the new personal-prayer and suggestion flows; prior November 6 publication predates these features.
- [ ] Confirm licensed translation sharing/widget permissions and the owner-reported $7,350 donation total. Production fictional ballot profiles remain disabled.
- [ ] Final production-connected TestFlight candidate, sandbox purchase/restore and signed production webhook delivery; fresh onboarding, personal prayer, translation, notifications, account deletion and analytics smoke checks.
- [ ] Final screenshots/review metadata, selected release build and annual/monthly subscriptions, then App Review submission. Manual public release follows approval.

Updated production-deploy.md to reflect $39.99 annual / $5.99 monthly, pending migrations and existing infrastructure. No production deploy or App Store submission has occurred in this preflight.

Live Apple follow-up: annual and monthly are READY_TO_SUBMIT; monthly has zero introductory offers and annual has ONE_WEEK FREE_TRIAL offers. Version 1.0 still selects build 1; latest uploaded beta is 28. Corrected the draft listing Support URL to production, replaced weekly with monthly in description/review notes, and marked both return offers disabled in private review notes. These draft edits do not submit or release the app. Required check and all 198 tests passed.

Owner-run production preparation confirmed November 10: all three pending migrations (0012–0014) applied successfully. Owner regenerated API.Bible credentials and Wrangler confirmed API_BIBLE_KEY uploaded to both production and staging. Local .dev.vars key replacement is not yet confirmed. The current backend code still needs the owner-run production deployment; secret updates alone do not deploy the new application code. Required checks and 198 tests passed for the code being prepared.

Production deployment completed by owner on November 10, 2026: source `e93d05afe0fb2b781216eba367c26d0faa678d91` (tracked checkout clean), Cloudflare version `ca9055cd-bb29-4f05-b3fe-688f9b9d7b12`. Wrangler confirmed the production queue producer/consumer and 15-minute schedule. Post-deploy public checks returned HTTP 200 for /health, /legal/privacy, /legal/terms and /legal/support. This verifies public availability only; authenticated production feature, purchase/restore, signed-webhook and analytics smoke tests remain pending before release.

### Build 29 production release candidate preparation
- Bumped app and widget to 1.0 (29). Archive uses standard Release without HC_STAGING_TESTFLIGHT, so it connects to production and hides Sandbox testing. Includes the post-28 Home search/share spacing updates and red heart double-tap like animation without sparks. Return offers remain disabled. Production backend version ca9055cd-bb29-4f05-b3fe-688f9b9d7b12 was verified before preparation. Upload and production-connected device checks are pending.

Build 29 archived successfully from clean source `51a053d` at `/private/tmp/hercrown-build29/HerCrown.xcarchive`. Verified app version 1.0 (29), team 494RZLCNHQ, and production URL in the archived binary. Required typecheck and all 198 tests passed. Command-line upload failed with Failed to Use Accounts; Organizer upload is in progress. No App Review submission or public release yet.

Xcode Organizer confirmed “HerCrown 1.0 (29) uploaded” on November 10. Apple processing and TestFlight assignment are being checked; upload completion is not confirmation of tester availability.

Build 29 delivery verified: Apple build `7840137b-f1f7-4e76-a813-47a9077d83a4`, processing VALID, audience APP_STORE_ELIGIBLE. Assigned existing external Beta group `20c28d43-2861-4a95-a0be-dc4cc303e4af`, updated beta notes and enabled notifications. Apple API reports both internalBuildState and externalBuildState IN_BETA_TESTING. Source `51a053d`; production Release, no HC_STAGING_TESTFLIGHT. Production-connected device smoke tests and App Store review submission remain pending.


### November 10 — real Community shortlist prepared

- Replaced fictional Community profiles with independently researched Dress for Success (US), CAMFED (Africa), Women’s Aid Federation of England (Europe/England), and Educate Girls US (Asia/India programs). Sources and photo licenses: `docs/community-charities.md`. These are nominees, not claimed partners or recipients of the $7,350 historical aggregate.
- Restored the four-card production ballot in code with nonbinding future-giving copy, official-site links, and representative licensed stock photos. No donations/transfers are performed.
- Added migration 0015 to accept real charity IDs while retaining historical votes; new `-charities-v1` rounds prevent prototype votes being assigned to real organizations. Apply on staging first. Production migration/deploy remains owner-run.
- Native Community copy/photos and the smaller Discover completion button need a new iOS candidate; build 29 is unchanged. Do not submit the store draft with old screenshots or until the owner finishes build 29 purchase/unlock/restore/notification checks.

Verification for Community source `da2343d`: required typecheck and all 198 tests passed, including production shortlist validation, rejecting legacy IDs, vote persistence and account isolation. Debug simulator build passed. Inspected all four cards and official-site detail in the running native app against a local Worker; CAMFED vote saved and displayed correctly. Local test only, no production writes. Screenshot: `/private/tmp/hercrown-community-real-charities-light.png`.

Staging rollout blocked before deploy: Cloudflare rejected the D1 migration request with account authorization error 7403. Migration 0015 has not been applied remotely and neither environment has received this change. Owner asked to re-authenticate via `npx wrangler login`; retry staging migration/deploy from a clean checkout after access is restored. Production migration/deploy remains human-only under AGENTS.md. Temporary localhost simulator configuration was restored in source after visual testing; no localhost archive was created.

Staging blocker resolved after owner OAuth login on November 10. Migration 0015 applied successfully and staging deployed from clean tracked source `b14bd73f4b79d3ac67ac9c78c0e285f427aaae81`, Cloudflare version `32d992fc-343f-4deb-9e63-635ffa9faf2a`. Live smoke checks passed: /health, guest authentication, four real Community profiles, CAMFED vote persisted after reload, and a second guest saw no inherited vote. Production remains unchanged. Normal staging simulator app rebuilt/reinstalled after local visual testing. Matching native candidate still required before production rollout.

### November 10 — owner-selected people-photo Community preview

- Owner selected shortlist items 1, 3 and 4: Mercy Multiplied (USA), House of Grace (Thailand) and Meninadança (Brazil), alongside Sharing the Mission (Nigeria) with the exact owner-supplied group photo. Updated native bundled card assets, official program descriptions/links and local interactive web preview. Reuse permission and photo-specific attribution/participant publicity clearance remain unconfirmed; this revision is local review only and must not be distributed until cleared.
- Migration 0016 preserves legacy ballots and permits the revised IDs. New `-charities-v2` rounds prevent earlier nominee votes being reassigned. No production or staging changes made in this revision.
- Verification: `npm run check` and all 198 API tests passed; Debug simulator compilation succeeded. Local browser preview visually inspected with all four authentic images, names and categories. Native revised server/card combination still needs device verification before a release candidate. Screenshot: `/private/tmp/hercrown-selected-community-preview.png`. Initial verification was interrupted by low disk space; disposable agent-created simulator build caches were removed, preserving archives and user files.
- Remaining public-release gates: clear selected photo reuse (or replace with cleared assets); migration 0016/staging smoke test then owner-run production migrations 0015–0016/deploy from a clean commit; archive matching final native candidate; production-connected purchase→Plus unlock→restore and notification/onboarding smoke tests, signed Superwall webhook and Tinybird production event confirmation; current App Store screenshots; final annual/monthly attachment/metadata/privacy/agreement availability checks; submit for Apple review. Manual release remains owner-controlled, with Main audience changed from sandbox-only to non-entitled users immediately before release after approval. Return offers remain off.


### Permission update from owner, November 10

Owner confirms photo-sharing permission for the selected Meninadança, Sharing the Mission and House of Grace images. This supersedes the pending-permission notes for those three selections; permission correspondence is held by the owner and has not been independently inspected. Mercy Multiplied permission is not confirmed: removed its official program photo from native/preview card assets and substituted existing Pexels stock photo 6646918, explicitly identified as representative, not Mercy participants or staff. Pexels license checked at https://www.pexels.com/license/; do not imply endorsement. No staging/production deployment or TestFlight upload in this update.

Final permission-update verification: required typecheck and all 198 API tests passed; Debug iOS simulator build succeeded. Updated web Community cards visually checked with the replacement Mercy stock image and the three owner-approved program photos. Updated preview remains local; production and TestFlight are unchanged.


### November 10 — selected Community staging rollout and build 30

Staging deployed from clean tracked source `4c169c8` with migration 0016, Cloudflare version `086029b7-f5a4-4e41-8adb-3243952349ca`. Live smoke checks passed: health 200, four selected nominees, charities-v2 round, persisted House of Grace test vote, and a second staging guest with no inherited vote. Production remains owner-run. Preparing build 30 with standard Release (production API, no HC_STAGING_TESTFLIGHT), current Community photos, Discover completion control and updated legal credits. Three organization photo permissions confirmed by owner; Mercy uses labelled representative licensed stock. No App Review submission or public release is authorized by this build upload.

Build 30 archived successfully from clean source `dc7ee54dea6b9d6b35c42bb53bdc821d455b6b94` at `/private/tmp/hercrown-build30/HerCrown.xcarchive`. Verified 1.0 (30), bundle com.hercrown.app and production endpoint in the archived binary. Required typecheck and 198 API tests passed. Revised native Community page inspected in the simulator against the deployed staging backend: four selected names and matching photo assets display. Command-line export hit Xcode's saved-account access error; Organizer upload in progress.

Owner applied production migrations 0015–0016 and deployed source `dc7ee54` on November 10; provided Cloudflare version `bdf7baed-5c81-49e4-ae0b-b63119ac2496`. Read-only post-deploy checks returned health 200 with env=production; privacy, terms, support and credits all 200; unauthenticated Community correctly returned 401. No production guest account or test vote was created by the agent. Owner's production-connected device ballot/purchase/restore/notification tests remain pending.


Owner clarified Discover completion during build 30 upload: retain the circle/tick icon, not a text capsule. Corrected to a 10 pt outlined/filled circle tick beside list verse references (12 pt beside featured reference), with a separate 44 pt accessible tap target. Completion fading/reordering/persistence remain unchanged. Build 31 supersedes build 30 for tester distribution; do not assign build 30 to groups.

Build 30 upload completed and Apple processed it VALID (`3c798fd9-c77f-4547-982a-6c8663143735`), but the owner clarified the Discover icon during upload. It is superseded by build 31 and was not manually assigned to external Beta.

Build 31 archive succeeded from clean source `916b46e` at `/private/tmp/hercrown-build31/HerCrown.xcarchive`. Verified version 1.0 (31), com.hercrown.app, and production API endpoint. Typecheck and all 198 API tests passed; Debug simulator build passed and the small circle-tick was visually inspected beside featured/list references (`/private/tmp/hercrown-build31-discover-circle.png`). Owner also confirmed the button behavior works. Organizer upload is in progress; processing and tester availability are not yet confirmed.

Build 31 TestFlight delivery verified November 10: Apple build `658393a0-604f-475f-a1d8-fc539edb106e`, processing VALID, audience APP_STORE_ELIGIBLE. Testing notes saved and auto-notify enabled. Assigned existing external Beta group `20c28d43-2861-4a95-a0be-dc4cc303e4af`; submitted required beta review and final API state became external IN_BETA_TESTING. Internal state was READY_FOR_BETA_TESTING; Apple does not permit manual assignment to the existing Team auto-managed internal group. Use the external Beta group/link for verified tester availability. Build 31 supersedes 30 and includes the owner-corrected small circle-tick alongside verse references. Archive source `916b46e`; production backend remains owner-deployed `dc7ee54`, Cloudflare version `bdf7baed-5c81-49e4-ae0b-b63119ac2496`. No public App Review submission or release performed. Final device checks and selecting the final build on the App Store review draft remain pending.

### 2026-11-10: Discover loading and featured completion follow-up
- Owner reports build 31 voting, purchase, Plus unlock and restore passed; notification opening remains untested.
- Discover now requests an editorial catalog (`includeText=false`), avoiding up to twelve licensed chapter requests before displaying its titles. Scripture is still fetched in the selected translation when opening a passage. Default API responses remain compatible with existing builds.
- Featured completion fades out before swapping stable verse identities, then fades in the replacement; tiny circle/tick controls remain unchanged. Stale translation responses are ignored.
- Reader keeps its toolbar accessible while loading and offers KJV offline immediately.
- Production health returned 200 (~0.49 s). Pre-change staging NLT Genesis 1 returned 200 (~1.01 s); NLT Discover returned 200 (~0.66 s). The reported outage was not reproduced; licensed reading still depends on provider/network availability.
- Validation: typecheck/content checks, 202 API tests, Debug simulator build passed. Four new regression cases ensure Discover catalog does not call a failing translation provider. Native visual check and staging rollout follow below. No production deploy or new TestFlight build yet.
- Staging deployed from clean source `2297d91`: Cloudflare version `9ed290dc-084c-4d72-a578-56022a049b9b`. Live NLT catalog smoke: HTTP 200, 72 cards, no text fetch/pagination, ~455 ms.
- Follow-up native check caught a LazyVStack identity collision between the incoming featured passage and its prior list row. Featured IDs now have their own namespace; simulator confirmed the next passage renders in the full featured layout after completion.
- Offline clarification: loading/error screen now offers KJV, BSB and WEB directly, while the translation toolbar stays available. All three load from bundled JSON with no network dependency. Debug build passed; simulator confirmed BSB selection renders the bundled passage. Full airplane-mode device check remains to be done in the next build.
- These native changes are not in TestFlight build 31. Production backend remains unchanged pending owner redeploy.

### November 10 — build 32 candidate
Owner requested the latest fixes in TestFlight. Build 31 is already uploaded and cannot be replaced, so the next upload is 1.0 (32). Includes immediate access to bundled KJV/BSB/WEB during online loading, accessible reader toolbar, lightweight Discover catalog request, and featured-card fade/identity correction. Production Release endpoint; return offers remain disabled. Backend catalog improvement is deployed to staging only; owner must run `cd ~/Downloads/bible-scroll-ios-build-kit/apps/api && npm run deploy:production` to activate it on production. Existing production response remains compatible until that deploy.

Build 32 archived from clean source `6fd7cf8` at `/private/tmp/hercrown-build32/HerCrown.xcarchive`; archive confirms 1.0 (32), com.hercrown.app. Required check and 202 tests passed; native simulator verification completed in the preceding fix. Xcode Organizer upload started.

November 10 App Store readiness recheck (Apple API): version 1.0 PREPARE_FOR_SUBMISSION, release MANUAL, age FOUR_PLUS. Annual `6830439735` and monthly `6831699380` both READY_TO_SUBMIT. Current selected App Store build remains 29 until the new candidate processes. All six APP_IPHONE_61 screenshot assets are COMPLETE; upload completeness does not establish that every screen matches final UI. Listing/review notes use $39.99 annual with eligible 7-day trial, $5.99 monthly without trial, weekly retired and return offers off. Review notes cover guest access, optional personal-prayer provider processing, restore and deletion. Browser session expired; privacy-label verification/publishing requires owner sign-in. No public submission or release performed.

Build 32 upload completed successfully in Xcode Organizer on November 10. Apple processing/tester assignment pending below. Annual introductory-offer API confirms ONE_WEEK/FREE_TRIAL across 175 territories; monthly has zero introductory offers. Existing screenshot preview inspected: uploaded artwork still contains older Home/Discover layouts, so refresh those before public review.

Current ordered submission gates:
1. Owner redeploy production (`npm run deploy:production` from apps/api) and provide Cloudflare version, then read-only health verification.
2. Make build 32 available to Beta and select it on the version 1.0 draft. Do not submit until device checks below pass.
3. Owner test build 32: offline switch from NKJV to bundled KJV/BSB/WEB; notification opening with app backgrounded and fully closed; quick purchase/restore regression. Prior build 31 purchase/unlock/restore and voting confirmed by owner.
4. Finish browser App Privacy audit for personal-prayer inputs and private suggestions; publish corrected label. Browser sign-in requested, pending.
5. Refresh outdated listing screenshots, confirm annual/monthly attached and parked products excluded; verify Paid Apps agreement/availability in signed-in dashboard, production webhook/Tinybird event evidence, then submit for App Review. Manual release remains selected; owner releases after approval and launch audience switch.

Build 32 final delivery verified: Apple build `7930b8c7-41be-45b5-a899-f0bcf37b5950`, processing VALID, audience APP_STORE_ELIGIBLE, non-exempt encryption false. Testing notes saved and auto-notify enabled; existing external Beta group `20c28d43-2861-4a95-a0be-dc4cc303e4af` assigned. Required beta review submitted; final internal and external states both IN_BETA_TESTING. Source `6fd7cf8`. Selected build 32 on version 1.0 App Store draft and verified selection via API. Public review has NOT been submitted, manual release remains unchanged. Apple intermittently returned HTTP 500 during processing checks; retry verified final success. Owner production redeploy and signed-in browser privacy audit remain pending, along with final device checks and screenshot refresh.

### November 10 — owner production redeploy after build 32
Owner supplied successful `npm run deploy:production` output: Cloudflare version `7750d96a-ecde-4c29-a782-df909139cbb6`. Current checkout at verification was `cabacdf` with no tracked changes (backend fix introduced in `2297d91`); deployment output itself does not embed a source SHA. Read-only verification passed: /health 200 with env=production; /legal/privacy, /legal/terms and /legal/support 200; unauthenticated Discover catalog request correctly 401. No production accounts/data created by agent. Authenticated production Discover speed and airplane-mode/notification checks remain device tests on build 32. Production deploy gate is now complete; privacy audit/browser sign-in and current screenshots remain pending before public App Review submission.

### November 10 — reader loading presentation correction after build 32
- Normal online translation fetch now shows only a neutral spinner/loading label; removed premature connection warning and bundled-Bible choices from that transient state. Toolbar remains available throughout.
- After a failed request, KJV/BSB/WEB are individually outlined selectors using Theme text/canvas/border in light and dark mode, rather than default blue links. Retry uses the app's secondary button style. Only a network failure is described as offline; provider/server failures use neutral unavailable copy.
- Verification: required typecheck and all 202 API tests passed; Debug simulator build passed. Native NKJV switch visually showed the clean loading indicator without the former warning/options. Error-selector styling checked in source; offline physical-device check remains pending. This correction is local and committed, not in already-uploaded TestFlight build 32. No backend changes or production deploy required.

### November 10 — final candidate build 33
Owner requested the final push. Preparing 1.0 (33) with the last native loading-screen correction: no premature offline warning during normal online fetching; individually outlined KJV/BSB/WEB choices after failure, with neutral appearance-aware styling. Standard production Release configuration, return offers off. Backend already owner-deployed version `7750d96a-ecde-4c29-a782-df909139cbb6`. Remaining reported notification/offline device checks and App Store browser sign-in requested while archiving. No public App Review submission yet. Low disk space: removed only clean agent-created source worktrees for builds 30–32; retained every archive and user asset.


### November 10 — build 33 delivery and paused App Review preparation
- Owner confirmed build 32 notification opening passed with the app backgrounded and fully closed, and bundled KJV/BSB/WEB passed airplane-mode testing. Earlier purchase, unlock, restore and Community tests were also confirmed.
- Build 33 archived from clean source `722feba`, uploaded successfully in Xcode, processed VALID and selected on version 1.0. Apple build ID `2916d4f1-fb07-4ad7-9f2e-78d558f3d76a`. TestFlight Beta assignment and beta review completed; internal and external states both IN_BETA_TESTING. Production backend remains owner-deployed Cloudflare version `7750d96a-ecde-4c29-a782-df909139cbb6`.
- Signed-in dashboard verified published App Privacy includes Sensitive Info; Paid Apps and Free Apps agreements, bank account and W-9 all Active. Review draft contains only Plus Monthly and Plus Yearly; weekly and return-offer products excluded. Manual release remains selected.
- Read-only aggregate Tinybird query verified environment=production product events, sandbox restore_completed and server-only verified billing events (subscription_started, trial_started/conversion, renewals). No personal event fields were queried.
- Owner paused submission while the app version was being added to the existing review draft. No Submit for Review or public Release action was performed. Keep submission paused until the owner resumes.
- Replaced outdated screenshots with current native CUA captures. Owner requested the original artwork, captions, frame positions, texture and illustration decorations be restored, with pure white backgrounds. The original PNGs remain untouched; reproducible composition lives in `scripts/app-store/compose-final-screenshots.py`, output `design/app-store-screenshots/build33/decorated-white/`. Only phone-display content is replaced; original decorative pixels are preserved. Current capture set visually inspected as a six-page contact sheet. App Store asset replacement status follows below.

All six decorated-white 1206×2622 RGB PNGs uploaded and ordered in App Store Connect. Read-back: three COMPLETE, three UPLOAD_COMPLETE with no errors (Apple processing pending). Confirmed sampled outer backgrounds are RGB 255/255/255. Original screenshot source files were not modified. Required check passed and all 202 tests passed; the first restricted test attempt could not bind localhost, and the authorized rerun passed. Public review remains paused.


### November 10 — owner requests automatic release
Apple API updated version 1.0 to `releaseType=AFTER_APPROVAL` and read back the same value; state remains PREPARE_FOR_SUBMISSION. No review submission performed. This supersedes manual-release references above. Superwall Main audience must be configured for production before submission/approval, rather than after approval. Availability audit found 175 enabled storefronts and availableInNewTerritories=true, which does not match the earlier U.S.-first launch plan. Asked owner whether to restrict app availability to USA only; no territory changes made pending answer. Owner screenshot also shows the current draft contains two subscriptions but lacks the app version and subscription group; these must be added together when the owner resumes submission work.

### November 10 — worldwide launch configuration and Superwall targeting
- Owner approved worldwide availability and explicitly excluded mainland China. Apple API read-back confirms 174 app territories enabled, CHN disabled and USA enabled. Plus Yearly (6830439735) and Plus Monthly (6831699380) were still USA-only; both now have the same 174 available territories, excluding CHN, verified by read-back. This is availability configuration, not a certification that every regional licensing/privacy obligation is satisfied.
- Superwall Main campaign 116616 / audience 199478 is now active in Production with no sandbox filter and entitlement targeting still restricted to users with no active entitlements. Published Main paywall 289087 remains the 100% allocation, holdout 0%. Verified active onboarding, settings, study and plan placements. Proof: /private/tmp/hercrown-superwall-launch-audience.png. This completes the audience switch required before automatic approval release and supersedes earlier instructions to switch after approval.
- Superwall catalog verifies Yearly $39.99 with one-week trial and Monthly $5.99 with no trial, both mapped to pro. Main annual renewal text uses products.primary.price rather than a literal US amount. Full non-US paywall currency/weekly-equivalent presentation still needs validation before declaring worldwide checkout audited. No paywall design changes were published in this pass; the editor crashed during inspection and was refreshed to its saved state.
- Decline offer paywall_decline placement remains paused (Resume placement shown), sandbox-only audience retained. Native returnOffersEnabled remains false; both $19.99 paths stay off for 1.0.
- EU sales are not automatically blocked by a separate EU tax registration requirement: Apple's agreement describes Apple collecting/remitting applicable transaction taxes in listed EU regions. Developer business/income taxes remain separate. DSA account compliance shows Active; app-specific trader declaration and translation territorial permissions still need confirmation. Official references: https://developer.apple.com/support/terms/apple-developer-program-license-agreement/ and https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/ .
- Version 1.0 remains AFTER_APPROVAL and PREPARE_FOR_SUBMISSION. Submission stays paused for owner artwork completion; no Add/Submit for Review or release action performed.
- Documentation-only verification: npm run check passed and all 202 tests passed (14 files). Restricted first test attempt could not bind localhost; authorized rerun passed. No native/server code changes or deployment in this pass.

### November 10 — EU trader verification blocker identified
- App Information → App Store Regulations & Permits explicitly identifies Her Crown as non-trader and links to Complete Compliance Requirements. The Business DSA row showing Active does not establish verified trader contact information; earlier account-status wording must not be read as trader verification complete.
- Opened Contact Information Verification. Public address, phone and email fields are empty, Next disabled. Apple accepts a P.O. Box. Requested the owner's intended public address and confirmation of public phone/email; the existing account city/state details are inconsistent and were not copied. No contact data entered or declaration submitted. Browser left at the form for the owner; App Review remains paused.

### November 10 — owner final iPhone/iPad and header exports restored
- Restored supplied ZIP artwork without changing decorations, layout or text. Local copies: design/app-store-screenshots/owner-final-nov10/ . Six iPhone PNGs are 1320×2868; six iPad PNGs are 2064×2752. Visually inspected a contact sheet of all artwork.
- Uploaded and ordered six screenshots in APP_IPHONE_67 (5d3f5449-4f27-4e89-aec8-7f9b309ab120, Apple's API name for its large-iPhone slot) and six in APP_IPAD_PRO_3GEN_129 (b7618c79-642c-4460-9d13-0254e4b8fdba). All 12 assets read back COMPLETE with no errors. The former APP_IPHONE_61 set was already empty when inspected; no existing screenshots were deleted in this pass.
- Uploaded supplied Header-3840x1646.png and separate Search-5244x2950.png through App Store Connect; each UI slot reads 1 of 1 Asset. Header preview visually verified. Proof: /private/tmp/hercrown-restored-header-asc.png . No app review submission or release action performed.


### November 10 evening — final review package assembled
- Owner resumed remaining launch preparation after approving the centered white/daylight header. Saved `Her-Crown-Centered-Daylight-Header-5244x2950.png` in `design/app-store-screenshots/owner-final-nov10/`; uploaded Header and visually checked Apple's actual center crop. Separate Search Results artwork and screenshot sets retained. Asset generation used the built-in image tool; final PNG exported at 5244×2950.
- Added version 1.0/build 33 and Plus group to the existing draft containing annual/monthly. Apple now shows four ready items; prior missing app-version/group validation errors are gone. No Submit for Review action performed. Proof: `/private/tmp/hercrown-review-package-ready.png`.
- Removed unverified `#1` subtitle claim; API read-back confirms `Daily Bible for women`. Corrected Monthly review notes from U.S.-only to supported-storefront availability with local pricing and China excluded. Annual API confirms 175 ONE_WEEK/FREE_TRIAL entries; Monthly has zero introductory offers. Six iPhone and six iPad screenshots all COMPLETE.
- Signed-in dashboard recheck: App Privacy published with 12 types including Sensitive Info; third-party rights Yes; app-specific DSA declaration trader. Business shows Paid/Free agreements, bank and W-9 Active, but DSA verification **In Review**. Do not represent EU verification as approved.
- Superwall catalog displays annual $39.99/one-week trial and monthly $5.99/no trial. Editor inspection shows monthly weekly-equivalent uses `products.monthly.weeklyPrice` and monthly billing text uses `products.monthly.price`; this inspected draft is not evidence of a completed non-US device checkout. No unrelated editor draft was published. Worldwide publisher territorial/sharing/widget rights remain an owner licensing verification item.
- Production /health (env=production), privacy, terms, support and credits returned 200. Required check and all 202 tests (14 files) passed. No native/server changes or deployment. Production deploy guide refreshed to replace obsolete pending-migration/manual-release instructions.
- Remaining: final owner go-ahead for public submission (automatic release after approval), Apple DSA review, and public production purchase/restore after availability. A never-installed-device first-run test is still not independently evidenced; earlier onboarding and physical-device checks are owner-reported.

### November 13 — TikTok reference audit for Her Crown
- Resolved all eight supplied TikTok short links and reviewed public metadata for those posts plus @heavendigitals. Saved canonical accounts, caption patterns, formats, dates and metric snapshots in `marketing/references/tiktok-video-and-slideshow-references.md`; preserved its earlier screenshot notes. Full assessment: `reports/Her Crown TikTok reference review.md`, with evidence in `research_notes/Her Crown TikTok reference review/`.
- Inspected first/final slide pairs for Aurora, Basalt, Rye and an additional Heaven Digitals example. Videos and intermediate slides were not reviewed. Prioritized Heaven's situation-to-passage structure and Basalt's habit-to-app bridge for original Her Crown content.
- Account cadence remains unverified because complete dated profile histories were unavailable. Proposed a clearly labeled 14-day experiment: one daily post, four slideshows and three videos per week, with results compared at consistent post ages. No posting, scheduling, media reuse or attribution implementation performed.
- Documentation-only verification: `npm run check` and all 202 tests across 14 files passed; final `git diff --check` passed. No app code changes or deployment.


### November 19 — billing analytics, email consent and account deletion

- Confirmed the live trial was accepted by both Superwall endpoints, then Tinybird retained the staging copy because its replacement key omitted environment. Scoped billing IDs by environment, ignored live events on staging, and await durable queue acceptance; signed retries repair interrupted queue sends without applying entitlements twice.
- Apple purchase authentication is not a reproduced Her Crown login bug. Account emails already persist through Sign in with Apple. Added optional verified-account email updates consent (default off, versioned, reversible, deleted with account) and an owner export query; no mailing vendor/campaign enabled. Migration 0017 must precede rollout.
- Included the guest deletion endpoint/older Apple session reauthentication fix, preserving the intended account on mismatch and explicitly reconfirming deletion. Corrected artwork build inputs/outputs without disabling sandboxing.
- Required check and 208 API tests pass; simulator build and 29 native tests pass. Recovery dry-run read one verified retained initial purchase, found one missing production row, made zero writes. Recovery is owner-run after production deployment; instructions in docs/billing-email-update.md. Native distribution and production remain pending.

Staging rollout verified November 19: clean isolated checkout `/private/tmp/hercrown-billing-email-update`, source `fa89f54`, Cloudflare version `0d663a79-e61c-4822-b3c3-3543280dc51c`. Migration 0017 applied on staging. Live staging smoke checks passed guest sign-in, default email opt-out, guest opt-in rejection, forged webhook rejection and deletion of the disposable test guest. Native app launched into Your account and guest layout inspected (`/private/tmp/hercrown-account-update.png`); real-device Apple sign-in and signed-in consent layout still require owner validation. Production deployment/recovery and native upload have not been performed.

Production follow-up November 19: owner applied migration 0017 and deployed source `fa89f54` as Cloudflare version `9b0767cd-1d25-456e-a499-6ecb80b3512a`. Owner ran billing recovery; ingestion succeeded but immediate readback was not yet visible. Subsequent read-only dry-run returned examined=1, missing=0, skipped=1. Independent Tinybird `FINAL` aggregate confirms exactly one production, non-sandbox `trial_started` event today. The historical staging copy also remains; filter reporting by production and sandbox=0. No repeat recovery ingestion was performed. Native consent/deletion changes still await the next app update.

### November 19 — UI review and expense tracking before the next release

- Owner requires all intended UI changes to be reviewed and tested together before any next archive/upload/release. Opened the original Discover web mockup and the installed staging-connected Debug app in Simulator. Comparison screenshots: `/private/tmp/hercrown-discover-reference.jpg` and `/private/tmp/hercrown-discover-current.png`. Current source places REFLECTION alongside the verse instead of the theme, and the 44-point checkmark row increases metadata height. Preserve a small checkmark on the verse line while matching the reference text grouping. This pass captured the comparison; it did not modify Discover.
- Captured requested remaining work: remove repeated Plus badges while preserving paywall access controls; investigate an onboarding-completion Lock Screen reminder (distinguish a user-added widget from a Live Activity); standard StoreKit rating requests after meaningful use with separate optional feedback; verified free English/Spanish editions; prioritize CSB once app-specific rights are confirmed. No custom five-star gating. No claim that iOS can place a widget before first app launch.
- Created `outputs/hercrown-2026-11-19/Her-Crown-Expense-Tracker.xlsx` with Subscriptions and Payments. Owner reconfirmed API.Bible at $69/month and corrected partner's name to Tomi. Nathan and Tomi each reported $100 ChatGPT payments; dates, billing periods and app allocation remain unverified, so these are recorded as $200 reported payments rather than silently added to monthly recurring cost. Other service amounts remain blank/unverified. Formula checks returned $69 confirmed monthly, $200 reported payments and eight costs needing confirmation; a temporary newly confirmed $20 monthly cost raised the budget to $89, then restored to $69. Both sheets rendered and inspected.
- AFFiNE's official MCP documentation describes read-only defaults and read/write limited to development/canary deployments. No AFFiNE tool is connected in this session; no workspace credential was requested or modified.


### November 19 — build 34 local UI and offline editions

Implemented Discover's reference/check row with theme + REFLECTION directly underneath, removed repeated study Plus badges while retaining paywall/server gates, added usage-based native review and separate feedback invitation, and implemented first-launch onboarding Live Activity with resumable Keychain draft. Existing email-consent and account-deletion work remains included. Build number set to 34; not archived or uploaded.

Added public-domain ASV, YLT, Darby, Webster, MSB and Spanish Reina-Valera 1909, whole-text compared against eBible VPL with pinned checksums and source omissions preserved. CSB remains pending licensing. New backend catalog migration 0018, seeds, analytics validation and content routes verified on staging.

Verification: `npm run check && npm test` passed (209 API tests); Xcode build/native tests passed (34). Actual Simulator Discover light/dark and Spanish reader inspected. Staging deployed from clean source commit `3b13d8f` in `/private/tmp/hercrown-build34-stage` to Worker version `e7fece1a-1c91-479d-a666-41b57a9a1e71`; new catalog/chapter/Discover readback passed for all six editions, temporary guest removed. No production writes/deployments. Physical-iPhone Live Activity and review-dialog checks remain before release. Details: `docs/build-34-update.md`.


### November 19 — Xcode test session and guest chapter offer

Owner approved installation of Apple's required Xcode system components; installation finished, HerCrown opened in Xcode, iPhone 17 Pro (iOS 26.2) selected, and Xcode reported Running HerCrown. The Simulator UI is now exposed by Apple's Device Hub (`com.apple.dt.Devices`), rather than a standalone Simulator.app.

Owner selected a guest offer after completing a chapter: same-day first opportunity, dismissible standard campaign, automatic request cooldown of 24 hours, exclusions for signed-in/Plus users, and reader-modal/foreground/account safeguards. Added five policy/reading-boundary tests (39 native tests total) and analytics event; API checks/tests passed (209). Staging analytics Worker deployed from clean commit `9ddca94` to `da2a4107-dd5c-40b8-8b7a-fbb74d3cb9a9`. Decision 0014 records the rule.

Live UI testing found nested chapter/verse scroll targets could show the preceding chapter after selecting another one. Flattened the reader into direct stable verse targets (clean local source commit `99dbd70`); native tests passed (39), and actual Simulator screenshots confirmed selected Psalm 117:1 and next-chapter Psalm 118:1 now match their headers. Also count the initial visible verse so short chapters can qualify for the guest offer. Final first-verse build/test and hands-on paywall check are tracked in this chat; do not claim the paywall presentation verified until observed. Xcode's pre-existing fresh-start-on-every-run argument is now disabled to preserve test sessions. No production deployment, purchase, archive or TestFlight upload.


Final local source commit `322fd61` in the clean build-34 checkout includes the initial-verse correction. Native build/tests passed again (39); API checks/tests remain green (209). Final Simulator runtime launched at Psalm 117 for live chapter-boundary verification. Computer control then failed to locate all Xcode/Device Hub windows (`cgWindowNotFound`), including after resetting its session. Owner asked to bring the test window forward; actual automatic paywall presentation/dismissal remains unverified. Do not ship or describe that live check as passed yet.


### November 19 — verified guest trigger, pending visible campaign check

Owner brought the Simulator forward. Actual trace verified Psalm 117:1 → 117:2 → 118:1 queues an eligible guest request with billing configured, online/active state and matching account. Superwall presentation was not observed. The live trace also exposed loss of read verses when navigation crossed out of a chapter and returned; the tracker now retains the last 32 chapters and offers each completed chapter once per reader session.

Daily cooldown now begins on Superwall onPresent, not on request; failed/skipped requests have only a five-minute in-session retry backoff. Debug-only eligibility, callback and bounded reading traces assist this test. Automatic paywall visible/dismissal check remains pending owner's manual Simulator gesture because computer control repeatedly lost its native window. No purchase attempted.

Final source `1fb40ba` in clean `/private/tmp/hercrown-build34-stage`; `npm run check && npm test` passed (209 API tests), native suite passed (41) on a separate “Her Crown Guest Policy Tests” Simulator so the owner's visible device was not interrupted. Staging Worker remains `da2a4107-dd5c-40b8-8b7a-fbb74d3cb9a9` from `9ddca94` (API code unchanged since). No archive, TestFlight upload or production changes.


### November 19 — paywall latency reduced and live check passed

Owner reported the guest paywall appeared but took about three seconds. Added eligible-guest background preloading of the existing standard campaign during reading, deduplicated per current guest identity and reset on logout. Removed the fixed 600 ms boundary pause; existing StoreKit, audience, entitlement and presentation/cooldown checks remain. Temporary verbose reader/eligibility traces removed. Debug-only preload timestamp and request-to-onPresent timing remain.

Live isolated guest test on “Her Crown Guest Policy Tests”: preload started before chapter completion; Psalm 117:1 → 117:2 → 118:1 displayed the actual Superwall main paywall. Measured request-to-presentation latency **827 ms**, including StoreKit preflight. Screenshot saved at `outputs/hercrown-2026-11-19/build34/Guest-Paywall-Preloaded.png`. Closed using the dismiss control and visually confirmed free reading at Psalm 118:1. No purchase attempted. This resolves the previously pending visible-presentation/dismissal check; it is one local measurement, not a network-wide performance guarantee.

`npm run check && npm test` passed (209 API tests); final Xcode native tests passed (41). Clean local source commit `fd11102` in `/private/tmp/hercrown-build34-stage`. API unchanged, staging Worker remains `da2a4107-dd5c-40b8-8b7a-fbb74d3cb9a9`. Verified app installed back onto the original test Simulator while preserving its account and cooldown. No archive, TestFlight upload, production deployment or production data writes.


### November 21 — four native design handoffs

- Added Faith Medals Home entry, five collections, snapping sprite-art carousel with light selection haptics, grid, real account-scoped progress and qualified PNG sharing. Replaced prototype examples with 14–365-day reading/chapter goals and honest difficulty tiers.
- Verified and imported all 66 canonical Bible-book illustrations; integrated 40-point aspect-fit artwork in the chapter picker.
- Added persisted Pink appearance with owner’s `#31222B` accent and supplied semantic palette. Font scaling and welcome layout explicitly left unchanged. Migration 0019 preserves existing preferences/onboarding and account-deletion cascade.
- Added two-step Mystery Gift fallback, gated by real StoreKit offer/eligibility/renewal terms, with preview purchase disabled and free exits. Existing disabled $19.99 campaigns untouched. Genuine discounted-product checkout is a release follow-up.
- Staging migration 0019 and Worker `6b11f02b-a93a-47b5-a2ee-518b80295f67` from clean API source `724e86f`; disposable guest verified all appearance readbacks, unchanged onboarding, real progress and event acceptance, then deleted. No production access.
- Checks: API type/content check and 210 tests passed; final full Xcode run 48 tests passed (zero failures/skips), iPhone 17 Pro/iOS 26.2. Running UI inspected for medals, book picker, Pink Home/Discover/reader, and gift previews/reveal/free exit. Physical haptic strength and actual discounted checkout remain manual follow-ups.
- Build remains 34, no archive/upload/release. Details: `docs/four-handoffs-update.md`.


### November 21 — Simulator appearance switching

The isolated Simulator had been left running with the screenshot launch argument `-hcPreviewAppearance dark`. The old preview override always won over an explicit Settings choice, so selecting Pink could save correctly while the screen stayed dark. Centralized preview resolution in `AppearancePalette`, made explicit appearance edits dismiss the preview override, and removed any stored preview setting on an explicit edit. App and Settings now use the same resolved preference. Added a regression test for Dark preview → Pink choice → saved preference refresh → Light/System choices. Font/layout behavior remains untouched.

Verification: full native suite 49/49 passed including preview-precedence regression; API check and 210/210 tests passed. Final Debug build succeeded. Reopened the isolated Simulator without an appearance override, preserving its account/onboarding. No production changes or release.

Visible follow-up: selected Pink from the actual Settings appearance menu; the screen immediately changed to Pink. Terminated and relaunched with no appearance override; Home remained Pink after account refresh. Left that Pink Home screen open in Device Hub.


### November 21 evening — preserve whole words in Discover headings

The featured title “A peace beyond understanding” split its final word in the narrow artwork/text layout. Added a shared measured heading component for featured and list titles: retain the scaled design font when words fit; otherwise reduce the heading font until its longest whitespace-delimited word fits the actual column. Use native word wrapping with hyphenation off and unconstrained vertical height. Keep the full title, existing artwork, metadata alignment and ordinary reading font unchanged. Tests cover narrow widths, normal/enlarged heading sizes and actual TextKit line boundaries. The broader welcome-screen font-size work remains paused at the owner’s request.

Confirmed onboarding reminder implementation: Live Activity starts while onboarding is foregrounded (including welcome), updates setup progress and deep-links to the saved draft; completes/ends with onboarding. It is not a separate re-engagement push and a dismissed/expired activity is not automatically recreated. iOS Live Activities must be enabled; physical-device background/force-quit behavior still needs validation.

Verification: all 52 native tests and all 210 API tests passed; API type/content check passed. Running Pink Discover inspected in Device Hub: “A peace / beyond / understanding” displays without a split word; list headings remain complete. Left corrected Discover open. No production deployment/release.


### November 22 — TestFlight 34 prepared, Apple sign-in pending

Owner requested decline preview and a TestFlight build. Added test-only Settings → Sandbox testing → Preview decline offer with explicit design-preview label and purchases/restore disabled. Native tester entry/reveal visually verified. Added a separate staging Keychain service to protect live saved credentials when installing staging TestFlight over the public app. Full staging-configured native suite: 53 passed; API check/210 tests passed.

Staging Worker `36e23e0f-a710-44ca-a230-1cba2f63cb41` from clean `373988f`. Final Release + HC_STAGING_TESTFLIGHT archive from clean `9a99717`, build 1.0 (34), `/private/tmp/hercrown-testflight34-20261122/HerCrown-Staging.xcarchive`; verified app/widget version, staging endpoint, isolated Keychain and Live Activities.

Upload remains blocked: existing API key can access ASC but lacks cloud-distribution-signing permission; Xcode has no signed-in Apple account; alternate existing key authentication failed. Apple Accounts window opened; owner asked to sign in. No new TestFlight delivery, public release or production change yet. Genuine discount SKU remains READY_TO_SUBMIT (normal annual APPROVED), so actual discounted checkout is not signed off.


### November 22 — TestFlight version train correction

Xcode Apple Account sign-in verified. Distribution signing succeeded, but Apple rejected the upload because approved version 1.0 is closed to new builds. Set app and widget marketing version to 1.0.1, retaining build 34 and staging configuration. Archive will be rebuilt from the clean committed source; no public release or production changes.


### November 22 — TestFlight 34 upload accepted

Xcode account sign-in and distribution signing succeeded. Apple rejected the initial 1.0 upload because that release train is closed. Rebuilt from clean source `3580423` as **1.0.1 (34)**, keeping staging endpoint, isolated staging Keychain, tester controls and Live Activities. Archive: `/private/tmp/hercrown-testflight34-20261122/HerCrown-1.0.1-Staging.xcarchive`. Apple upload succeeded November 22 at 4:49 PM Eastern; processing/tester distribution is being checked. API check and all 210 API tests passed again; the unchanged native feature code previously passed 53 tests. No production backend or public-release changes.


TestFlight verification, November 22 at 4:53 PM Eastern: Apple build `2f3ae808-4974-4dc2-8a7c-be76b0dabe31`, version **1.0.1 (34)**, processing **VALID**, internal **IN_BETA_TESTING**, external **WAITING_FOR_BETA_REVIEW**. Existing Beta group assignment and staging-specific What to Test notes read back successfully. TestFlight Beta App Review submission accepted (**WAITING_FOR_REVIEW**); external installation awaits Apple. Source `3580423`; staging Worker `36e23e0f-a710-44ca-a230-1cba2f63cb41`. Genuine discount checkout, physical haptics and onboarding Live Activity background/force-quit checks remain manual testing items. Public App Store build 33 and production backend unchanged.


### November 22 — correct Bible book picker layout

Owner clarified that the approved artwork layout must be an illustrated grid rather than the existing compact list. Replaced book rows with proportionally scaled 150-point art above centered serif book names, grouped into Old/New Testament sections. Adaptive columns retain the handoff gallery’s two-column phone presentation and wider multi-column layouts. Removed row dividers/chevrons and visible chapter counts from the artwork grid; chapter counts remain accessible. Search, book selection and chapter navigation retained. This follows the owner’s clarified layout direction, superseding the earlier 40-point list integration. Build 34 already uploaded does not include this subsequent change; no new upload or production release. Verification pending.


November 22 layout verification: corrected Bible book grid built and visually inspected on iPhone Simulator. Selecting Genesis opened its chapters; searching John returned John/1 John/2 John/3 John under New Testament. API check and all 210 tests passed. Reattached mystery-gift ZIP README, preview HTML and light reference are byte-identical to the earlier handoff. Corrected native hero to the reference top-aligned cloud/flower/object positions and cloud width, removed extra reveal top gap, moved tester disclosure to footer, and retained original CTA wording with purchasing disabled in design preview. Invitation/reveal visually inspected and free-reading exit verified. Existing store-eligibility and purchase validation unchanged. Final Simulator build passed. Saved updated grid/invitation/reveal screenshots and refreshed comparison HTML under `outputs/hercrown-2026-11-22/comparisons/`. These corrections are local and not in uploaded TestFlight build 34.


Next-release requirement from owner: reproduce the approved two-step decline offer in Superwall with visual parity, activate its intended eligible audience only after real product/offer validation, and test trigger/reveal/purchase/restore/free exit before release. Native tester preview is not completion of that Superwall work. November 22 read-only billing audit confirmed zero missing verified initial purchases; deployed production/non-sandbox revenue endpoint shows one annual trial and $0 paid proceeds since November 19. No production writes or recovery replay performed.


### November 22 — owner review refinements and analytics snapshot

Lowered invitation CTA by removing the in-flow tester notice and reducing invitation bottom padding; retained visible preview notice as a noninteractive overlay. Invitation heading uses Baskerville semibold including italic second line; body uses DM Sans medium. Close circle now 32 points with 12-point symbol, retaining 44-point hit target. Both invitation and reveal built/visually verified in Simulator; comparison captures refreshed and book-grid tab requested in sidebar. API checks and 210 tests passed. No upload or production change.

Analytics read-only at approximately 6:53 PM Eastern: Apple Trends for Her Crown, October 22–November 21 UTC, reports 21 app units (20 USA/Canada region, 1 Africa/Middle East/India region). Tinybird production, sandbox=0, November 18 00:00 Eastern through current data: 22 new first-open installation IDs, 11 onboarding completions (50%), 5 distinct installs reaching final ready step, 58 opens, 9 passage-reading installs, 4 chapter-completing installs, 3 saving installs, 5 opening study tools. Active installations by Eastern day: Nov18=6, Nov19=11, Nov20=8, Nov21=6, Nov22=3. One verified annual trial is owner activity, zero paid conversions/proceeds. These figures include owner/team public-app use and reinstalls; they are not an organic-customer count. TestFlight/debug/staging excluded by available flags; older Nov10–14 production-tagged history excluded by date. Completion includes guest route and does not prove every guided step. Apple report is delayed through Nov21; installation telemetry through today is a different measure/window. Individual downloaders are not identifiable from these aggregate reports. Existing API key cannot access Apple analytics-report API, but signed-in Trends UI was successfully read.


November 22 offer proportion review: clarified comparison left is supplied reference and right is an actual saved native capture, not an interactive purchase flow. Reduced invitation heading 38→32 while retaining semibold; body 14→13 medium, line spacing 4→2; reveal heading 36→30 and price 39→34; tighter 10-point group spacing and 16-point card padding. Retained smaller close button and lower invitation CTA. Native build passed, invitation→reveal visually verified, comparison captures regenerated. API check and 210 tests passed. No TestFlight upload, Superwall activation or production changes.


### November 22 — measured offer footers and medal state color

Measured original reference phone interior at 376×830 design points: invitation primary ends 56 points above bottom; reveal primary ends 72 points above bottom; primary height 46. Replaced shared 48-point button style locally with 46-point offer style and set footer components/padding explicitly. Native iPhone Simulator captures measured exactly 56 and 72 points (3× pixels converted to points). Retained restored invitation sizes and regular-weight heading. Reveal now bolds only 25% off, uses 15-point body with explicit break after one-time, and has a taller 160-point minimum offer card. Both pages visually inspected; screenshots refreshed. API check/210 tests passed; native build passed.

Medal carousel and collection now fade only medals with zero progress, rather than every unearned medal. In-progress medals render with original saturation/opacity; qualification/share guards remain unchanged. Current Simulator account shows zero reading days/chapters and correctly remains locked. Simulator scrolling/dragging failed with noWindowsAvailable, so actual in-progress visual state is not yet signed off.

Owner proposed closed-envelope opening animation followed by a smooth reveal, and delaying gift delivery until a later app open after main-paywall dismissal. Recommendation discussed: next foreground session at least 24 hours after dismissal, once per account, recheck subscription/eligibility first, keep free exit; canceling StoreKit purchase sheet alone is not a decline. Timing/animation are proposals, not implemented or activated. Superwall parity, actual discount product approval/configuration and sandbox checkout remain next-release requirements. No production changes or upload.


### November 22 — next-day gift flow and branded setup reminder

Implemented accepted next-foreground gift timing: at least 24 hours after closing a main paywall, account-scoped atomic claim, membership/StoreKit eligibility checks, no repeat across devices, offline dismissal retry, and no trigger from purchase-sheet cancellation alone. New migration 0020 and authenticated endpoints; production native flag remains off. Preview uses original envelope artwork with a closed flap, hinged opening and smooth reveal; repeated taps are ignored, cancellation and Reduce Motion are handled. Native animation was visually inspected and recorded. Removed the long paragraph above the purchase CTA; concise renewal/no-trial terms remain in the price card.

Redesigned the onboarding Live Activity with original wreath/book artwork, smaller consistent rounded typography, plum Continue setup link and progress rail. The shared component is used by the actual widget and labelled native design preview. Layout tests pass at 298/358/500-point widths within 160-point height. Apple permission controls remain system-owned. API check and all 214 tests passed; all 54 native tests passed, including card layout. Physical-device Lock Screen/resume, actual eligible discount checkout, Superwall parity and medal in-progress visual verification remain release checks. No new TestFlight upload or production activation. Tinybird funnel source recognizes the gift event names; production endpoint deployment is still pending.


Staging rollout verified November 22, 2026 at approximately 7:52 PM Eastern: clean source commit `f0a9d23`; migration 0020 applied; Worker version `1b51aea7-99d4-4440-9c81-fcceb3e5cec3`. Disposable staging guest verified first-only scheduling, same-day suppression, next-day availability after backdating only that test row, one-time claim and no-repeat; guest deleted afterward. Initial Python client request was rejected with 403; accepted client header resolved access. Production untouched. Final native reminder capture measures approximately 156 points tall on iPhone 17 Pro and was visually inspected; before/after and envelope-animation recording added to the comparison page.


### November 22 — correct envelope opening after owner review

Owner rejected the first animation as a visual glitch. Replaced full-envelope opacity swapping and whole-hero movement with one stationary envelope front/ribbon and a continuously animated hinged flap. Letter appears behind the flap; the open pose rests for 750 ms after the 1-second opening. The invitation fades out before swapping layout without animation, then the offer fades in, avoiding animated constraint changes. Both the envelope and primary CTA trigger the same guarded sequence; Reduce Motion retains a short fade. Onboarding design unchanged. Native build passed and closed/open/final offer states visually inspected in Simulator. Updated actual recording in comparison page and dedicated animation preview. Required API check and all 214 tests passed. No deployment, upload or activation.


### November 22 — refine paper treatment and continuous contents reveal

Owner found the hinge version visually tacky and correctly noted that the letter faded in after opening. Removed letter opacity animation: it is present from the first frame behind the closed flap and lifts gently during opening. Flap switches depth behind the letter at its edge-on midpoint. Replaced flat procedural flap fibres with a native crop of the original artwork’s paper texture, subtle moving shading/shadow, small coherent envelope scale and eased opening. Separate invitation/offer page layouts now directly dissolve together, keeping the header steady and avoiding a blank screen or constraint morph. Opening lasts 950 ms, followed by 450 ms open hold and 550 ms dissolve. Onboarding unchanged. Native build passed; closed, opening-with-letter and final offer visually inspected in Simulator; revised recording and comparison refreshed. API check and all 214 tests passed. No upload or deployment. Visual acceptance remains with owner.


### November 22 — the letter becomes the offer page

Owner clarified the intended motion: envelope opens, its letter comes out, then that same letter unfolds into the offer. Replaced page dissolve with shared paper geometry. Original-texture paper is present inside from the start, stays behind the envelope front while lifting, then expands from its actual position into the offer surface. A subtle crease/shading settles away and offer content appears on the expanding sheet. Sequence: 620 ms flap, 380 ms extraction, 650 ms expansion, overlapping 300 ms ink reveal; interactive offer settles at approximately 1.82 seconds. Header remains steady; final offer layout/copy/prices unchanged. Reduce Motion uses the existing short fade; repeated tap/dismissal safeguards retained. Frame-by-frame Simulator recording verified continuous geometry and solid paper after removing an unwanted insertion fade. Native build passed; API check and all 214 tests passed. Updated dedicated letter animation preview and comparison recording. Owner visual acceptance pending; no deployment or upload; onboarding unchanged.


### November 22 — distinguish Faith Medal goals

Replaced generic Armor/Promises thresholds with nine distinct named chapter journeys plus existing reading-day minimums. Fruit habit milestones, Psalms-specific and Women/book goals retained. Added exact completed chapter identities to the authenticated progress response using existing database records, retaining all existing aggregate fields. Native progress matches unique required identities, never generic totals; old API/cache data cannot invent awards. Required reading list shows completed chapters and opens the selected chapter in the Bible. Cache rules version 2 recalculates changed Armor/Promises awards without changing reading history or unchanged collection dates. Added medal-only journey/view/open events. API check and all 214 tests passed; all 59 native tests passed, including five new cases for generic-vs-themed credit, exact/missing/duplicate chapter identity, minimum days, unique valid lists, legacy payloads and award-date migration. An existing alert test failed because a 60-second interval crossed a wall-clock hour; stabilized its test clock within one hour, without changing alert behavior. Native visual/link verification and staging rollout pending.


Staging/native verification completed approximately 9:04 PM Eastern November 22: clean source `9c8ffda`, staging Worker `e67037ab-88fd-4bae-afe2-ce5bb2f48a8c`. No migration required. Two disposable staging guests verified exact chapter refs, repeated-completion deduplication, account isolation, and reference removal after unmark; both deleted. Simulator visually verified Breastplate’s 30-reading-day + 10-specific-chapter requirement, expanded Righteousness list, and Romans 3 navigation from the first row. Saved `outputs/hercrown-2026-11-22/comparisons/medals-distinct-goals.png`. Final native build succeeded after removing an unnecessary standalone preview; the DEBUG collection selector uses the real Home entry/account. Production/App Store/TestFlight unchanged.

Animation discussion: close sampled frames reveal that the existing letter morph stretches the paper and grain rather than physically articulating folds, with a rotation handoff into screen-aligned geometry. This is a diagnosed visual limitation, not a signed-off realistic animation. A further articulated paper animation is separate from this medal-rule fix.


### November 22 — articulated folded-paper offer animation

Replaced the rectangular geometry stretch with a three-panel sheet. The envelope contains a folded panel with proportions derived from the eventual full sheet; it is measured with an anchor after extraction. A uniform camera scale/position/rotation moves the folded paper forward, then its top/bottom panels rotate about actual hinges with a slight stagger. Panel dimensions stay constant during unfolding. Tiled clean paper grain replaces the stretched image patch; transient fold shadows and crease lines settle away as the offer’s native content appears across all three clipped panels. Sequence is approximately 2.03 seconds. Header/final offer composition and purchase terms remain unchanged; Reduce Motion still uses a short fade, interruption cancels pending phases, and the actual-flow reveal event remains once-only.

Visually checked closed/extracted/final states in Simulator and inspected 100-ms sampled frames through flight and unfolding. Important preview-export correction: default ffmpeg frame synchronization inferred the recording’s low average rate (including long static intervals), dropping motion frames. Export with `-fps_mode passthrough` now retains native variable-rate frame timing: the same review excerpt contains 117 captured frames instead of 16. Do not re-encode Simulator recordings at an inferred average frame rate. The local review player now offers previous/next captured-frame seeking and 0.35× playback, with frame timestamps taken from ffprobe.

API check and all 214 tests passed; all 61 native tests passed. Two new rendering tests verify that the folded pose stays compact and that the opened sheet preserves distinct top/middle/bottom content without missing or duplicated panels. Review recording refreshed in comparison page and `animation-folds.html`. Owner visual acceptance remains pending. No deployment, new TestFlight upload or public release.


### November 22 — pricing polish, clean translation names and 60 FPS review

Original offer price now muted red/struck through; new price is larger semibold Baskerville with plum/rose gradient, warm cream/rose in Dark. Added a subtle blush/plum card, warm rim, small sparkle and savings pill. Light/Pink/Dark visually verified and captured; actual StoreKit terms, renewal disclosures and footer positions retained. Preview fixtures remain labelled and purchasing disabled.

Translation menu names no longer have online/offline suffixes. Offline menu offers bundled versions. Reader synchronizes with the existing effective readingTranslation: offline remote preferences use correctly labelled KJV, keep the preferred version for reconnection and preserve passage position. Network transport failure uses the same fallback; provider HTTP errors retain retry/bundled choices. Added KJV-only translation_fallback event. CSB remains on hold; ESV/NIV are not in this build; NKJV/MSG/AMP/NLT remain included. No Scripture or publisher attribution changed.

Pre-render offer once at 3× before tapping; folded panels animate that image rather than three live ScrollViews, then settle into the interactive native page. Latest measured Simulator moving window: 115 captured frames over 1.993 seconds, average 57.2 FPS, median 16.7 ms, maximum captured interval 90 ms (VFR includes unchanged holds). This is a capture measurement, not a guaranteed device refresh rate. New explicit constant-60-FPS export verified at 288 frames/4.8 seconds; unchanged holds repeat naturally, with no synthetic/interpolated motion. Earlier revised preview averaged approximately 52 FPS. offer-60fps.html includes normal/slow/frame controls and all three price appearances.

API check/all 214 tests passed; 64 native tests passed, including three new offline preference/position/bundled-reading cases. Final build passed after making snapshot preparation persistent. Optimized reveal, all price themes and clean picker visually verified. An incorrect artifact working directory caused a documentation step and commit to fail; a subsequent staging upload started from uncommitted source. It was interrupted after Uploaded and before trigger/version confirmation; a clean committed staging redeploy is required below. Production/TestFlight unchanged.


Clean staging redeploy completed from `b107b51`: Worker `68d326e7-37f5-4126-927f-38860a11c6cf`. Verified POST /events accepts one debug-tagged translation_fallback event (KJV); no customer account or production endpoint used. The earlier uncommitted upload is superseded by this verified clean-source deployment. Source checkout clean before deployment. Native offer Light/Pink/Dark captures and clean reader picker saved, and unique offer-60fps.html requested in the review pane. No new native archive/upload or production deployment.


### November 22 — align the gift price and purchase reporting

Owner selected $29.99 for the first year (25% below the standard $39.99), renewing at $39.99/year. Read-only Apple audit found legacy offer product `hercrown.plus.yearly.offer` (6830441103) still $19.99 introductory / $29.99 renewal, READY_TO_SUBMIT and USA-only. Standard annual product remains unchanged at $39.99. Apple rejected a same-day renewal-price change and required November 24: saved $39.99 renewal from 2026-11-24, ended the unused old USA introductory offer on November 23 and saved $29.99 PAY_UP_FRONT / ONE_YEAR / one period from November 24. Readback confirmed both scheduled prices. No submission or availability expansion. Superwall decline placement remains paused, sandbox-only audience, unsubscribed users, one match ever. Its old paywall is being edited as a draft using the approved native reference; no publishing or audience activation.

Billing audit reconfirmed the November 19 verified initial purchase: recovery dry-run examined 1, missing 0, skipped 1, repaired 0. No production data writes. Gift purchase previously bypassed Superwall by calling StoreKit directly; now calls the installed SDK purchase method so reporting and transaction finishing follow the same pipeline as hosted paywalls. Removed duplicate manual client purchase events; retain exact-product verified entitlement lookup, user identity guards and server verification before granting Plus. Native appearance and offer timing remain unchanged. Gift feature production flag remains off; no new archive/upload or production API deployment. Tests/visual verification recorded below when complete.

Purchase reporting verification: required API check and all 214 tests passed; Xcode native build and all 64 tests passed. Rebuilt gift reveal visually inspected in Simulator; appearance unchanged. End-to-end Apple sandbox purchase remains pending the scheduled November 24 pricing and product readiness. Superwall dashboard product preview saved as 1-year introductory period $29.99, regular annual $39.99 (dashboard previews only; Apple readback is authoritative). The editor AI reference attempt stalled without changing the design and was stopped. Owner approved adding Superwall’s official framework for the hosted recreation; dependency setup follows separately.

Owner chose the faster native animation route after initially approving framework evaluation. Removed only the newly generated, untracked `superwall/` scaffold; no framework dependency or replacement paywall is retained. Native invitation → envelope opening → letter unfolding → offer remains the implementation, with SDK purchase reporting from source `1307967`. No hosted draft was changed by the stalled editor attempt. Review/feedback prompts and guest chapter-boundary/24-hour cooldown were rechecked from source; automatic guest paywall does not fire on app opening alone. Instagram account creation remains uncompleted per owner.


### November 22 — enable the native gift in the next app build

Owner explicitly requested enabling the feature for the next bug-fix app update. Changed `AppConfig.mysteryGiftsEnabled` from staging-only to true in source. Kept the disabled legacy return-offer flag and paused hosted decline campaign unchanged: the approved native UI/animation sells through Superwall's SDK. Presentation still fails closed without the server's 24-hour account-scoped eligibility/atomic claim or matching currently eligible Apple 25%-off introductory pricing. Production API migration 0020/deployment, Apple offer review and scheduled November 24 pricing, sandbox purchase testing and a new native archive remain release prerequisites; this source switch does not activate the existing App Store binary. Current project marketing version remains 1.0.1, build 34; next archive must select the next unused build number.

Explained prompt rules from code: native Apple rating request after 7 elapsed days plus 3 unique reading days, once per marketing version and at least 120 days between requests; Apple controls display. Separate private-feedback invitation after 14 elapsed days plus 5 unique reading days, at least 7 days after rating request and 90 days between feedback invitations (not 30). Both at Home when no conflicting modal. Guest automatic paywall remains chapter-boundary triggered with a 24-hour presentation cooldown, not an app-open timer. Verified Discover whole-word sizing with hyphenation off; in-progress medals use full color/opacity; existing deletion reauthentication and guest endpoint fixes remain included.

Next-build enablement verification: required API check and all 214 tests passed; Xcode build and all 64 native tests passed, including review cooldown, guest chapter/cooldown, account deletion, whole-word sizing, appearance, medals and offer-price guard coverage. No production deployment or native upload performed.


### November 22 — final Simulator comparison and TestFlight 35 preparation

Owner authorized final Simulator walkthrough/comparisons, gift purchasing setup and phone testing. Apple readback confirms latest build is 34 and public version 1.0; selected next build 1.0.1 (35), retaining staging configuration for test isolation. Native source changes through `4bce427` passed 214 API / 64 native tests. New source increments app/widget build number only; release archive remains staging, not eligible for public release until rebuilt against production after validation. Offer pricing scheduled November 24 is accepted by owner; actual Apple checkout cannot yet be claimed verified. Final captures and offer review metadata are being refreshed.


TestFlight 35 archive/upload completed November 22 at approximately 10:38 PM Eastern from clean source `06f5168`. Archive `/private/tmp/hercrown-testflight35-20261122/HerCrown-1.0.1-Staging.xcarchive`; app/widget verified 1.0.1 (35), staging endpoint, `com.hercrown.session.staging` and Live Activities. Apple build ID `ba97ac36-a1de-4fa8-8bde-5a17e7a575d8`, processing VALID, internal IN_BETA_TESTING. Native invitation→reveal/free exit, Pink selection, Discover, Genesis grid→chapter and distinct Armor journey/required chapter links verified in Simulator. Refreshed seven-screen side-by-side final-review.html in outputs/comparisons and opened in Codex panel. Onboarding reminder labelled preview inspected; actual Lock Screen/physical haptics/notification/deletion/checkout remain phone checks. Apple gift review screenshot `3e8c44f9-18be-4010-bc32-9ce89fb01f6d` COMPLETE and notes updated for native next-day flow, 29.99→39.99 from November 24; standalone product remains READY_TO_SUBMIT, not submitted before phone validation. Read-only production migration audit shows 0018–0020 pending.

Automatic approval review initially rejected external Beta group assignment as beyond the phone-only request. Owner then explicitly authorized existing external Beta group. Build 35 assigned; What to Test notes saved/readback pending. Apple rejected beta submission with ANOTHER_BUILD_IN_REVIEW because build 34 is waiting; checking App Store Connect Remove from Review to replace the superseded Beta submission. No App Store public submission/release or production API changes.

Apple Beta review replacement completed: UI Remove from Review withdrew superseded build 34; readback READY_FOR_BETA_SUBMISSION. Build 35 submission then accepted, betaReviewState WAITING_FOR_REVIEW and externalBuildState WAITING_FOR_BETA_REVIEW; internal remains IN_BETA_TESTING. Existing Beta/Team assignments retained; phone test instructions saved. API final check/all 214 tests passed; native source suite remains 64 passed and archive succeeded. No production deployment or public app submission. Owner phone validation and actual gift checkout after scheduled pricing remain outstanding.


### November 22 — tap to finish onboarding reveals

Owner requested a screen tap to end timed onboarding text/haptics, including prayer, without waiting. Added a cancellable visual entrance task and tap/custom accessibility action Show full text across onboarding. Tap completes current page, welcome subtitle/collage and time-intro bridge immediately; cancels pending typewriter sleeps/haptic pulses, acknowledgement holds/fades and intermediate delays. It reveals the next-step control instead of answering questions or navigating automatically. Capture the displayed step/request version so a navigation/retry button tap cannot accidentally finish the next page/request. Prayer preparation runs separately: a tap during generation cannot cancel it or show stale text, and the complete prayer appears once its current response/error is ready. A skipped reveal remains finished across scene/motion changes. Added privacy-safe onboarding_animation_skipped event schema (step/index only).

Latest native build passed; API check/all 214 tests passed after adding the event allowlist. Live Simulator checks: tap early social-media intro → complete bridge + Continue immediately; tap a partly revealed generated prayer → full two-paragraph prayer + Keep this prayer; Continue advanced exactly one page, and tapping the reminder title revealed controls without enabling its off toggle. Captures onboarding-tap-intro.png and onboarding-tap-prayer.png saved in comparisons. Final native regression run pending. Build 35 is already uploaded and does not include this later change; bundle into the next test build after medal-rule decision. Armor simplification recommended to owner; existing rules remain unchanged pending explicit choice.

Final onboarding shortcut verification completed: all 64 native tests passed on the final source, 214 API tests and API check passed. Added final-review-onboarding-tap.html with actual intro/prayer post-tap captures and opened it in the comparison pane. No changes made to medal requirements pending the owner’s choice. No new archive/upload since build 35; onboarding tap change is for the subsequent build.

Onboarding event staging rollout: clean source `17f591e`, Worker `38f812b6-3bc0-4449-a3be-74eca807a034`. POST /events accepted one debug-tagged onboarding_animation_skipped event (step=time, index=1), HTTP 202 accepted 1/rejected 0. No production changes.


### November 22 — artistic Armor book milestones and TestFlight 36

Owner explicitly approved Armor using the Fruit-style automatic medal format and completed Bible books, preserving the artistic iconography, and requested it plus onboarding tap-to-finish in the next TestFlight build. Replaced only Armor’s mandatory journeys with 1/3/5/10/20/40 distinct completed canonical books and retained its existing 21/30/45/60/90/180 reading-day minimums. Original six illustrations, carousel, tiles, colors and haptics unchanged; individual Ephesians 6:14–17 references displayed. Other collections unchanged. Award-cache rules version 3 recalculates Armor dates while retaining unaffected awards. Two new native tests cover canonical full-book/partial/duplicate/malformed data, day minimums, art/verse presence and absence of required chapter lists; all 66 native tests passed. API checks and Simulator verification pending. Latest Apple build confirmed 35; selected next build 1.0.1 (36), staging configuration and isolated credentials, including onboarding tap fix source `17f591e`.

Build 36 pre-archive checks complete: API check/all 214 tests passed; all 66 native tests passed. Simulator Armor/Righteousness shows Ephesians 6:14, original breastplate artwork and 30 reading days / 3 completed books, with no Required reading disclosure. Captured armor-completed-books.png; current test account is locked at zero progress (not an invented achievement). Source changes do not alter artwork, carousel or tile layout.

Build 36 archive/upload completed November 22 at approximately 11:11 PM Eastern from clean source `49cd35d`. Archive `/private/tmp/hercrown-testflight36-20261122/HerCrown-1.0.1-Staging.xcarchive`, app/widget 1.0.1 (36), staging backend/Keychain isolation verified. Apple upload accepted; processing pending. Beta review demoAccountRequired was incorrectly true despite automatic guest access; changed to false and saved accurate build-36 notes, verified readback. No public release or production API deployment. Updated comparison build-36-comparisons.html includes new Armor source and onboarding tap captures; actual zero-progress Armor is locked/muted.

Build 36 processing completed VALID. Saved/read back 2,633-character en-US test instructions and assigned the owner-approved existing external Beta group (13 testers). Withdrew superseded build 35 through App Store Connect (READY_FOR_BETA_SUBMISSION), then submitted build 36: internal IN_BETA_TESTING, external WAITING_FOR_BETA_REVIEW, auto-notify enabled. Visible iOS Builds page confirms build 36 Waiting for Review with Team/Beta groups; proof testflight-36-review.jpg saved beside build-36-comparisons.html. Build 36 contains both artistic Armor book milestones and onboarding tap-to-finish. No public App Store submission/release or production data/deployment. Phone validation and actual gift checkout remain outstanding.

### November 23 — independent sequential medal stages

Owner clarified that Love needs 14 days/14 chapters and Joy needs another 21 days/21 chapters from zero, not lifetime thresholds. Applied one active stage per collection to all collections, preserving art/carousel/icon tiles and Armor complete-book goals. Worker replays verified days/chapter-end history; award-day surplus never rolls over; chapter uniqueness resets only between stages; Armor requires every book chapter within that stage. Reader reports daily chapter rereads to support later goals; errors permit retry. Server stage refs drive themed checklist ticks. Guest-link history and unmarking retained, ordinary verse reads cannot count as chapter ends. v4 recalculates stale local award dates. Onboarding tap changes explicitly left unchanged while owner compares other apps. API check/219 tests and native 67 tests passed. No new TestFlight archive: uploaded build 36 is immutable. Simulator inspection/staging rollout pending.

Sequential medal verification completed November 23: API check/all 219 tests and all 67 native tests passed. Clean source `ea0d0cc` deployed to staging Worker `37cb275d-7dfa-4e7b-b530-276b58ac6646`. Disposable staging guest completed Psalm 117: Love 1/14 days and 1/14 chapters; all later-stage counters zero. Simulator shows Joy Locked/0 of 21 with Complete Love first, and only Belt of Truth available in Armor while later pieces remain Locked. Original art preserved; screenshot comparisons/sequential-armor.png. No onboarding file changes, no production writes/deployments and no additional TestFlight upload. Build 36 remains the prior uploaded binary; this correction is saved for a subsequent build.

### November 23 — match Pink handoff accents and Home layout

Owner requested the original purple/wine controls, overriding the earlier #31222B accent direction. Sampled the original Library pill: dominant RGB130/67/95 = #82435F, matching supplied --petal-wine. Added Theme.accent separate from ordinary #31222B body text; updated shared primary/secondary styles, selected Dock/pills, reader chrome, Home actions, Discover selections, Community vote/action colors and settings controls. Light/Dark tokens remain unchanged. Restored inset Home divider with 12pt card gap. Daily verse now uses all card width and measured 28→22pt size at default Dynamic Type for long passages, then grows without truncation; accessibility sizes are not reduced. Faith Medals row has 4pt text spacing, inline View medal arrow and its own bottom divider; devotional arrows remain trailing.

Required API check/219 tests passed; final native suite 68 tests passed. Live Simulator inspected matched Psalm23:1, licensed MSG Romans8:26–28 bridge (469 characters, exact provider text), Bible and Community controls. Both passage captures show complete text, correct purple accents and divider/inline-arrow layout. Temporary fixed-passage debug code removed from HomeModel after capture; no fixture Scripture or API secret retained in source. Original handoff vs current app plus short/long-native tabs saved in outputs/hercrown-2026-11-22/comparisons/pink-corrections-review.html. Staging Community values were used solely to inspect styling, not asserted as real donations. Onboarding tap behavior unchanged. No production change or new TestFlight archive/upload.

### November 23 — measured Home rhythm and restored verse formatting

Owner reversed the full-width/adaptive verse request: restored original 28pt relative-to-title2, 265pt max width, original tracking/leading and natural vertical expansion for every translation. Removed the temporary adaptive type component/test. Kept #82435F accents. Owner clarified that editorial row dividers remain: Faith Medals uses stronger 1pt full-opacity theme border; other rows lighter 0.5pt/65% border. Tight medal typography/inline arrow retained, excess minimum-height slack removed; editorial copy top-aligned and vertically padded 20pt. Final full-glyph normalized screenshot measurements: reference clear gaps 20.13pt above /26.23pt below strong rule; actual native 20.00pt /25.67pt. Preserved screenshot home-reference-rhythm.png and measurement JSON in comparison output; updated home-spacing-review.html and current pink review pages. Final API check/219 tests and 67 native tests passed; Simulator capture inspected directly because desktop window retrieval was unavailable. Temporary matched-Psalm capture code removed after build; no fixed Scripture content retained in source. Onboarding unchanged. No production deployment or TestFlight archive/upload.

### November 23 — TestFlight 37 preparation

Owner requested push v37. Selected 1.0.1 (37) for app/widget, retaining staging API and isolated staging credentials. Includes sequential fresh medal stages (Worker ea0d0cc /37cb275d-7dfa-4e7b-b530-276b58ac6646), sampled Pink #82435F controls, restored original verse typography and measured Home divider rhythm through source 053a2ba. Onboarding tap behavior retained while owner reviews it. Latest required checks: API check/219 tests and 67 native tests passed; actual Simulator captures verified. This version-only bump has no feature logic changes. Archive/upload must use this clean commit. No production release or API deployment.

Build 37 archive and upload completed November 23 at approximately 1:55 AM Eastern from clean source `bdbd20d`. Archive `/private/tmp/hercrown-testflight37-20261123/HerCrown-1.0.1-Staging.xcarchive`. App/widget 1.0.1 (37), staging endpoint/Keychain isolation/Live Activities verified; temporary design-capture overrides absent in Release binary. Apple upload accepted, processing pending. External Beta review replacement requires browser sign-in after session expiration; request sent to owner. Existing source tests 219 API/67 native passed. No production deployment or public release.

Build 37 upload readback: upload ID `99b820c1-be83-4d0b-b813-ae951f590099`, uploaded 1:55:03 AM Eastern. Apple still reports PROCESSING with empty errors/warnings after repeated bounded checks; /builds has no build-37 resource yet, so tester localization/group assignment/submission cannot run yet. Owner restored browser sign-in. Withdrew superseded build 36 through App Store Connect, verified external READY_FOR_BETA_SUBMISSION. Saved/read back accurate build-37 Beta review notes with demoAccountRequired=false. Test instructions ready in docs/build-37-testing.md and /private/tmp/hercrown-testflight37-20261123/WhatToTest.txt (2819 chars). Existing Beta group 20c28d43-2861-4a95-a0be-dc4cc303e4af /Team group unchanged; build 37 must be assigned after processing completes, then POST betaAppReviewSubmissions. Screenshot testflight-37-processing.jpg confirms Apple processing. External Beta submission remains unfinished pending Apple processing; no public release or production changes.

### November 23 — partner-confirmed plum, flat verse section and book openings

Owner restored #31222B for Pink accents (supersedes #82435F handoff matching) and requested the original book-specific icon at each book start, then removal of the rounded Home daily-verse card. Updated semantic accent, removed card/inset and applied subtle #F8EBF0 full-width flat wash without shape/stroke/shadow. Original verse font/column, separators and measured medal rhythm retained. Reader previously used generic chapter-opening art; now selects supplied canonical book asset at 1:1 only, preserving separate featured-verse art. Ezra1:1 uses original quill.

API check/all219 tests and all68 native tests passed, including actual ReaderModel selection for every bundled book opening, later verses/chapters, loadable66 assets and featured Psalm. Running Simulator screenshots home-flat-plum.png and ezra-book-opening.png inspected; updated plum-flat-and-book-openings.html review with matched Psalm and original Ezra asset beside the running reader. Temporary matched-Psalm debug capture code removed from HomeModel after building, with no fixed Scripture text retained in source. No schema/dependency/vendor changes. Onboarding unchanged. Source version remains37, but these corrections are AFTER uploaded37 and require a subsequent build; no new archive/upload/public or production changes.

### November 23 — continuous divider-to-divider daily-verse wash

Owner clarified all space between the Library divider and lower daily-verse divider must use the same subtle shade. Colored the 12pt Library-only spacer and moved the verse wash to its outer section, including the lower divider background. No size/typography/spacing changes. Actual Simulator screenshot home-continuous-pink.png inspected; five pixel samples at y797/815/830/1100/1500 all RGB248/235/240 (#F8EBF0). Updated continuous-pink-review.html and existing review files. API check/all219 tests and all68 native tests passed. Temporary matched-Psalm capture code removed from HomeModel; no fixed content retained in source.

Also completed the earlier build37 distribution after Apple finally reported COMPLETE: build ID99b820c1-be83-4d0b-b813-ae951f590099, processing VALID, internal IN_BETA_TESTING. Saved/read back What to Test with explicit disclaimer that later #31222B/flat-verse/book-opening corrections are not in37. Assigned approved existing Beta group20c28d43-2861-4a95-a0be-dc4cc303e4af, verified membership and submitted Beta review; external WAITING_FOR_BETA_REVIEW, auto-notify true. Earlier source/archive bdbd20d remains unchanged. Current UI corrections require subsequent build. No production deployment/public release.

### November 23 — internal-only TestFlight 39 preparation

Owner requested latest corrections as internal-only build38; Apple already has an older 38 uploaded at2:45AM (ID8b181f81-2aca-4c66-b756-49a7490ab3c1, INTERNAL_ONLY). Owner explicitly confirmed use of39 instead. Set app/widget 1.0.1(39), staging API and isolated staging credentials. Export testFlightInternalTestingOnly=true enforces internal-only audience, with existing Team group only; no external Beta group/submission or public release. Includes corrections through0f7983c: continuous flat verse wash, #31222B controls, all66 book-opening artwork, fresh sequential medals, original verse typography and measured section spacing. Onboarding tap unchanged. Required source checks passed219 API/68 native and actual Simulator captures inspected. Version-only bump; archive/upload from this clean commit.

Build39 archive/upload completed November23 at approximately2:23PM Eastern from clean source d11ee46. Archive /private/tmp/hercrown-testflight39-20261123/HerCrown-1.0.1-Staging.xcarchive; app/widget1.0.1(39), staging endpoint/Keychain isolation verified. Export testFlightInternalTestingOnly=true verified; temporary design-capture flags absent from Release. Apple upload accepted; processing/readback pending. Latest source checks219 API/68 native passed. No external Beta assignment/submission or public/production deployment.

Internal TestFlight39 verified ready: Apple build ID8dec1205-c5f8-4a13-9f58-9c66c1368de8, processing VALID, audience INTERNAL_ONLY, internal IN_BETA_TESTING, external NOT_APPLICABLE. Existing Team group28cc9cba-c547-49ca-bb95-2cfeb20b6ac4 assigned/read back, external Beta group NOT assigned, auto-notify true. Saved/read back3116-character en-US What to Test. No Beta App Review submission or public release performed. Final structured readback saved /private/tmp/hercrown-testflight39-20261123/verified.json. Latest appearance/book-art/sequential-medal fixes are included in clean archive source d11ee46.


### November 23 — cumulative progress, concealed medal artwork

Owner superseded the fresh-stage rule: every milestone now counts the same verified lifetime activity concurrently (2/14 and 2/365), without resets. Retained independent days AND distinct chapter/book/themed requirements. Removed predecessor-lock copy, concealed unearned artwork completely in carousel/grid/Home, and kept share/Collected restricted to fully earned goals. Version5 API counters and cache invalidation prevent old sequential snapshots from zeroing later goals. Added threshold/deduplication/whole-book/legacy-payload regressions. Verification in progress; no new TestFlight build or production changes.

Cumulative medal verification: API type/content checks and all220 API tests passed; all69 native tests passed. Clean backend source9c75fad deployed only to staging Worker3b991e26-b77f-4ff0-beea-e71f1a8a4b33. Disposable staging guests verified all24 day counters advance concurrently, all9 Fruit counters count the same2 distinct chapters, none earned, duplicates do not inflate, other-account history is isolated and unmark removes the chapter; test guests deleted. Simulator inspection caught an unavailable placeholder symbol; replaced with scalable lock.fill so unearned illustrations are not rendered at any size. Final rebuilt Simulator capture inspected: original artwork concealed by visible lock placeholders; zero activity remains unearned, no share button. Capture outputs/hercrown-2026-11-22/comparisons/cumulative-concealed-medals.png. Existing39 remains immutable; no new TestFlight upload/public release/production write.


### November 23 — internal TestFlight40

Owner requested next build after cumulative medal fix. Apple latest build39 verified; selected1.0.1(40) for app/widget. Includes cumulative concurrent progress and concealed unearned artwork throughaf931b3. Required checks passed220 API/69 native, final rebuilt Simulator inspected; staging backend source9c75fad/Worker3b991e26-b77f-4ff0-beea-e71f1a8a4b33 verified with disposable guests. Retain staging API/isolated Keychain and internal-only export, existing Team group only. No external Beta submission/public release/production writes. Clean source commit below is the archive source.


Build40 upload interrupted at owner's request before finishing export/upload. Apple build40 query returned no records immediately afterward; no Team assignment or release performed. Archive72dab9e is superseded for distribution. Owner requires envelope letter to carry offer content and remain the final paper background, with no independent page swap. Work resumed on that correction before another push.


### November 23 — restore original offer styling and continuous printed paper

Owner clarified: match original handoff styling, with excitement from the paper reveal. Removed later sparkle/gradient/shadow/savings-pill decoration; restored plain pricing card and regular original type, retained book/cloud/flower assets, verified29.99 first-year/39.99 renewal terms and purchase-disabled preview. Shared concrete pageContents now powers both snapshot panels and final interactive page; no GeometryReader/ScrollView snapshot wrapper. Folded letter carries the printed middle panel, texture persists as final page background, no delayed ink fade; hide reverse-side ink and place folded wings behind center until facing viewer, preventing mirrored upside-down text. Reduced Motion preserved. Added actual-offer snapshot regression (ink in all3 panels). Required API check/all220 tests and all70 native tests passed. Simulator service failed during a recording, restarted without resetting data; subsequent final recording inspected frame by frame. Review artifact outputs/hercrown-2026-11-22/comparisons/original-offer-paper-review.html contains original/native comparison and real native video.

Build40 upload remains canceled: queried Apple twice after interruption, no build40 record. No Team assignment/external submission/public release/production change. Existing72dab9e archive lacks these corrections and must not be uploaded. Hold distribution until this corrected preview is reviewed.


### November 23 — full-screen matching offer paper

Owner requested the off-white letter material across the entire gift screen, including Her Crown Plus header, X button and top/status safe area. Use one root GiftPaperMaterial ignoring safe areas; removed independent offer-body background and contrasting close-button fill. Invitation/revealed pages share the same continuous material, with existing card styling retained. API check/all220 tests passed, native build succeeded and running Simulator capture directly inspected (hercrown-paper-fullscreen.png). Prior70 native logic tests remain passed; layout-only correction verified visually. Preview refreshed; distribution remains paused, no new TestFlight upload.


### November 23 — approved internal TestFlight40 retry

Owner explicitly approved internal TestFlight push after reviewing continuous off-white background. Apple latest remains39; canceled40 never arrived. Rebuild1.0.1(40) from latest corrected source through18c526d, replacing the superseded archive in a new archive directory. Includes cumulative concealed medals, original gift styling, printed paper continuity and full-screen matching paper/header. API check/220 tests and70 native tests passed on relevant changes; final background rebuilt and Simulator inspected. Internal-only staging export, isolated credentials and Team group only. No external/public release or production writes.


Final build40 archive/upload succeeded from clean source6fcd755. Archive /private/tmp/hercrown-testflight40-final-20261123/HerCrown-1.0.1-Staging.xcarchive. App/widget1.0.1(40), staging endpoint/isolated Keychain, internal-only export and exclusion of DEBUG animation preview flag verified. Apple upload accepted November23 at approximately3:59PM Eastern; processing pending. Includes final matching header/paper, printed offer animation and cumulative concealed medals. No external/public distribution or production writes.


Build40 verified VALID and INTERNAL_ONLY: Apple ID122b0ebb-f606-41a7-a9cb-0c6d615a8ec2, internal IN_BETA_TESTING, external NOT_APPLICABLE, autoNotifyEnabled true. Team group28cc9cba-c547-49ca-bb95-2cfeb20b6ac4 already receives it through hasAccessToAllBuilds=true; membership read back true. Explicit assignment was unnecessary (Apple rejected re-adding an internal-only build to that already-associated internal group). Testing notes submitted. Archive source6fcd755 and staging backend9c75fad/3b991e26-b77f-4ff0-beea-e71f1a8a4b33. No external review/public release/production changes.

Final read-only verification saved /private/tmp/hercrown-testflight40-final-20261123/verified.json: internal IN_BETA_TESTING, auto-notify true, Team membership true, external Beta membership false,3558-character en-US testing notes read back exactly. Apple returned a transient500 during an earlier redundant detail read; fresh parallel reads succeeded and confirmed readiness.


### November 23 — remove rounded Discover feature card

Owner identified the same inset rounded pink-card issue on Discover. Removed the feature's rounded shape and darker #F3DFE7 fill. Use Home's subtle #F8EBF0 flat full-width section wash, spanning from the filter edge through the14pt feed gap to the existing lower divider. Retained original heading/whole-word layout, illustration, reference/completion and Begin reading behavior. API check/all220 tests passed; native build succeeded and actual pink Simulator page inspected with Numbers6:26. Capture comparisons/discover-flat.png. No new TestFlight upload; build40 predates this correction.


### November 23 — restore original greyed medal icons

Owner corrected the rendering: unearned medals must retain original fruit/armor/collection artwork in grayscale/faded form, not lock symbols. Shared MedalImage now always renders original art, saturation0/opacity0.5 while unearned and full colour/opacity when earned. Carousel, tiles and Home keep the existing !earned guard; cumulative progress, thresholds and sharing eligibility unchanged. Updated decision0024 clarification. API check/all220 tests passed; native build succeeded and running pink Simulator inspected: Love uses original grey strawberry, adjacent Joy original grey peach, no replacement lock. Capture comparisons/grey-medals.png. This correction and flat Discover fix are newer than uploaded40; no new TestFlight upload.


### November 23 — internal TestFlight41

Owner requested recent fixes in next build. Selected1.0.1(41), app/widget. Includes56f7a3d grey original unearned medal artwork (no lock symbols), cumulative progress unchanged,6887dc5 flat Discover pink section, plus previously approved native printed-letter offer/original styling/full-screen paper header. Existing paywall preloading retained; physical phone latency remains to be measured, not claimed fixed. API check/220 tests and native builds/Simulator captures passed for latest layout fixes; prior70 native logic tests passed. Internal-only staging export/isolated credentials, existing Team group only; no external/public release or production writes. Archive from clean commit.


Build41 archive/upload succeeded from clean sourcef9c2206. Archive /private/tmp/hercrown-testflight41-20261123/HerCrown-1.0.1-Staging.xcarchive. App/widget1.0.1(41), staging endpoint/Keychain isolation, internal-only export and exclusion of DEBUG preview automation verified. Apple accepted upload November23 at approximately5:04PM Eastern; upload IDdcaad65a-dbd4-4761-a7c5-ce039d80e073 processing with no errors/warnings. Team distribution verification pending; no external/public release/production changes.


Build41 verified ready: Apple IDdcaad65a-dbd4-4761-a7c5-ce039d80e073, processing VALID, audience INTERNAL_ONLY, internal IN_BETA_TESTING, external NOT_APPLICABLE, autoNotifyEnabled true. Existing Team membership read back true; external Beta membership false.3849-character testing notes saved/read back exactly. Final /private/tmp/hercrown-testflight41-20261123/verified.json. Clean archive sourcef9c2206. No external Beta review/public release/production write.


### November 23 — restore compact Home and uniform pink

Owner provided comparison photos: editorial titles/kickers were separated by flexible Spacer plus88pt text frame and20pt external padding. Restored original centred102pt minimum rows with fixed7pt copy gaps; Faith Medals entry now uses102pt minimum without uneven24/13pt padding. Home navigation fruits always full colour; actual unearned Faith Medals artwork still grey/faded. Removed all Home/Discover darker verse/feature fills and unused verseSurface token, leaving canvas#FBF1F4. No Scripture font/content or medal progress/eligibility changes. API check/all220 tests passed, native build succeeded; actual pink Home (Ecclesiastes4:9, matching supplied example) and grey Faith Medals inspected. Discover fully loaded capture also inspected: one canvas tone through feature and list. Newer than TestFlight41, no upload/deployment.
