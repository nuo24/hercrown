# Her Crown 1.0.1 (35) phone testing

Archive source: `06f5168`. Staging backend only; isolated staging Keychain. Public release must use a separate production archive after validation.

Her Crown 1.0.1 (35) — STAGING TEST BUILD

This build uses staging and an isolated staging sign-in. It is for testing; App Store account data will not appear here.

1. Settings > Sandbox testing > Start fresh onboarding. Complete onboarding, dismiss the paywall and verify free reading. During setup, background the app and try Continue setup on the physical iPhone Lock Screen.
2. As a guest, complete a chapter and continue to the next. Dismiss the automatic paywall into free reading. It must not repeat within 24 hours; Plus-feature paywalls remain separate.
3. Select Pink, then Light/Dark; leave Settings and relaunch. Inspect Discover whole words, verse/checkmark alignment and the reflection caption below.
4. Open the Bible book artwork grid, search and select chapters. In airplane mode, try KJV/BSB/WEB and bundled English/Spanish editions. A licensed online translation must fall back to usable free reading.
5. Faith Medals: carousel selection/haptics, distinct chapter journeys, Required reading links, colorful in-progress artwork and muted locked artwork.
6. Delete only a disposable STAGING guest/Apple-linked account. Apple may require renewed sign-in and another deletion confirmation. Ordinary Settings changes must not reset onboarding.
7. Settings > Sandbox testing > Preview decline offer tests the native animation, with purchases disabled in this labelled preview. Actual gift requires main-paywall dismissal, reopening at least 24 hours later, no Plus entitlement and introductory-offer eligibility. U.S. pricing starts November 24: $29.99 first year, then $39.99/year, no free trial. Actual gift stays hidden until Apple returns matching terms. Then test sandbox purchase/cancel/restore and Plus access.
8. Send feedback anytime through Settings > Suggestions & bugs. Automatic rating request: 7 days plus 3 reading days, Apple controls display. Feedback invitation: 14 days plus 5 reading days, with a 90-day repeat interval.

Report build, iPhone model, appearance, steps and screenshot/video. Never include passwords or verification codes.


## Release gates

- Confirm phone visual, haptic, Lock Screen, notifications, offline, account deletion and guest paywall behavior.
- On or after November 24, verify actual Apple sandbox gift purchase, cancellation, restore and server entitlements / verified billing events. Labelled gift design previews cannot prove checkout.
- Submit the standalone offer with the production app update; do not claim approval from READY_TO_SUBMIT. Review screenshot and notes were refreshed November 22.
- Human production update: migrations 0018–0020, six verified edition seeds and Worker deployment. No production data modified by agent.
- Production archive from a clean commit, new unused build number; source/version recorded. Build 35 is staging and must not become the public release binary.
