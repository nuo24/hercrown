# Implementation brief for the building agent

## Mission

Build Bible Scroll as a complete native iOS app with the visual and interaction fidelity of the included working mockup. The primary audience is women. Preserve its current structure, typography, contextual photographic illustrations, live gradient, neutral raised dock, reader rail, onboarding, paywall and detailed Settings. Deliver maintainable native code with the services, persistence, tests and documentation needed for a real product.

This is an implementation mandate, not a request for another design proposal. Inspect, run, implement, verify and iterate. Do not stop at a plan, a static screenshot or the existing partial SwiftUI source.

## Fidelity and freedom

Match the current reference at normal text size on the large-phone reference composition first. Use the same assets, content order, icon geometry, color relationships, spacing, shadows and interaction intent. Then adapt naturally to other iPhones, Dynamic Type, keyboard presentation, accessibility and system safe areas. Functional accessibility takes precedence over clipping text to force a pixel match.

You may add necessary screens, components, backend services, error/loading/empty states and engineering infrastructure without treating this document as a closed feature ceiling. Fill gaps with coherent native behavior and the existing visual vocabulary. Make routine implementation choices independently and document them. Escalate decisions involving real commercial terms, provider credentials, new paid services, publishing or major changes to approved product behavior. Do not silently redesign the established screens or invent approval for branding, prices, legal policies or theological content.

Existing mock limitations are implementation gaps, not instructions to ship broken or placeholder features. Clearly track each gap and either implement it fully or report the exact external dependency blocking it. Never disguise fixtures as real accounts, AI, messages, subscriptions or community activity.

## Read and inspect first

1. Read this file, `specs/CURRENT-DESIGN.md`, `specs/SCREEN-MAP.md`, `specs/FULL-STACK.md` and `specs/ACCEPTANCE.md`.
2. Run the browser reference using README. Review every onboarding step, all four tabs, the reader rail, saved passages, plans, insights, paywall and all Settings destinations in both appearances.
3. Study current CSS in its actual import order from `reference-web/dist/index.html`. Later styles override earlier layers. Do not port an old CSS file in isolation.
4. Inspect `starter-ios/`. It is an earlier SwiftUI baseline, not the current spec. Inventory its missing flows before extending it.
5. Inspect asset and icon manifests. Reuse included artwork; no emoji substitutions or placeholder boxes for supplied assets.

## Native architecture

Use SwiftUI as the default implementation because the supplied project already uses it. Keep the supported OS baseline explicit. The starter targets iOS 17 and references newer conditional APIs; verify it with the installed full Xcode SDK. Do not promise compilation merely because source parsing succeeds. If platform APIs have changed, consult current Apple documentation during the build.

Use an app-owned route/state model, separate navigation stacks where appropriate, typed domain models, dependency-injected repositories and testable services. Keep network, persistence and UI responsibilities separate. Do not reimplement the browser DOM or embed the app in a WebView.

Suggested modules: DesignSystem, Onboarding, Reader, Discover, Home, Community, Settings, Membership, Scripture, Profile, ReadingProgress and service adapters. Use an explicit environment/configuration layer for development, fixtures, staging and production.

Use system status bar, Dynamic Island and home indicator behavior. **Never render the fake browser phone frame, time, battery, notch or home pill in native content.** Backgrounds may extend into safe areas; controls and text must respect them.

## Implementation sequence

### 1. Establish an executable baseline

Open the Xcode project, resolve build diagnostics, set development identifiers/signing placeholders appropriately and run in Simulator. Record Xcode/SDK, deployment target and exact build/test commands. Keep the app usable without production credentials through explicit fixture repositories. Import the supplied artwork catalog and verify image names.

### 2. Reconstruct the shared visual system

Implement semantic light/dark colors, regular/italic serif accents, native sans UI, spacing, continuous radii, shallow and floating elevation, button variants, native pickers, neutral translucent dock and common sheets. Reproduce the gradient algorithm from `gradient-theme.js`, including optional third color, intensity, reach and direction. Keep one shared gradient source for all screens and paywall. The desktop editor is a design tool; do not insert its outer panel into native app content.

Create a developer preview/gallery for shared components, illustrations and gradient tuning. Preserve the shipped defaults separately from any reviewer’s local editor snapshot.

### 3. Build the reader and app shell

The Bible is the leftmost tab and default destination. Tab order is Bible, Community, Discover, Home. Build actual bidirectional reading and chapter navigation, persistent segmented left rail, contextually chosen illustrations, neutral action icons and a lens-with-sparkle insights button above the heart. The lens has no surrounding border, background or shadow. Changing chapters regenerates the rail from real verse counts and returns to verse one. Handle one verse, short chapters, 31 verses, long chapters and variable text height.

### 4. Port onboarding faithfully

Implement all eight steps and their copy/assets, optional skips, back behavior, guest access, persistence and completion. The paywall follows completed onboarding and remains dismissible. Settings edits must never reset onboarding. Keep Scripture separate from reflective copy. Do not add fabricated usage statistics or testimonials.

### 5. Complete the core content flows

Implement Home, streak behavior, Discover filtering, saved passages, reading plans, reflection and insights. Preserve stable passage IDs while moving to a canonical reference model. Start with fixtures for visual parity, then integrate a complete licensed Scripture source. Never fabricate verse text or chapter counts to match a visual sample.

### 6. Complete Settings as real destinations

Build in-app pages for account editing/photo picker, reading topics, appearance, subscription, contact/support, About, Privacy, Terms and credits. Include back navigation and safe-area/keyboard handling. Saving settings returns to Settings. The restart-onboarding button belongs to developer tooling, not normal preference editing.

Use PhotosPicker or another native user-selected photo flow, preview and remove/replace, validation, upload progress and recoverable errors. Local guest profiles should remain usable without forced registration. Name changes update the greeting. Topic changes do not alter Scripture. Support forms need real delivery integration before production; mock mode must remain visibly identified.

### 7. Implement membership, account and service integrations

Reproduce annual $29.99 and weekly $2.99 plan presentation, annual initially selected, visible billing cadence, free-reading exit and no trial by default. These are proposed design prices; fetch localized product data from StoreKit in production. No invented entitlement after tapping Continue. Implement purchase, restore, pending, cancellation, error and entitlement refresh flows, server verification where needed, and development StoreKit configuration. Follow current platform requirements when implementing purchase/account behavior.

Add accounts and secure sync without blocking guest reading. Keep credentials out of the client and repository. See FULL-STACK for domain/service contracts. Do not publish or make real purchases during development without authorization.

### 8. Finish and verify

Run native build and tests, capture Simulator screenshots and interaction evidence, compare against the reference and fix discrepancies. Review both themes, reduced motion/transparency, accessibility contrast, VoiceOver, large text, keyboard, offline use, failure states, long chapters and restoring purchases. Produce a gap checklist that distinguishes completed work from external blockers.

## Definition of done

- Native app builds and runs with documented commands and no unexplained warnings or broken routes.
- Current mockup screens are reproduced at normal scale, with responsive native adaptations rather than fixed screenshot layouts.
- All assets and licenses are accounted for; no old tinted dock, cream/purple Settings slab or outdated rail behavior returns.
- Settings has working detail pages and profile editing; onboarding completion is not cleared by settings changes.
- Subscription, account, Scripture, support and insight behavior is connected or explicitly blocked by named dependencies; fixture mode is never mislabeled as production.
- Meaningful unit, service and UI tests pass, with Simulator/device evidence and a completed acceptance checklist.
- Deliver source, setup/config examples without secrets, schema/migrations, service contracts, tests, visual evidence, known limitations and run/build instructions.

## Do not carry forward these prototype shortcuts

Browser localStorage as the production account store; hardcoded localized billing labels; fake restore confirmations; hardcoded KJV sample counts; mock support numbers; sample insights labeled as live AI; fixed 62/34px safe areas; desktop popup appearance mistaken for an iOS picker; browser-generated device chrome; old starter tabs or typography overriding this reference.
