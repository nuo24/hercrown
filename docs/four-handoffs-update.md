# Four handoffs — development verification

2026-11-21. Working against build 34. No archive, upload or production release. Font sizing/welcome-screen changes are explicitly excluded.

## 1. Faith medals

Imported all seven original PNGs after SHA-256 verification. Native Home entry after Verse of the Day; five collections; horizontally snapping carousel with subtle selection haptics; grid selection; account-scoped server progress/cache; real qualifying goals; locked grayscale; 1200×1200 PNG export through the native share sheet only for qualified medals. Rarity labels indicate goal difficulty, not fabricated population statistics. Goals are in decision 0015.

Xcode Debug build succeeded. Ran in isolated iPhone 17 Pro/iOS 26.2 Simulator: real test-account progress 1 day/1 chapter, zero medals collected. Visually checked light screen, collection navigation and grid selection. Three native eligibility tests passed (both conditions required; book-specific counts; unique catalog/long goals). Physical haptic strength still needs an iPhone check. Milestone progress syncs from the existing API; awards are derived, with local first-detection dates, not a new server-issued reward ledger.

## 2. Bible-book artwork

Verified all 66 SHA-256 hashes and all English book names against the canonical USFM catalog. Preserved originals inside dedicated image sets. Added aspect-fit 40-point artwork to the book/chapter picker; ID-based mapping works independently of translation/language. All 66 images load successfully in the native test bundle (one test passed). Visually checked the running light chapter picker; original contours and shadows render correctly at 40 points.

## 3. Pink appearance

Implemented semantic canvas/surface/feature/text/border roles and persisted Pink selection, with the owner’s plum accent. Home and Discover inspected in Simulator. API checks and all 210 tests passed, including preference persistence without resetting onboarding. Separately applied migration 0019 to a populated in-memory copy of the old preferences schema: every column retained and user-deletion cascade preserved. Migration 0019 applied to staging; staging Worker `6b11f02b-a93a-47b5-a2ee-518b80295f67`, clean API source `724e86f`. Disposable staging guest verified Pink/Light/Dark/System readback, unchanged onboarding, 66-book progress and new event acceptance, then was deleted. Native palette regression test passed. Pink also uses the palette for existing onboarding surfaces; no typography/layout change. Production migration/deployment pending.

## 4. Mystery Gift fallback

Implemented invitation/reveal using the four original cloud/book/envelope/flower assets, native free-reading exits, legal links, restore, and Apple purchase/server-verification integration. Normal flow only follows an actual declined standard onboarding campaign and a qualified StoreKit annual introductory offer. Eligible storefront price must be approximately 25% below the ordinary annual price (cent rounding allowed), renew at the ordinary annual price, use an upfront one-year introductory period in the same subscription group, and have no active entitlement. Eligibility/prices revalidated before purchase; reveal never purchases. Once-per-account/device invitation and account-change guards prevent repeated/misassigned offers. Existing disabled $19.99 return offers remain disabled.

Pink invitation, reveal and free-reading exit tested through the running Simulator. Light/Dark reveal screenshots inspected. Preview is explicitly labeled and cannot buy or restore. No real purchase performed; actual App Store offer configuration/availability and checkout still require verification before release.

## Final checks and boundaries

`npm run check && npm test`: 210 API tests across 15 files passed. Full Xcode test run after final refinements: 48 passed, zero failures/skips. App build remains 34. No archive, TestFlight upload, production database writes/deploy or App Store release. Source staged separately on `codex/four-handoffs`; root’s pre-existing work remains intact. Screenshots: `outputs/hercrown-2026-11-21/handoffs/`.

Manual follow-up before release: physical iPhone haptic strength, genuine StoreKit discount configuration/checkout, and full device appearance walkthrough. Font-size/welcome-layout work remains deliberately deferred.
