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

- [x] App Store Connect uses manual release. The owner presses Release after approval.
- [x] App Store Connect weekly plan has no introductory offer in any territory and is Ready to Submit. Yearly retains its 7-day trial for eligible subscribers. Superwall Main publishes the matching weekly disclosure.
- [x] App Store Connect age rating is 4+ and the third-party content rights declaration is saved.
- [x] Both $19.99 return offers are off for version 1.0. The app requires a sandbox receipt, the Worker endpoints require staging, and Superwall's legacy `paywall_decline` placement is paused. Exclude the separate $19.99 product from the 1.0 submission.
- [x] App Privacy published in App Store Connect on 2026-11-06. The label covers country-level analytics and device IDs used for analytics and notifications. Switch the privacy policy URL to production after the Worker is live.
- [x] Provisioned production D1, KV, R2 and the events queue on 2026-11-06. Production bindings are recorded in `apps/api/wrangler.jsonc`.
- [x] Owner applied all 11 production D1 migrations and seeded KJV, BSB, WEB, all four study datasets and 29 approved devotionals. Wrangler confirmed the initial production Worker secrets, including both Sign in with Apple settings.
- [x] Owner deployed the production Worker on 2026-11-06 (version `af0c194b-8287-4c12-ad5a-b62675f18081`). Health, privacy, terms and support returned HTTP 200.
- [x] Created the production Superwall V2 webhook at `/webhooks/superwall`.
- [x] Owner uploaded the production Superwall signing secret. The endpoint returned `401 invalid_signature` for an unsigned request.
- [ ] Verify a signed delivery after a sandbox purchase. The production webhook is active, with no delivery attempts yet. Superwall V2 does not send synthetic test events.
- [x] Release now points at production and uses its legal and support URLs. The production build disables sandbox testing and both return offers.
- [ ] Verify first-run onboarding on an iPhone that has never had Her Crown installed. The Sandbox testing menu is hidden in production builds. Complete the production smoke checks.
- [ ] Sandbox checkout and restore on the TestFlight release candidate. Use dedicated test accounts: the build writes those accounts and their purchases to production, with purchases flagged as sandbox. Verify the entitlement and purchase event on the production backend.
- [ ] After Apple approves 1.0, switch Superwall Main to all users without an active entitlement immediately before the owner presses Release.
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
