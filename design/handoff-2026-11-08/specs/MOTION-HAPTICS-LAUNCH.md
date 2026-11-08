# Motion, haptics and cold launch

## Active onboarding scheduler

Use `personal-onboarding-motion.mjs`, not older onboarding-motion.mjs or the November 6 timing note. All timers belong to a page/flow identity and cancel on departure. Typing holds the final layout space and reveals characters inside word containers; final static markup replaces transient spans after completion so no italic word disappears.

- Start heading at220ms. Reveal **48ms per non-whitespace character** (Unicode code points in reference). Keep spaces/layout visible; do not resize/reflow text per keystroke.
- Selection haptic request every **fourth** typed non-whitespace character, including index0: 192ms cadence for heading/lead; prayer uses38ms/character, hence152ms cadence. Source calls optional WebKit bridge `herCrownHaptics`; Safari itself does not buzz. Native use selection feedback and verify on physical hardware. Respect accessibility/system preferences; no audio click.
- Acknowledgement lead: type, hold650ms, fade/translate up12 over240ms; next body begins260ms after exit begins and fades/rises10 over280ms. Body/choices remain hidden and inert until appropriate stage. Do not stack two headlines in the same coordinates.
- Question subcopy/choices/input controls reveal at heading end+80ms with220ms fade. CTA gates unlock at completion (ordinary question end+100ms); action must not be invisibly tappable. Prayer action waits for full prayer type at38ms/char after heading end+400ms, plus180ms.
- Time page: heading end+1200ms starts heading/art exit700ms and bridge reposition850ms. Bridge typing begins1000ms after that start. Flower enters60ms after bridge text ends, with320ms settle; Continue unlocks after flower settles. Preserve all phases when the screen's copy is changed.
- First-page collage groups: seven pre-existing cutout groups, reference CSS delays0,120,240,360,480,600,720ms (composition order intentionally differs from DOM order in some pieces),560ms settle. Second-page four icons have inline stagger0,140,280,420ms and640ms settle. Use actual illustration pixels, not new symbols.
- Reduce Motion: bypass typing/entrances, remove lead and present final actionable question immediately. Backgrounding cancels timers and settles current content; no delayed callback may mutate another page. Name/choice/switch updates on the same page must not restart the whole sequence.

The browser final source is authoritative for exact easing/positions. Haptic feel cannot be guaranteed by CSS timings; calibrate hardware and record deviations. Do not claim simulator vibration verifies physical haptics. Supplemental native coordinator has been updated to48ms/four-letter cadence and accepts explicit start/cadence for prayer and acknowledgement phases; it is guidance to integrate, not a new parallel owner.

## App motion and transitions

Use platform push/back/sheet/keyboard behavior; do not animate tab screens sliding across one another. Nav opacity feedback is restrained. Reader scroll physics follow gesture/index and the persistent rail adapts segment density to chapter length. Bottom menu translucency must sample visible content; do not fake it with a colored gradient.

Studio tray prototype settles over260ms ease-out; native use a cancellable gesture-following spring with projected momentum. Preserve canvas coordinates while tray moves. Tap/drag/pinch/rotate interrupt smoothly, center snap and detent changes may get light selection haptics; never buzz continuously along sliders or drag movement. Reduce Motion eliminates ornamental spatial transitions.

## Returning-reader process launch

Current executable study: `motion/cold-launch/`. Partner native already has ColdLaunchView.swift + CrownMesh.metal.txt; verify its root lifecycle in HerCrownApp/RootView and adapt, not duplicate.

Ordinary fresh process, already onboarded: white/black app-rendered overlay, actual crown grows from lower ends then original flowers bloom. No name/subtitle. Static OS launch screen matches canvas; animation belongs after launch. Crown248pt square (224 compact), centered12pt above vertical center.

80–1360ms branch growth;1430–1740 first floral region;1510–1820 second;1820–2050 completed logo hold;2050–2400 dissolve to real restored content. Final frame preserves approved logo. Startup work runs concurrently;2.4s hard end independent of auth/network. No sound or launch haptics.

Skip for initial onboarding, warm resumes, tab/page/sheet navigation, initial deep link/notification, Reduce Motion. Incoming route or background interruption cancels immediately and restores real destination. Missing renderer/art falls through to content. Avoid duplicate playback from view reconstruction or a “played once ever” preference. One process-scoped coordinator owns launch.

Flattened original PNG and provisional matte/hidden wood reconstruction can stretch intermediate grain/thorns or fringe on black. Native mesh code is included, but production should compare it and clean up/author true layers where needed without regenerating a different logo. Older bare-vector crown is not the approved asset. Native-only rendering/performance/haptics remain builder verification work.
