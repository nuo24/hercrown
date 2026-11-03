# Visual evidence guide

All captures are browser mockup images, not iOS Simulator screenshots. Outer device frame/status bar are review tools and must not be drawn in the native app.

## Fresh final-build captures

`current/final-reader-light.png`, `final-reader-dark.png`, `final-home-light.png`, `final-discover-light.png`, `final-community-light.png`, `final-paywall-light.png`, `final-paywall-dark.png` were captured during handoff creation from `build=pickers21`. The review used the local 29%-intensity/59%-reach gradient snapshot. These are single visible viewport captures, not the entirety of long pages.

## Recent feature evidence

- `native-chapter-picker.png`: current native-select reader layout; OS-owned expanded menus may not appear in browser image capture.
- `neutral-dock.png`: neutral dock, no built-in cyan/gold gradient; predates final select changes.
- `settings-continuous-background.png`: current Settings background/safe areas, scrolled to support/legal. Predates native-picker typography normalization only.
- `settings-account-editor.png`: functional photo/profile editor. Predates final Settings background correction; follow current Settings CSS for canvas, not the older lavender appearance in this capture.
- `onboarding-clouds.png`: current intro copy/art and cloud treatment. Other onboarding states must be reviewed in the runnable reference.
- `membership-paywall.png`: recent neutral-button paywall. Prefer fresh `final-paywall-*` captures for parity.

All older screenshots and design notes are under `history/docs/`. They include discarded cream backgrounds, prior docks, old tab orders, temporary social styling, hidden/right-hand verse rails and other obsolete states. They are not an instruction to combine all past iterations. Current specification and working code take precedence.
