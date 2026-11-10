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
