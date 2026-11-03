# Current design authority

Snapshot: November 2, 2026. Target: the current Bible Scroll mockup, translated faithfully to native iOS. Historical Lassie/Origin/Altitude explorations explain the evolution but are not competing design systems for the build.

## Non-negotiable current decisions

- Bible is the first and default tab, followed by Community, Discover, Home.
- A lifted floating capsule dock with neutral translucent glass, shallow edge highlights and soft depth. **No authored blue/cyan-to-yellow/gold dock gradient.** Backdrop colors may naturally show through transparency; that is different from baking in a colored gradient.
- Shared editable sage/sky gradient, with an optional third color. Settings and membership use the same source. No separate cream, purple or opaque page-sized Settings background.
- Full display background coverage, including behind system safe areas. Content avoids the notch/status bar, home indicator and dock. Native system insets replace preview constants.
- One persistent left-edge segment per verse in the active chapter. It does not disappear while idle. Counts and segment sizing adapt to each chapter. Gentle focus magnification is preserved without moving text layout.
- Serif Scripture and selective regular/italic editorial emphasis. UI labels and controls use a consistent native sans. No mixed decorative fonts throughout the app.
- Consistent outlined action icons. The reader insights control is a magnifying lens containing a small sparkle; it sits above the heart with **no enclosing well, border or shadow**.
- Photographic paper-cutout illustrations are contextual, dimensional and varied. Do not substitute emoji or recolor them as template icons. Scripture remains visually primary.
- All dropdowns are system-owned selection controls. Native SwiftUI Picker/Menu presentations should match the situation; do not reproduce browser options as a custom HTML popover.
- Settings destinations are proper in-app pages, not onboarding links. Topic/profile edits do not clear onboarding completion.
- Current paywall prices are mock USD $29.99/year and $2.99/week, annual selected initially, no trial, dismissible/free-reading exit. Buttons follow the neutral app palette, not green.

## Visual source and typography

`reference-web/dist/index.html` defines the actual CSS import order. `altitude-ios.css` changes the earlier font tokens to `-apple-system, BlinkMacSystemFont, Helvetica Neue, sans-serif` for UI and `Baskerville, Times New Roman, serif` for display. The native starter’s Georgia is an older approximation; match Baskerville regular and italic where available and validate metrics on iOS. Use scaled metrics/Dynamic Type rather than fixed point sizes that clip.

Typical final sizes: reader Scripture 31px/1.25; app headings 28px/1.05; onboarding introduction 37px/1.12; membership heading 39px/1.05; Settings profile 30px/1.15; UI body 13–16px; metadata 10–12px in the browser. Convert CSS units to points as a starting relationship, then compare in Simulator. Native accessibility may require larger minimum metadata and expanded layout.

Spacing scale: 4, 8, 12, 16, 20, 24, 32, 40, 48. Operational gutters are generally 20–24; Settings uses 22. Standard cards use 16px continuous radii; grouped Settings sections 18; feature card 20; interactive capsules fully rounded. Use the exact component styles when a role differs from the global token.

Light: primary text #111; primary surface #fff; supporting surface #f2f2f4; muted text #717177; fine border #e5e5e8. Dark equivalents vary by component; use the final cascade and semantic role, not a global inversion. Never tint all neutral actions green because the gradient includes sage.

## Depth and controls

Preserve layered neutral elevation, not hard borders around everything. Read final component shadows in `altitude-ios.css`, `settings.css`, `paywall.css`, `expressive-topics.css` and `liquid-dock.css`. Buttons use text/surface semantic foreground/background. Retain a visible focus/pressed state and native minimum targets. SVG base icons use a 24-unit viewBox, round caps/joins, stroke 1.65; reader/dock overrides vary slightly. Native SF Symbols may substitute only when their geometry/weight match. Use supplied custom lens paths when no symbol fits.

The glass dock is a browser approximation. Native system materials/glass are preferred where they reproduce the reference. Preserve the neutral capsule and tab order even when using platform APIs. On older supported OS versions, provide a neutral material fallback. Support Reduce Transparency and Reduce Motion.

## Shared gradient algorithm

Canonical source: `reference-web/dist/gradient-theme.js`.

Defaults: colors #e4eddf, #e0edf5, #eadff0; third off; intensity 100; reach 49; angle 165. Reviewer-local settings may differ. `design/gradient-review-snapshot.json` records one observed state (29% intensity, 59% reach); it is not a new product default.

For light: alpha=intensity/100. First ellipse at (0%,14%) uses color0 and fades to transparent at reach%. Second at (100%,74%) uses color1. Optional third ellipse at (52%,100%) uses color2 at alpha×0.8. Composite in the same front-to-back order over a linear gradient from white to #f5f8f7 at the chosen angle. For dark: alpha=intensity/100×0.20, base linear gradient #101314 to #121619. Match the CSS radial ellipse sizing/composition with a native Canvas/shader if default SwiftUI radial gradients differ. Keep a shared configuration model; do not hardcode a separate gradient into membership or Settings.

## Artwork rules

The 25-item illustration pack contains 24 cutouts plus one transparent cloud bank. Three additional PNGs are the onboarding collage, meadow photo and sky scene. All 28 are catalogued. Original aspect ratio, alpha and embedded contours/shadows are intentional. Render photographic artwork as original color, scaled to fit. Full-bleed photos and collage compositions have their own cover/layout rules.

The old illustration README says to keep the reader free of imagery; **that restriction is superseded** by the current reader’s contextual art. Use the existing `readerArtwork()` mapping as the baseline. Avoid adding art to every single verse without purpose. Study lens and operational controls remain outline icons.

The welcome’s original flower-photo treatment was later replaced by the existing photographic collage composition. Current authority is the welcome markup plus the latest onboarding CSS and `assets/onboarding-collage.png`, not historical full-meadow screenshots. Keep the centered “Less scrolling. More Scripture.” heading.

Clouds are atmospheric, soft-edged background assets rather than a white sticker outline. Keep them behind legible content. The optional gradient editor belongs outside the app in the browser preview; native developer tooling may expose equivalent controls without changing ordinary app navigation.
