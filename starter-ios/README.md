> HANDOFF WARNING — This is an earlier, incomplete native starter. It does not reproduce the final browser mockup. Read ../IMPLEMENTATION.md and ../specs/CURRENT-DESIGN.md before building. Statements below describe historical scope/verification and are not current parity claims.

# Bible Scroll · native iOS implementation source

Open `BibleScroll.xcodeproj` in full Xcode, select the BibleScroll scheme and an iPhone simulator, then Run. Deployment target: iOS 17+. No third-party packages are required. For physical devices, choose your development team and a unique bundle identifier in Signing & Capabilities. The example identifier is com.example.BibleScroll.

This is SwiftUI source, not a webview wrapper. TabView, NavigationStack, Form, Picker, Menu, ShareLink, native sheets, SF Symbols and system safe areas provide platform behavior. iOS itself draws the status bar, Dynamic Island and home indicator. Never put the browser preview's fake hardware or system chrome into the native view hierarchy.

## Included

Home, Discover topic filtering, saved passages, paged sample reader with chapter selection, reflection sheets, plan selection, and appearance/reading-intention preferences. Saved passages and preferences persist locally. Scripture uses the KJV fixtures copied from the existing demo, with identifiers preserved. Navigation and controls use Dynamic Type system text; Georgia regular/italic appears selectively in Scripture and the devotional heading. Semantic system colors support System/Light/Dark.

The native sample retains the web app's four primary destinations. Community remains an explicit unavailable state. It is not a cloud account, full Bible library, social product or notification scheduler. The browser retains the original seven-step onboarding. That onboarding has not yet been ported into this native sample. Reading-plan selection persists; full native plan-progress tracking is not implemented.

## Verification limits

Swift parser checks and Xcode project property-list validation passed. Full Xcode is not installed on this machine (`xcode-select` points to CommandLineTools, and simctl is unavailable). Compilation, SwiftUI type checking against the iOS SDK, Simulator rendering, native gestures, Dynamic Type layouts and device performance remain unverified. Fix any SDK/compiler diagnostics in Xcode before treating this source as a runnable build. Browser screenshots demonstrate the web preview only.

## Visual mapping

Altitude's white/black hierarchy, 14pt continuous panels, fine separators, 24pt operational gutters and capsule actions underpin the UI. The user's serif screenshot deliberately modifies the source type system. This is an Altitude-informed Bible Scroll adaptation, not exact parity with the Altitude site. The proprietary GT Standard font is not included. SF is used for native UI; Georgia for the selected regular/italic accent.

Depth revision: shared Panel now has three neutral shadow layers; the Home Scripture panel sits within a generated photographic SkyStage. PillButton animates only its capsule fill, respects Reduce Motion and preserves label alignment. quiet-sky.png is an included app resource; provenance is in ../dist/assets/quiet-sky.provenance.json. These native visuals are unverified until built in Xcode.

Liquid Glass revision: use Xcode26 or newer to compile the current source. SystemGlassTabBar keeps the native TabView material and conditionally uses tabBarMinimizeBehavior(.onScrollDown) on iOS26+, with the original system tabs on older supported systems. The new Restart onboarding button is in the browser-preview toolbar; native onboarding is still outside this source sample's completed scope.
