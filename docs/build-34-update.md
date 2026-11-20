# Build 34 — local update under review

This is an unreleased update. Keep build 33 live until the UI and device checks are approved together. No production deployment or TestFlight upload has been performed for these changes.

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
