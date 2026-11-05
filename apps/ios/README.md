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
- `-hcPaywallDiagnostics YES` shows the skip or error reason and Her Crown, Superwall, and StoreKit subscription statuses after a failed paywall attempt.

## Superwall dashboard and sandbox return offer

The app registers these placements. Main placements need a Superwall campaign with the yearly and weekly products. Keep the old `paywall_decline` placement paused; the sandbox return offer is presented in the app on a later reopen.

| Placement | When |
|---|---|
| `onboarding_complete` | End of onboarding (not on the guest path). Main paywall: yearly $29.99 and weekly $2.99, each with a 7-day trial for eligible users |
| `study_explain`, `study_deeper`, `study_original`, `study_related` | A free reader opens a study tool |
| `plan_start` | A free reader starts a reading plan |
| `settings`, `settings_subscription` | Membership card and Settings → Subscription |

For the onboarding paywall layout, use the [mockup markup](../../reference-web/dist/paywall.mjs) and [styles](../../reference-web/dist/paywall.css). The hero layers the original cloud bank, open book, and cosmos illustrations from the [illustration pack](../../reference-web/dist/illustration-pack). Keep the yearly and weekly options, close and restore controls, and free-reading exit. Use the product and trial terms from [decision 0003](../../docs/decisions/0003-trial-hard-paywall-decline-offer.md) when configuring the campaign.

After a purchase or restore the app asks the server to verify it with Apple (`POST /me/restore`), so Plus unlocks at once; the webhook keeps it current. Paywall copy must spell out the trial terms and the reminder (docs/trial-reminder.md).

Status: see `docs/progress.md` (Phase 7).
