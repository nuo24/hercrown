# Origin fidelity review

Reviewed 31 October 2026. This is a design-system translation to Bible Scroll, not a pixel comparison of equivalent content.

## Visual references

- [Origin desktop homepage](screenshots/origin-home-desktop.png) — live public site, desktop viewport. The current website presents a blue photographic hero and transitions into dark editorial sections.
- Bible Scroll [home, dark](screenshots/bible-scroll-home-dark.png), [home, light](screenshots/bible-scroll-home-light.png), [Discover, dark](screenshots/bible-scroll-discover-dark.png), [reader, dark](screenshots/bible-scroll-reader-dark.png), and [reflection sheet, dark](screenshots/bible-scroll-sheet-dark.png). These show the app in its desktop phone-frame preview, not an iOS simulator.

## Confirmed relationships and implementation

- Black canvas, restrained matte charcoal surfaces and fine border separation in dark mode. Fudge's documented baseline informs the shared token values; exact parity with current Origin mobile tokens is unverified.
- Display serif, sans-serif controls/body, and occasional monospace metadata are defined centrally. Compact light primary buttons and quiet borders follow verified website relationships.
- Existing mobile information architecture is retained. Home, Discover, saved, Community, reader, plans, settings, onboarding and dialogs use shared token-driven surfaces, spacing, type and controls. Screen-specific layout remains in the existing CSS and JS templates.
- Light mode remains available and a preexisting stored user theme is retained. Responsive CSS keeps full-width phone layouts, a framed desktop preview, scrollable filters, safe-area spacing and reduced-motion rules.

## Remaining differences and confidence

- **Inferred:** Actual mobile radii, layout dimensions, animation and typography sizes. The site desktop and Bible Scroll phone screenshots cannot be compared pixel-for-pixel.
- **Font difference:** the commercial Lyon font is not bundled or known to be licensed. Baskerville, followed by Georgia, is a system fallback chosen for its high-contrast strokes and editorial proportions. It cannot match Lyon's exact forms, widths, italics, or wrapping and may fall back differently by platform. Inter and Roboto Mono also fall back to local system fonts if not installed.
- The existing meadow image is product-owned, recolored rather than replaced with Origin's proprietary imagery. No Origin trademarks or artwork were copied. No verified feature-specific photo or mobile behavior is claimed.
- The app is a browser mockup, not a native app: actual native navigation, Dynamic Type, safe-area behavior on hardware, dark-mode keyboard, and mobile sheet gestures require a real-device or simulator pass. The available browser preview did not support capturing the reference at a phone viewport in this review.
- Layered legacy styles remain, with new semantic tokens and shared component rules overriding them. Further consolidation into a single stylesheet would make future changes easier, but was not needed to preserve the existing flows.

## Accessibility and validation

- Both themes were visually inspected in the browser; semantic labels are present on icon controls, focus-visible treatment uses the accent, and reduced-motion rules are retained.
- Topic filtering and opening/closing a reflection dialog were exercised; navigation to the Bible reader was checked. No exhaustive accessibility or contrast audit, touch-target audit, long-content scaling test, screen recording, or physical-device test was performed.
- `node --check dist/app.js` passed. `node test.mjs` passed seven-step navigation, choices, skip, reminders, completion, guest, persistence and recovery.
- Existing features include the sample Scripture library, saving, sharing, filters, reader, reading plans, settings and onboarding. Community features and scheduled reminders remain placeholders as documented in the application.
