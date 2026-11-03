# iOS design implementation · 31 October 2026

The requested target is Bible Scroll, confirmed by the user. The Altitude reference artifact is unchanged. A final override stylesheet `dist/altitude-ios.css` applies its visual relationships to the existing functional demo without replacing its data and interaction code. This deliberately supersedes the prior Origin/Lassie styling; earlier styles remain for the existing onboarding and outside-scope elements.

## Preview

Open http://127.0.0.1:8879/ios-preview.html. The simulated iPhone uses a 440×956pt display composition, with a Dynamic Island, status icons, side controls and home indicator. Its metal frame fits the browser while preserving the screen's proportions. A fixed 440×860 iframe reserves 62pt above and 34pt below for simulated system chrome. These insets and hardware details are visual approximations, not measured Apple hardware specifications. The actual native app uses system insets instead.

Apple's published iPhone 17 Pro Max layout is 440×956pt at3×: https://developer.apple.com/design/human-interface-guidelines/layout. Product specification: https://support.apple.com/en-us/125091.

The preview chrome follows the app's light/dark state; fake chrome is aria-hidden. Appearance control invokes the app's existing theme action. Onboarding, saved passages, preferences, plan selection, topic filtering, reading, chapter selection and reflection behavior remain in existing JS.

## Typography and design

System sans carries headings, body labels, tabs and controls. Regular Baskerville/Times serif carries Scripture; an italic phrase in “Make room / for the Word.” demonstrates the user-requested pairing in a selected devotional moment. Native SwiftUI uses Georgia regular/italic with Dynamic Type scaling. Exact font identification from the screenshot is not verified, and no commercial font was copied.

White canvas, black text/actions, #fafafa supporting surfaces, #e5e5e5 borders, #737373 metadata, 14px panels, 24px operational gutters and capsule CTAs come from the measured Altitude kit. Dark mode uses semantic equivalents. Floating and supporting panels use role-specific neutral layered shadows; controls use inset edges. A generated sky photograph frames the opaque daily-verse panel; the existing reading-plan thumbnail remains. Source-like fades support the scene and a subtle devotional-surface lighting gradient. iOS system/brand changes mean this is not claimed as source-site 1:1 parity.

## Native source

`ios/BibleScroll.xcodeproj` contains SwiftUI source and local sample Scripture JSON. Native UI uses platform controls, SF Symbols, safe areas and sheets; no fake device border, notch or status bar is inside the native app. Source parser and pbxproj validation passed; iOS SDK compilation and Simulator QA are unavailable without full Xcode. See ios/README.md for scope and unported flows.

## Executed checks

Existing state tests passed: seven-step navigation, back state, selections, multiple topics, skip, reminders, completion, guest access, persistence and malformed-data recovery. JS syntax passed. Native Swift parser and Xcode pbxproj plist validation passed; JSON has 19 unique passages including five Genesis 1 and six Psalm 23 verses. These checks are not iOS SDK type checking.

Browser checked Home, Discover, dark appearance with matching preview status/home chrome, study sheet, regular/italic devotional pairing, reader safe-area layout and chapter selection Genesis 1 → Psalm 23. Saved state remained present. Screenshots are docs/screenshots/ios-home-light.png, ios-discover-dark.png, ios-study-dark.png, ios-serif-variation.png and ios-reader-light.png. All are browser captures, not Simulator evidence. Compact native devices, native Dynamic Type and VoiceOver remain unverified.

## Depth correction

User feedback identified the flattened surface treatment. Corrected the missing source relationships: layered floating-sheet and paper shadows, shallow control shadows, inset strokes, isolated button fill with1.04 hover/.96 press scaling and stationary label, dual focus rings and reduced-motion support. Browser SVG paths now come from one Lucide set (ISC license in assets/LUCIDE-LICENSE.txt); SwiftUI retains SF Symbols.

Sky photo generated for this app; exact generation prompt retained with the asset. The sky/fade composition is a Bible Scroll adaptation of the reference relationship. The source scene/shader is not recovered. Supporting-card shadow strength, gradients on the devotional surface, circular icon wells and dark equivalents are deliberate adaptations; source numerical shadows are recorded in the Altitude kit depth tokens and audit supplement.

Browser exercised Study this verse → reflection sheet → close, light/dark appearance and matching chrome after the correction. Final captures ios-depth-home-light.png and ios-depth-home-dark.png show this correction; previous ios-*.png captures predate it. Existing state tests, JS syntax, Swift parser and Xcode project plist checks passed again. Native SDK compilation and Simulator verification remain unavailable.

A fresh independent review was requested for the depth correction but could not run because the reviewer hit the account usage limit. Final visual checks were performed by the build thread; this correction has no independent review verdict.

## Screenshot-led background, spacing and scroll revision

The user's IMG_4002.jpeg pins a near-white reading surface with a pale neutral, segmented vertical verse rail on the right. Interpreted the unspecified background color from that screenshot: reading canvas #fdfdfd, Home/Discover #f7f7f9, white cards, #e5e5e8 separators. Dark mode preserves semantic contrast. Card rhythm is now16px gaps,20px standard padding/gutters,16px corner radius, a16px inset around the sky feature, and role-specific restrained shadows. Earlier spacing notes are superseded by this revision.

Replaced the old vertical range input with a segmented slider: one segment per available verse, active segment/number, and actual chapter total. The sample library still contains five Genesis1 and six Psalm23 verses; it does not fabricate31 verses to resemble the crop. The rail supports pointer drag/click, ArrowUp/ArrowDown, PageUp/PageDown, Home/End, accessible value text and focus. Main reading supports scrolling in both directions with proximity snapping rather than mandatory one-page locks. Visible verse is computed from actual page offsets, so variable-height pages do not accumulate fixed-height drift. Resize observers disconnect on rerender; reduced-motion removes smooth programmatic scrolling. Native SwiftUI source now includes the matching rail, adjustable accessibility action, drag handling and less restrictive view-aligned scrolling, plus expanding text containers.

Browser verified down to verse2, up to verse1, End to verse5, and dragging backward to verse2. Light/dark reader captures are ios-segmented-reader-light.png and ios-segmented-reader-dark.png. The preview appearance toggle now works while reading, without requiring a hidden settings button. Unit checks in reader-scroll.test.mjs cover bounds, drag mapping, variable-height offsets and reverse navigation. Existing state tests passed. Swift parsing passed; native SDK compilation/Simulator testing remains unavailable. No independent review is claimed for this revision.

## Complete chapter block counts

Genesis1 now includes all31 KJV verses, loaded locally from dist/chapters.mjs; Psalm23 retains all6. Earlier notes describing a five-verse Genesis sample are superseded. Genesis text was retrieved from https://bible-api.com/genesis%201?translation=kjv, whose response identifies KJV as Public Domain. Only whitespace was normalized. Native bundled passages.json contains the same31 Genesis verses, preserving prior identifiers/saved references.

The rail creates exactly one equal block per chapter verse. Genesis1 displays31 blocks and the total31; Psalm23 displays6. Selecting the bottom block was verified to open verse31. Counts/reference uniqueness and31-position input mapping are covered by reader-scroll.test.mjs. Final capture: ios-31-verse-blocks.png.

## Contextual left-edge verse dock

Moved the verse rail to the left as a44px interaction overlay; it no longer reserves a permanent column or draws a background strip. It is transparent while idle, reveals on scroll/pointer/keyboard interaction, and fades1second after the last activity. Hover and keyboard focus retain visibility for discoverability/accessibility. Scrolling still updates the active verse. Block magnification follows a symmetric Gaussian falloff (peak1.8× width, restrained vertical expansion); neighbors smoothly taper toward1×, with no page reflow. Pointer position drives the magnification focus during scrubbing. Reduced Motion disables magnification and transitions while preserving reveal/navigation.

Browser verified appearance while scrolling, idle disappearance, and left-rail drag to verse10. Captures: ios-left-dock-active.png, ios-left-dock-idle.png and ios-left-dock-drag.png. dockScale unit checks verify the peak, symmetry and distance falloff. SwiftUI source uses a leading overlay and matching scaling/reveal behavior; native rendering and VoiceOver behavior still require Simulator/device verification.

## Floating glass dock and preview restart

The user explicitly requested Liquid Glass. Browser bottom navigation now floats above the content as a translucent capsule with28px backdrop blur, restrained saturation, an inset edge highlight, neutral elevation and a raised active-tab pill. The dock has16px horizontal clearance and12px bottom clearance within the preview's already-safe content frame. Reading space/rail bounds reserve96px below content for the dock. Light/dark variants, visible keyboard focus and opaque reduced-transparency/high-contrast fallbacks are included. This is a web approximation, not Apple's native compositor.

Restart onboarding is now an always-available preview-toolbar button. It emits a dedicated app event that resets only completed/step, persists the state, returns to the top, and focuses the welcome heading. Saved verses, topic preferences, selected plan and reading intention are retained. Browser verified Home → Restart onboarding → welcome → Explore as guest → Home; the existing saved Psalm23:1 remained selected. Captures ios-liquid-dock-light.png and ios-liquid-dock-dark.png show the dock and button.

Native SwiftUI retains TabView to receive the platform Liquid Glass tab bar with the iOS26 SDK. SystemGlassTabBar conditionally requests onScrollDown minimization on iOS26+, preserving older-system behavior. Native source now requires Xcode26+ to compile the new API references, although deployment target remains iOS17. Native onboarding remains an unported flow as documented; the new restart control is a web-preview control. Native appearance, minimization and SDK type checking remain unverified without full Xcode.

Apple source: https://developer.apple.com/videos/play/wwdc2025/323/ and https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views.
