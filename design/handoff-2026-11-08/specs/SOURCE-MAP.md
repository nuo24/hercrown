# Source map

Current web under reference-web/dist:
- index.html: CSS order and current entrypoint; ios-preview.html/review-desk.mjs: development tools only.
- app.js: root, navigation, reader/header/dock glyphs, current module wiring.
- native-review.mjs: full route/subpage/overlay states and studio integration; native-data: bundled reference fixture data.
- personal-home.mjs/css: personal library/profile layout and notes/bookmarks row spacing.
- discover-model.mjs, discover-featured.css, discover-editorial.css: contextual artwork, featured passage and sticky Discover.
- community-voting.mjs/css, community-photos: approved gallery/voting and nomination pages.
- onboarding-new.mjs/css, opening.mjs, personal-onboarding-motion.mjs, onboarding-motion.css, onboarding-reminder.css: current personalized onboarding, copy, gates and native-style preview.
- verse-studios.mjs/css, studio-model.mjs: both editors, rendering/storage/export, tray and gesture behavior.
- paywall.mjs/css: current annual/monthly offer and dynamic disclosures; pure-white.css: final light/dark palette; quiet-chrome.css/safe-areas.css: final menu/edge treatment.
- streak.mjs: recorded-day calculations; streak-activity.mjs/rhythm.css: Week/6months and compact sheet.
- app-icons/manifest.json: current4icons/default; illustration-pack and assets/fonts: actual artwork and DM Sans.

Native baseline under native-baseline/apps/ios/HerCrown:
- App/HerCrownApp.swift, Features/Shell/RootView.swift: process/navigation/lifecycle.
- App/ColdLaunchView.swift, CrownMesh.metal.txt: existing actual-logo renderer to verify.
- Core/AppModel.swift, APIClient.swift, Billing.swift, WidgetBridge.swift: preserve real integration.
- Features/Reader, Study, Home, Library, Discover, Onboarding, Settings: existing views/models to evolve.
- Design/VerseShareButton.swift: replace simpler snapshot with studio entry while retaining textshare.
- ../HerCrownWidget/HerCrownWidget.swift: extend existingwidget for saved design.
- Artwork.xcassets: native baselineassets; import current design/Artwork.xcassets updates and compare beforeoverwriting.
- apps/api/src + migrations + seeds: preserve API/contracts. New community/design serverfeatures require explicit integration, not fixture endpoints.

Machine-generated CSS/source/asset usage inventories are in design. Root specs override historical README/specs inside baseline when appearance/copy/pricing differs. Use native docs for service behavior and environment setup, not old visual instructions.
