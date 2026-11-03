# Her Crown · iOS app

SwiftUI, iOS 17+, no third-party packages yet (Superwall comes with the paywall). Xcode 26.6.

- Open `HerCrown.xcodeproj`, choose the **HerCrown** scheme and an iPhone simulator, then Run. To run on a phone, set your team in Signing & Capabilities.
- Bundle id: `com.hercrown.app` (change in the target's build settings if you register another).
- API: staging (`HerCrown/Core/Config.swift`). The app never holds secrets.
- The three offline Bibles are copied at build time from `apps/api/seeds/{kjv,bsb,web}.json`, so the app and server share one verified source.
- Artwork: `HerCrown/Artwork.xcassets` (the design kit's 28 images, original names).

Command line:
```
xcodebuild -project HerCrown.xcodeproj -scheme HerCrown -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -project HerCrown.xcodeproj -scheme HerCrown -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -parallel-testing-enabled NO test
```

Debug-only review switches (launch arguments): `-hcOnboardingStep 0…7` opens an onboarding step; `-hcSkipOnboarding YES -hcTab bible|community|discover|home` opens a tab.

Status: see `docs/progress.md` (Phase 7).
