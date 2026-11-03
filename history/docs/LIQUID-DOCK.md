# Reference-style liquid glass dock

The bottom navigation now uses a translucent floating capsule with a soft backdrop blur, edge highlights, restrained teal/warm rim reflections, and a separate rounded selection lens. Active icons have stronger strokes and labels have stronger weight. Tabs retain their existing order and functionality; The Bible remains first and default.

Implementation: liquid-dock.css, linked last, with a dock-index variable supplied by navigation() in app.js. Light and dark themes are included, plus reduced-transparency/high-contrast solid fallbacks and reduced-motion support. Reader viewport and feed clearance account for the taller dock.

Verified in browser: Bible and Home selection positions, tab navigation, reader clearance, light and dark rendering. This is a browser approximation; native iOS refraction is not implemented. Screenshot: docs/screenshots/liquid-glass-dock-dark.png.

Rollback checkpoint: outputs/checkpoints/bible-scroll-before-reference-dock contains app.js and index.html before this pass.
