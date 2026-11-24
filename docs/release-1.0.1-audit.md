# Version 1.0.1, build 45: final release audit

Date: November 24, 2026. Result: **hold public submission for the privacy corrections below**. This is an evidence review, not a guarantee of Apple approval or a legal opinion.

## Release and review package verified

- Archive source `63008e87978b37a2117e59a3bc31394d88b7b54e`; production Release, app/widget 1.0.1(45), no staging API/Keychain or DEBUG preview automation in the app binary. Apple processed build `40cd9448-48f4-4ef5-a5f8-34f4ca13adc2` as VALID and APP_STORE_ELIGIBLE.
- Build 45 selected on version `cae4cefb-bfdd-4973-824a-1accba02e248`. Automatic release AFTER_APPROVAL independently read back. It has not been submitted to Apple.
- Draft review submission `6f2c1e01-2774-4c58-ac19-c220bb294af2` contains the app version and gift subscription version `9a4d61fc-8b36-4fff-90aa-91d3ab4a148f`, both READY_FOR_REVIEW. This state means prepared, not submitted or approved.
- Standard annual/monthly products are APPROVED. Gift product `hercrown.plus.yearly.offer` remains READY_TO_SUBMIT and is included for review. Current US schedule: $29.99 PAY_UP_FRONT for one year from November 24, renewal $39.99/year from the same date. Main annual remains $39.99 with eligible one-week trial; monthly $5.99, no trial. Native gift checks actual StoreKit pricing, group, eligibility and entitlements; unavailable/mismatched terms suppress presentation.
- Existing reviewer contact and guest/no-demo-account instructions preserved. Legal/support URLs return HTTP 200. No privacy/contact credential values are copied here.
- Owner completed migrations 0018–0020, six free-edition seeds and deployment from the archive source, Cloudflare version `0e63a432-989e-4d36-9115-4e0e3ebd0862`. Public health returns production. This does not prove authenticated feature or purchase behavior.

## Listing and screenshot accuracy

- Description and 998-character What's New match the implemented feature set; no NIV, CSB or ESV claim. These editions have not been added.
- Corrected the description to distinguish the standard yearly trial from the optional discounted first-year offer, which has no trial and renews at the standard annual price. Read back the 1,734-character description.
- Downloaded and visually inspected all 12 actual uploaded screenshot assets, six iPhone and six iPad. All Apple delivery states COMPLETE. They depict reader, Discover, study menu, Home, saved passages and dark appearance, all existing features. They use the earlier approved white/dark layouts; they are not a showcase of every new Pink/medal change. A refresh is optional marketing work, not evidence that unavailable features are promised.
- App name/subtitle, copyright, standard EULA and support/privacy links present. No ranking or guaranteed spiritual/health outcome claims added.
- Distribution readback: 174 territories enabled, mainland China disabled. The generic China AIGC/security notices do not establish a China distribution blocker for the current disabled territory. No territory changes made.
- Age declaration is 4+ with no ads, gambling, public chat or unrestricted web access; the app is not declared in the Kids category. New location-sharing/dating responses were not modified. This review does not independently classify every Bible passage against local content rules.

## Corrections required before submitting this build

### 1. Explicit permission for personal-context AI prayer

Source: `apps/ios/HerCrown/Features/Onboarding/OnboardingView.swift`, footnote and prayerPreparation/preparePrayer; `PersonalPrayer.swift`, prayerInput.

Build 45's only local disclosure says optional answers are sent to a prayer provider. It does not name OpenRouter/DeepSeek, and reaching step 10 starts the request automatically. The payload includes normalized first name, life season, familiarity, selected needs and optional burden/loved-one text. Skipping optional free text does not constitute a separate permission choice for the other personal context. The non-AI simple prayer is offered after generation fails, rather than as an equal choice before transmission.

Apple guideline 5.1.2(i) requires clear disclosure and explicit permission before sharing personal data with third-party AI. Add a concise pre-request choice naming the providers and data sent, with an equally accessible local/simple prayer path; ensure no request begins before opt-in, including resumed onboarding and back navigation. Verify the no-consent path produces zero AI request. This requires a new binary; uploaded build 45 cannot be edited.

Reference: https://developer.apple.com/app-store/review/guidelines/#data-use-and-sharing

### 2. App and widget required-reason privacy manifests

The archived app contains SuperwallKit's PrivacyInfo.xcprivacy with a file-timestamp declaration. No Her Crown app or widget PrivacyInfo.xcprivacy was found in the source or archive. Her Crown uses UserDefaults.standard and shared App Group defaults; the widget uses shared defaults too. A dependency manifest does not describe the app's own UserDefaults use.

Add target-bundled manifests with truthful required-reason declarations: CA92.1 for app-only preferences and 1C8F.1 for same-App-Group shared preferences where used. Review any other required-reason APIs actually called, and inspect both the final app and extension archive. Do not invent declarations for APIs not used. Upload acceptance does not prove this source/archive gap is safe to ignore. This requires a new binary.

References:
- https://developer.apple.com/documentation/foundation/userdefaults
- https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest

### 3. Published legal text still says Draft

Actual production GET /legal/privacy contains “Draft, last updated November 3, 2026. Have it reviewed before launch.” Source terms and refunds have the same draft marker. The legacy reference-web privacy copy also predates the newer email/prayer disclosure, but it is not a bundled native fallback: the current native legal view opens the public page in Safari. Finalize the public wording/date and keep any retained reference copy consistent; do not imply legal review occurred if it has not. Production document deployment remains human-run under AGENTS.md.

### Additional disclosure alignment

Published App Privacy lists 12 data types, including Sensitive Info linked to identity for functionality/personalization. Email Address currently lists App Functionality only. Account email-update opt-in is implemented, but this audit did not establish that marketing mail is being sent. Before using collected emails for developer marketing/news campaigns, align the Email Address purposes and policy with that use. Do not silently treat sign-in or a subscription as mailing-list consent.

## Content and rights audit

- Rechecked the original source rights statements for ASV, YLT, Darby, Webster, MSB and RV1909. All six explicitly state public domain. Source identifiers/checksums, expected verse counts and attributions are recorded in `apps/api/scripts/free-editions.json`; required content checks previously verified the pinned imported texts and source omissions. No Scripture was edited in this audit.
- Rights statements: https://ebible.org/asv/copyright.htm ; https://ebible.org/engylt/copyright.htm ; https://ebible.org/engDBY/copyright.htm ; https://ebible.org/engwebster/copyright.htm ; https://ebible.org/engmsb/copyright.htm ; https://ebible.org/spaRV1909/copyright.htm .
- NKJV/MSG/AMP/NLT remain API.Bible-backed with copyright attribution; no protected full-text seed was added. The owner's paid-provider report is recorded, but the actual contract's commercial, territorial, share-image and widget rights were not available to this audit. A focused search of connected Gmail found no matching license/invoice email. Do not represent those rights as independently certified or infer unrestricted rights from a successful API response.
- Credits record owner-confirmed Community photo permissions and representative-photo attribution. Community giving uses an owner-reported $7,350 aggregate and 30% commitment. No financial receipt/ledger reconciliation was performed here; these numbers are not newly verified revenue/donation data.
- AI commentary is separate from Scripture, cited, with reporting controls. No fabricated medal ownership percentages or invented Scripture claims were introduced.

## Functional checks and limits

- Required content/type checks and 220 API tests passed in this release cycle. Full native suite passed 70 tests, including deletion account-mismatch protection, staging isolation, chapter-completion/cooldown, offline fallback, gift pricing/paper and medal progress cases. A fresh API/content rerun is recorded in the audit output directory.
- Prior running Simulator inspections cover Pink/Light/Dark, four-column book gallery, Home/Discover, original grey medal icons and the native paper animation. No new feature code was changed during this audit.
- Not completed on the production-connected physical build: fresh Sign in with Apple, successful sandbox checkout, Plus unlock, sandbox restore, gift purchase/reporting, and deletion of a dedicated test account. Real purchases require an eligible signed-in Apple tester, and production data writes are prohibited for the agent. Public health and automated tests do not substitute for these checks.
- No public review submission or release performed. Automatic release remains enabled at the owner's request. Correct the privacy issues, upload a replacement build, repeat relevant checks, and then submit the app and gift together.

Evidence: `/private/tmp/hercrown-release45-20261124/audit/` (App Store readback, actual screenshot contact sheet, content/type and test logs). Source and deployment IDs above remain fixed even if audit documentation receives later commits.
