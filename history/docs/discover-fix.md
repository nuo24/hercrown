# Discover correction

Implemented 31 October 2026.

The updated screen uses a #050505 dark canvas, matte #131313 cards without outlines, compact reference/category metadata, dominant Scripture, secondary translation metadata, a separator and inline reflection, a compact primary action, and monochrome saved hearts. Filters retain horizontal scrolling. Navigation is a quiet full-width bottom bar with accessible labelled destinations. Light mode remains selectable.

Files: `dist/app.js` (card order, Discover scope, filter pressed state, optional preview route), `dist/discover.css` (screen styling and documented dark palette), `dist/index.html` (stylesheet), `dist/preview-mobile.html` (390 × 844 iframe viewport for validation).

Evidence: [390 × 844 screenshot](screenshots/discover-390x844.png). This is a real 390 × 844 embedded browser viewport, cropped to its exact bounds, not a native simulator capture. Compared visually with the previous Discover capture and public Origin reference material; exact font parity is not claimed. System Baskerville remains the evaluated fallback because Lyon is not licensed/bundled.

Verification: topic filter reduced the list correctly; saved state was toggled off and on, restoring the original bookmark; reflection dialog opened and closed; navigation to the Bible reader succeeded. Sharing was invoked but no success/cancellation result was exposed by the browser, so completed sharing is not verified. Existing state tests and JavaScript syntax checks pass.
