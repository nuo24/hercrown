# Her Crown · iOS app

SwiftUI, iOS 17+, Xcode 26.6. One package: **SuperwallKit** 4.x (paywalls and purchases).

- Open `HerCrown.xcodeproj`, choose the **HerCrown** scheme and an iPhone, then Run. Team `494RZLCNHQ` is set; Xcode's automatic signing creates the App ID capabilities (Sign in with Apple, Push, App Group `group.com.hercrown.app`) the first time you run on a phone.
- Targets: **HerCrown** (`com.hercrown.app`), **HerCrownWidget** (`com.hercrown.app.widget`, home-screen verse widget), **HerCrownTests**.
- API: staging (`HerCrown/Core/Config.swift`). The app never holds secrets; the Superwall key in `Core/Billing.swift` is the public SDK key.
- The three offline Bibles are copied at build time from `apps/api/seeds/{kjv,bsb,web}.json`, so the app and server share one verified source.
- Artwork: `HerCrown/Artwork.xcassets` (the design kit's images, original names). App icon: placeholder crown of thorns.

Command line:
```
xcodebuild -project HerCrown.xcodeproj -scheme HerCrown -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild -project HerCrown.xcodeproj -scheme HerCrown -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -parallel-testing-enabled NO test
```

Debug-only review switches (launch arguments):
- `-hcOnboardingStep 0…7` opens an onboarding step; `-hcSkipOnboarding YES -hcTab bible|community|discover|home` opens a tab
- `-hcOpenStudy explain|deeper|original|related` opens a study tool from the reader
- `-hcOpenHome streak|devotional|plan|saved|settings` opens a Home sheet; `-hcHomeScroll search|season` scrolls Home
- `-hcFreshStart YES` starts over as a new guest at the first onboarding screen (deleting the app isn't enough: the Keychain keeps the session)
- `-hcSkipBilling YES` doesn't start Superwall. A simulator that isn't signed into an Apple Account shows "Sign in to Apple Account" when StoreKit starts; real phones signed into the App Store don't.

## Superwall dashboard (paywalls are configured there, not in code)

The app registers these placements. Each needs a campaign with a paywall, and the products `hercrown.plus.yearly`, `hercrown.plus.weekly`, `hercrown.plus.yearly.offer` added under Products.

| Placement | When |
|---|---|
| `onboarding_complete` | End of onboarding (not on the guest path). Main paywall: yearly $29.99 with 7-day trial, weekly $2.99 |
| `paywall_decline` | Superwall's built-in placement when she closes a paywall: the one-time $19.99 first-year offer (`hercrown.plus.yearly.offer`) |
| `study_explain`, `study_deeper`, `study_original`, `study_related` | A free reader opens a study tool |
| `plan_start` | A free reader starts a reading plan |
| `settings`, `settings_subscription` | Membership card and Settings → Subscription |

After a purchase or restore the app asks the server to verify it with Apple (`POST /me/restore`), so Plus unlocks at once; the webhook keeps it current. Paywall copy must spell out the trial terms and the reminder (docs/trial-reminder.md).

Status: see `docs/progress.md` (Phase 7).
