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

`scripts/free-editions.json` under apps/api records official eBible rights links, source archive checksums and expected marker counts. The builder checks every stored verse against a separately published verse-per-line export. Psalm superscriptions remain separate. No missing verse is invented or copied from another edition. ASV and MSB omit some source verses; Spanish uses its source's own numbering, including empty source placeholders. The app bundle and D1 seeds use the same generated JSON/SQL source.

The six JSON bundles add approximately 26 MB before app-store compression. They load on first use rather than all at startup. Spanish book names come from the source USFM metadata. Reflections, navigation and study commentary remain English; this is Spanish Scripture support, not full Spanish app localization.

## Backend rollout

Migration 0018 registers the new editions. Apply to staging and seed `seed:free-editions:staging` before testing server-backed Discover/Home in those editions. New review and onboarding activity event names require the updated Worker. Production migration, seed and deployment remain human-run from a clean checkout after staging verification. Registering translations without loading their verses is incomplete.

## Guest paywall investigation

There is no daily guest-paywall timer in the current native code. Continuing as guest intentionally skips the onboarding paywall; premium tools still open it on demand. Return offers are disabled by `AppConfig.returnOffersEnabled = false`, including staging. A recurring popup on the installed App Store build needs reproduction against its exact build and Superwall campaign before changing billing behavior.

## Outstanding release checks

Inspect Discover in both themes, offline translation switching, Lock Screen Live Activity resume/completion/dismissal on a physical iPhone, native review/feedback presentation and the existing purchase/restore/deletion/email-consent flows. Do not release merely because compilation passes.
