# White collage onboarding

The welcome arrangement uses the supplied Stella screenshot as layout inspiration: scattered photographic cutouts around a centered headline, with bottom-anchored actions. Original Bible Scroll headings, supporting copy, routes and app structure are retained.

The onboarding surfaces are white with black primary actions, neutral secondary text and shallow shadows on selectable controls. Main app styling is unchanged. The welcome collage is an original generated transparent raster featuring flowers, an open book, a mug, olive leaves, a journal and sky.

Implementation: `dist/onboarding-white.css`, linked last in `dist/index.html`; preview chrome synchronization in `dist/ios-preview.html`; `dist/assets/onboarding-collage.png`.

Verified in the browser: welcome layout, Get started transition, white preference screen, and restart. Screenshot: `docs/screenshots/ios-white-collage-welcome.png`. This revision updates the browser mockup; it has not been ported to or validated in the SwiftUI app.

Rollback checkpoint: `outputs/checkpoints/bible-scroll-before-white-collage` contains the three preceding runtime files. Restore those and remove the unused new stylesheet/asset if reverting this revision.

## Gradient and safe-area refinement

All seven onboarding steps now share a white-based sage-to-sky gradient. In the iOS browser preview, onboarding fills the display behind transparent status and home overlays, with explicit safe-area content padding. The welcome collage extends behind the Dynamic Island rather than starting below the status bar. Verified welcome and preference-step rendering and restart. Screenshot: `docs/screenshots/ios-gradient-welcome.png`.
