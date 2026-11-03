# Acceptance and verification

The building agent must complete this checklist with native evidence. The browser handoff is not proof of native implementation.

## Build and reproducibility

- Clean checkout opens, builds and runs in full Xcode with documented version/SDK and deployment target.
- Development fixture mode runs without production credentials. Release configuration contains no mock purchase success, demo legal claim or fabricated support destination.
- App assets are correctly bundled with original colors/alpha. No missing-font or missing-image fallback changes the design unnoticed.
- Environment examples, backend setup, schema migrations and service tests are documented; no secrets are committed.

## Screen parity

- Compare all eight onboarding steps against the live reference; review choice-selected, reminder-on/off, skip/back, guest and completion paths.
- Main tab order/default matches. Dock is raised neutral glass; no authored cyan/gold gradient. Selected state is clear in both themes.
- Reader shows Scripture and reference faithfully, contextual art, correct icon order and borderless insights lens.
- Rail is permanently visible, fits actual verse count and stays synchronized during forward/back scroll, scrubbing and chapter changes.
- Home greeting reflects saved profile, fire/streak is on the right, and appearance lives in Settings.
- Discover artwork varies with topic; cards have reference spacing/depth and reflections remain distinguishable from Scripture.
- Saved state is consistent across surfaces; plans open exact passages and resume correctly.
- All Settings destinations are native in-app pages with Back. Editing profile/topics never restarts onboarding.
- Profile photo picker supports selection, preview, remove/replace, canceled selection, unsupported image and recoverable storage/upload failures.
- Settings and paywall backgrounds use the shared gradient and extend to physical edges without text behind system chrome.
- Native dropdowns, time controls, share sheet and photo picker use platform conventions rather than custom web-like popups.

## Interaction and data

- Persist and restore onboarding/preferences/profile/saves/progress across app restart and migration.
- Complete a reading day once, avoid duplicate streak credit, cover local midnight, DST, missed days, future/invalid events and multi-device sync.
- Chapter rail: 1, 6, 31, a long real chapter and a stress fixture up to 300 verses; short and long text. At extreme density, preserve an accessible usable selection path.
- Disable duplicate submissions, show loading/success/errors, recover offline and resume without discarding reading position.
- Insights show correct source passage/version, real content provenance and honest unavailable/error states. No static content presented as a live model response.
- Support delivery has an actual integration or a clearly marked fixture state; no silent data transmission.
- Guest-to-account merge preserves saves and reading history; sign-out/switch/delete behavior is explicit and tested.

## Membership

- Fetch localized products, preserve annual default and clearly distinguish yearly vs weekly billing. No unapproved trial.
- Test purchase cancellation, pending, unverified result, verified success, failure, product unavailable, restore, revocation/refund, expiration and entitlement refresh.
- Free exit and close stay functional. Back from legal/privacy returns to the paywall state.
- No purchase happens during visual review. Use StoreKit configuration/sandbox with approved test accounts.

## Native visual test matrix

- Reference large iPhone composition, compact supported iPhone and at least one other supported size.
- Light/dark, long name, long chapter title, long verse and localization expansion.
- Default and largest accessible Dynamic Type; readable layouts may expand beyond exact normal-size screenshot geometry.
- VoiceOver focus order, descriptive controls, adjustable verse rail, selected states and decorative-image hiding.
- Reduce Motion, Reduce Transparency and increased contrast.
- Keyboard shown/dismissed in account/support forms; safe-area/scroll targets remain reachable.
- Network loss, denied photo/notification permissions where relevant and unavailable StoreKit products.

## Deliver evidence

Record commands/results, failing and passing tests, Xcode/SDK and device/OS versions. Capture Simulator screenshots and a short interaction walkthrough showing onboarding, reader scrubbing/chapter change, insights, Settings save and paywall cancel/restore testing. Label browser evidence separately from native evidence.

Use same app state and gradient settings for comparisons. Crop only for a measured comparison; retain full captures for context. Review side-by-side and overlays, recording deviations in typography, geometry, color, artwork, depth and safe areas. Do not accept a single hero screen as parity for the whole app.

## Open decisions / dependencies

Final logo/App Store icon; supported OS/device range; complete Scripture source and distribution rights; auth/backend providers; real support contacts; Plus gating and App Store products; AI versus curated insight scope; whether/how Community launches; production legal/privacy copy; localization and release configuration. Build reviewable local implementations while tracking these, then request concrete decisions only when they become necessary.
