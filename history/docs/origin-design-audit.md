# Origin design audit

Reviewed 31 October 2026. Confidence: **Verified** = live page computed style or visible screenshot; **Documented** = external capture; **Inferred** = adaptation or visual estimate.

## Sources and coverage

- [Origin home](https://useorigin.com/) — live desktop page inspected, including hero, page sections and product visual. Desktop viewport capture: [origin-home-desktop.png](screenshots/origin-home-desktop.png).
- [Origin spending](https://useorigin.com/products/spending) — public feature layout and product imagery reviewed.
- [Origin App Store listing](https://apps.apple.com/us/app/origin-ai-budget-and-track/id1637693312) — public phone screenshots reviewed in earlier investigation; they are marketing captures, not a live authenticated app session.
- [Fudge website capture](https://design.withfudge.com/share/useorigin.com-design), [Fudge app capture](https://design.withfudge.com/share/app.useorigin.com-design), and [UI Discovery](https://uidiscovery.com/sites/origin) — supplemental captured references, potentially older than the live page.
- A separate mobile viewport of the live Origin site was not captured; mobile geometry is inferred from public app screenshots and adapted for this application's content. No authenticated Origin flows, code, or proprietary assets were accessed.

## Evidence

- **Verified:** The homepage uses a blue photographic hero, white editorial serif heading with one italic word, subdued supporting copy, a light primary button, and substantial open space. Further down the page the canvas is black with large editorial headings and product demonstrations.
- **Verified:** At a desktop viewport, the hero heading computed `Lyondisplay App`, 96px / 110.4px, weight 300; the supporting text was Inter, 16px / 24px, weight 300. A secondary heading was 48px / 55.2px. Navigation and CTA used Roboto Mono, 12px; the CTA had an 8px radius. These are desktop page measurements, not phone specifications.
- **Documented:** Fudge reports #000 canvas, #131313 surfaces, #2B2B2C raised surfaces, #2E2E2E borders and controlled blue/teal accents. Its app capture describes denser, small-radius panels. Exact live mobile token parity is unverified.
- **Verified:** Public App Store imagery shows an app with near-black backgrounds, compact charcoal panels, small functional labels, white text and blue data accents. Its marketing screenshots are not proof of every state in the current app.
- **Inferred:** Phone gutters around 20px, component padding 16–24px, compact radii 8–16px, and larger editorial type on feature/onboarding screens. Exact dimensions need reference images at the same device viewport.
- **Verified:** Homepage buttons and product imagery are interactive and the page scrolls. Specific mobile gesture implementations, animation curves, loading states, and native sheet behavior have not been verified.

## Existing application audit

The project is a plain HTML/CSS/JavaScript browser mockup, not an Expo/native application. `state.mjs` stores onboarding, saved passages, preferences and theme in localStorage; `app.js` renders views and handles events. Shared CSS and reusable template functions provide the existing component architecture. The home, Discover, Community, Bible reader, saved, settings, plans, onboarding, and dialog flows already exist. Reminder scheduling and community backend are explicitly not implemented. The application has no chart, authentication, or separate splash flow, so these should not be invented.

## Translation decisions

**Inferred:** retain four peer tabs, content and functional behavior; use a dark-first neutral token family, warm-free light alternative, restrained blue, differentiated editorial and operational type, and component-specific radii. Keep safe area and minimum tap-target rules for web. Use system-available Baskerville (high stroke contrast, narrower and more editorial than the heavier Georgia fallback) followed by Georgia; Origin's Lyon is not licensed or bundled. Native app simulator behavior and exact type metrics remain unverified.
