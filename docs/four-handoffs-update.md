# Four handoffs — development verification

2026-11-21. Working against build 34. No archive, upload or production release. Font sizing/welcome-screen changes are explicitly excluded.

## 1. Faith medals

Imported all seven original PNGs after SHA-256 verification. Native Home entry after Verse of the Day; five collections; horizontally snapping carousel with subtle selection haptics; grid selection; account-scoped server progress/cache; real qualifying goals; locked grayscale; 1200×1200 PNG export through the native share sheet only for qualified medals. Rarity labels indicate goal difficulty, not fabricated population statistics. Goals are in decision 0015.

Xcode Debug build succeeded. Ran in isolated iPhone 17 Pro/iOS 26.2 Simulator: real test-account progress 1 day/1 chapter, zero medals collected. Visually checked light screen, collection navigation and grid selection. Three native eligibility tests passed (both conditions required; book-specific counts; unique catalog/long goals). Physical haptic strength still needs an iPhone check. Milestone progress syncs from the existing API; awards are derived, with local first-detection dates, not a new server-issued reward ledger.

## 2. Bible-book artwork

Verified all 66 SHA-256 hashes and all English book names against the canonical USFM catalog. Preserved originals inside dedicated image sets. Added aspect-fit 40-point artwork to the book/chapter picker; ID-based mapping works independently of translation/language. All 66 images load successfully in the native test bundle (one test passed). Visually checked the running light chapter picker; original contours and shadows render correctly at 40 points.

## 3. Pink appearance

Implemented semantic canvas/surface/feature/text/border roles and persisted Pink selection, with the owner’s plum accent. Home and Discover inspected in Simulator. API checks and all 210 tests passed, including preference persistence without resetting onboarding. Separately applied migration 0019 to a populated in-memory copy of the old preferences schema: every column retained and user-deletion cascade preserved. Remote migration/deployment pending. Native palette regression test running.

## 4. Mystery Gift fallback

Pending implementation and verification. Actual discounted product availability and first-year/renewal terms must resolve before a purchase is offered. No remote offer is enabled by this handoff.
