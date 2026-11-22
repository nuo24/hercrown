# Build 34 — TestFlight staging candidate

This is an unreleased update. Keep build 33 live until the UI and device checks are approved together. On November 22 the owner authorized a TestFlight upload for checking. Build 34 will use Release plus `HC_STAGING_TESTFLIGHT`, connecting to staging and exposing tester-only controls. Public App Store release and production deployment remain outside this task. Upload/processing evidence is recorded below when completed.

## Changes

- Discover: small circled completion control beside the verse reference; theme and REFLECTION on a compact second line. Existing completion transition retained.
- Study: removed repeated Plus capsules. Locked tools request the existing Superwall placement directly; server entitlement checks remain.
- Review: native StoreKit prompt after at least three reading days and seven days of use; once per marketing version, with at least 120 days between requests. Independent optional feedback invitation after five reading days and 14 days, with separate cooldowns. Settings has an explicit review link. No sentiment or star-rating gate.
- Onboarding: first-launch Live Activity can remind her to continue setup. It cannot appear before the app has been opened or when Live Activities are disabled. It contains progress only, resumes the encrypted Keychain draft through hercrown://onboarding, respects dismissal and ends when onboarding completes. Device/OS determines visibility and lifetime.
- Include existing email-consent and fresh-authentication account-deletion work in this update. Apple checkout authentication remains Apple's UI.
- Added six public-domain offline editions: ASV, YLT, Darby, Webster, MSB, Reina-Valera 1909 (Spanish). Five English additions plus Spanish supplement KJV, BSB and WEB. Existing API.Bible editions remain licensed online editions. CSB is pending permission and has not been imported.

## Scripture provenance

`scripts/free-editions.json` under apps/api records official eBible rights links, source archive checksums and expected marker counts. The builder checks every stored verse against a separately published verse-per-line export. Tagged Psalm superscriptions remain separate; words included inline by the source stay with their source verse. No missing verse is invented or copied from another edition. ASV and MSB omit some source verses; Spanish uses its source's own numbering, including empty source placeholders. The app bundle and D1 seeds use the same generated JSON/SQL source.

The six JSON bundles add approximately 26 MB before app-store compression. They load on first use rather than all at startup. Spanish book names come from the source USFM metadata. Reflections, navigation and study commentary remain English; this is Spanish Scripture support, not full Spanish app localization.

## Backend rollout

Migration 0018 registers the new editions. Apply to staging and seed `seed:free-editions:staging` before testing server-backed Discover/Home in those editions. New review and onboarding activity event names require the updated Worker. Production migration, seed and deployment remain human-run from a clean checkout after staging verification. Registering translations without loading their verses is incomplete.

## Guest paywall investigation

Guest exploration still skips the initial onboarding paywall; premium tools open it on demand. The owner subsequently selected a same-day automatic offer after chapter completion: it appears at the next chapter boundary and is limited to once every rolling 24 hours. See decision 0014. Return offers are disabled by `AppConfig.returnOffersEnabled = false`, including staging. A recurring popup on the installed App Store build needs reproduction against its exact build and Superwall campaign before changing billing behavior.

## Outstanding release checks

Inspect Discover in both themes, offline translation switching, Lock Screen Live Activity resume/completion/dismissal on a physical iPhone, native review/feedback presentation and the existing purchase/restore/deletion/email-consent flows. Do not release merely because compilation passes.

## Verification — November 19, 2026

- `npm run check && npm test`: passed; 209 API tests in 15 files.
- Xcode Debug build and native tests: passed, 34 tests. Added coverage for source omissions, all offline bundles, Spanish labels, review eligibility/cooldowns and prior account-deletion fixes.
- Inspected actual Simulator Discover in light/dark and the Spanish reader; screenshots in `/private/tmp/hercrown-build34-*`.
- Clean staging checkout `/private/tmp/hercrown-build34-stage`, source commit `3b13d8f`; Worker version `e7fece1a-1c91-479d-a666-41b57a9a1e71`. Migration 0018 and all six full seeds applied to staging. Each new edition passed real catalog/chapter/Discover readback; temporary guest deleted afterwards.
- No production database changes, production deployment, App Store submission or TestFlight upload for build 34.
- Physical-iPhone Live Activity display/resume/dismissal/completion and Apple-controlled rating dialog remain device checks before release.

### Subsequent Xcode guest-flow test

Owner selected the same-day guest paywall after chapter completion (decision 0014). Added five policy tests and fixed direct reader verse targets plus initial-verse recording. Final native tests: 39 passed; API checks/tests: 209 passed. Clean local source: `322fd61`; guest analytics staging deployment source `9ddca94`, Worker `da2a4107-dd5c-40b8-8b7a-fbb74d3cb9a9`. Xcode's reset-on-each-run launch argument is disabled. Live Simulator verification of correct Psalm 117:1 and Psalm 118:1 passed before the final initial-verse change. Automatic paywall presentation/dismissal requires finishing the live check; computer control lost all native windows after the final build launched. Production and TestFlight unchanged.

### Guest live-test corrections

The live trace confirmed an eligible guest crossing from Psalm 117 to 118 requests the standard campaign. Retain read verses across the last 32 chapters so back-and-forth navigation does not erase completion. Only Superwall's onPresent callback starts the persisted 24-hour cooldown (`hc.lastGuestPaywallShown`); failed/skipped requests use a five-minute in-session backoff. Explicit premium-feature requests remain available. New regression tests cover both cases. Debug-only local diagnostics record eligibility and SDK outcomes; no private account identifiers are stored in those diagnostics. The owner is completing the manual transition because native computer control became intermittent. Do not claim a visible Superwall presentation/dismissal until observed.

### Paywall performance verification — November 19

Owner confirmed that the chapter paywall appeared, but took about three seconds. Added eligible-guest background preloading during reading and removed the fixed 600 ms delay. Temporary detailed reading traces removed; retain debug-only preload/outcome/latency counters. A fresh guest on the isolated “Her Crown Guest Policy Tests” iPhone Simulator preloaded the campaign, completed Psalm 117 and displayed the real Superwall main paywall. Instrumented request-to-onPresent time, including the existing StoreKit check: **827 ms**. Closed the paywall without purchasing and visually verified free reading at Psalm 118:1. This confirms presentation and dismissal, resolving the earlier pending live check. This is one local measurement, not a guarantee across networks/devices.

Proof image: `outputs/hercrown-2026-11-19/build34/Guest-Paywall-Preloaded.png`. API checks/tests passed (209); final native suite passed (41). Clean local source commit `fd11102` in `/private/tmp/hercrown-build34-stage`. Production and TestFlight unchanged.


### November 22 — TestFlight preparation

Includes all four handoffs and subsequent fixes: Faith Medals, original 66-book artwork, persisted Pink appearance, preview-precedence fix, whole-word Discover titles, Mystery Gift invitation/reveal and free exits. Added Settings → Sandbox testing → Preview decline offer so TestFlight testers can inspect the gift without a configured discount. The design preview is explicitly labeled and cannot purchase/restore. Genuine StoreKit-discount checkout remains a manual release check.

Required API check/210 tests passed. Native tests with both DEBUG and HC_STAGING_TESTFLIGHT passed. Physical Live Activity behavior, haptic strength and actual discount availability/checkout still need device testing. Archive only from clean `codex/four-handoffs`; API key files stay outside the repo.


TestFlight preflight caught a local session-storage collision: the staging and live bundle formerly used the same Keychain service. Staging now uses `com.hercrown.session.staging`, retaining `com.hercrown.session` unchanged for live installs. Staging never migrates/reads the live login. Added regression coverage; full staging-configured native suite passed (53 tests), API check/210 tests passed.

Initial clean-source archive `373988f` succeeded, but export/upload stopped before delivery: API key lacked cloud-signing permission; account-based fallback found no Xcode Apple account. Alternate existing key could not authenticate. Owner was asked to sign in in Xcode → Apple Accounts. Final isolated-session archive and upload tracked below. No App Store release or production change.


Final archive succeeded from clean source `9a99717` at `/private/tmp/hercrown-testflight34-20261122/HerCrown-Staging.xcarchive`. Verified app/widget build 34, staging API endpoint, separate staging Keychain service and Live Activity support in the signed app. Staging analytics deployment source `373988f`, Worker `36e23e0f-a710-44ca-a230-1cba2f63cb41`. Final upload script is prepared outside the repo; delivery awaits owner sign-in in Xcode Apple Accounts. Build 34 is NOT uploaded yet. Existing TestFlight latest remains 33 until delivery succeeds.


### November 22 — corrected version uploaded

Xcode account sign-in resolved signing. Apple rejected version 1.0 because its approved release train is closed. Marketing version corrected to **1.0.1 (34)**, archived from clean source `3580423` at `/private/tmp/hercrown-testflight34-20261122/HerCrown-1.0.1-Staging.xcarchive`. Verified matching app/widget versions, staging endpoint, isolated Keychain and Live Activity support. Export/upload succeeded at 4:49 PM Eastern. This supersedes the earlier upload-blocker notes. Apple processing and tester availability are being verified. API check and all 210 tests passed again. No public submission or production changes.


TestFlight verification, November 22 at 4:53 PM Eastern: Apple build `2f3ae808-4974-4dc2-8a7c-be76b0dabe31`, version **1.0.1 (34)**, processing **VALID**, internal **IN_BETA_TESTING**, external **WAITING_FOR_BETA_REVIEW**. Existing Beta group assignment and staging-specific What to Test notes read back successfully. TestFlight Beta App Review submission accepted (**WAITING_FOR_REVIEW**); external installation awaits Apple. Source `3580423`; staging Worker `36e23e0f-a710-44ca-a230-1cba2f63cb41`. Genuine discount checkout, physical haptics and onboarding Live Activity background/force-quit checks remain manual testing items. Public App Store build 33 and production backend unchanged.
