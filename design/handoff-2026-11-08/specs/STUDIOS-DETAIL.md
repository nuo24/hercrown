# Her Crown — Snapshot Studio and Widget Studio

Working browser prototype and native implementation supplement · 7 November 2026.

## Start here

Serve the full app integration in `dist` over localhost. For a server-free editor-only preview, open `Her-Crown-Studios-Offline.html` in a normal browser. The offline file embeds its fonts and 34 optimized illustrations; it uses a fixed Psalm 23:1 sample and does not connect to app repositories. File-origin storage and sharing support depend on the browser.

Full app preview:

```sh
python3 -m http.server 8900 --bind 127.0.0.1 --directory dist
```

Open `/ios-preview.html?build=story2&studio=snapshot` or `&studio=widget`. The right-hand shortcuts and left-hand screen selector are preview tools, not app UI. Within the app use Bible → Share verse → Snapshot Studio, or Home → Settings → Widget Studio. “Set as widget verse” from Share/Insights also opens Widget Studio with that verse selected.

This folder contains a functional local browser mockup. It does not install a widget, modify the native app, connect to production, or change subscription offers. Do not overwrite the native app with this web distribution.

## Source and integration boundary

Inspected the supplied `her-crown-partner-handoff-2026-11-07.zip`, particularly `VerseShareButton.swift`, `WidgetBridge.swift`, `HerCrownWidget.swift`, and `SettingsView.swift`. Partner package identifies source commit `3ac9c54c21352c5604011c49eeb486cb572d9e10`.

The ZIP's reference web folder predates the approved personal Home and Discover revisions. This prototype therefore starts from the current workspace mockup and adds the studio behavior while preserving the current design. The extracted older reference is kept separately in `partner-reference`, outside the runnable distribution. The native source remains authoritative for authentication, entitlements, repositories, API calls, and production verse selection.

Changed browser files: `app.js`, `index.html`, `native-review.mjs`, `ios-preview.html`, `review-desk.mjs`. New files: `studio-model.mjs`, `verse-studios.mjs`, `verse-studios.css`. All existing Bible bundles, pages, packs, and fonts remain available.

## Product behavior

Snapshot Studio and Widget Studio are independent editors with separate persisted designs. They may share components and a rendering engine, but changing one must not change the other or the app's appearance.

- Background: Pure white, Soft sky, Quiet garden, Rose mist, Evening; two or three custom hex colors; 0–100% intensity; 0–360° direction. Intensity mixes each stop toward white. Background presets choose a readable default ink, then custom ink remains user controlled.
- Photo: choose a local photo, replace/remove it, shade it 0–70%, and adjust vertical crop focus 0–100%. Cover crop is centered horizontally. Browser accepts JPEG/PNG/WebP up to 15 MB, processes a copy to at most 1600 px on its longest edge. Native PhotosPicker should also decode HEIC and handle orientation.
- Text: Ink, White, Slate, Olive, Rose or custom color; Baskerville, Baskerville Italic, Avenir Next, DM Sans; size 22–52 canonical units; left/center/right alignment. Preserve exact Scripture text, reference, and translation. Fit long verses by reducing the rendered size; do not truncate or rewrite Scripture.
- Illustrations: 34 existing PNG illustrations, maximum six per design. Add/remove layers, select, drag, resize, rotate, position. Normalized x/y/size persist across formats. Illustration width is now 7–50% of the canonical canvas width, with a 23% initial size for newly added artwork; previously saved drawings retain their existing size. Artwork stays behind verse text. Selection outlines never appear in exports.
- Snapshot formats: Portrait 1080×1440, Square 1080×1080, Story 1080×1920 PNG. Share via native share sheet; browser falls back to download and exposes a save-again link and exported-image preview.
- Widget sizes: Small, Medium, Large preview; chosen verse or Verse of the day. These are shape previews, not a promise of one device's exact WidgetKit dimensions. Resolve production dimensions using the actual family and available geometry.
- Done saves and returns. Back/Escape asks Save & close / Discard changes / Keep editing if dirty. Reset resets only the current draft; it becomes persistent on save. Widget footer saves without closing so the user can compare sizes.
- Editor chrome follows Light/Dark appearance (white/black). The user's artwork colors remain unchanged when appearance changes. Header/footer stay visible. The large canvas is the primary workspace. A bottom tool tray opens over it and slides down to a 104-point collapsed state; adding/selecting an illustration returns to the large canvas automatically. Artwork coordinates and canvas bounds remain stable as the tray moves.

## Native implementation plan

### Shared state and rendering

Create a versioned Codable `VerseDesign` (see `studio-design.schema.json`) and independent Snapshot/Widget design stores. Keep immutable verse payload `{reference, text, translation}` separate from styling. Use repository-resolved verse content from the tapped Share action; never substitute a different verse if resolution fails. The browser's daily source uses the current mock Home verse; native must use the real app's daily verse service/date behavior.

Build one SwiftUI `VerseArtworkView` renderer accepting payload, design, geometry, and export/preview mode. Reuse it in both studios, ImageRenderer exports, and WidgetKit. Add the same illustration assets to both target memberships or a shared resource bundle. DM Sans must be bundled in the widget target too; verify font PostScript names. Baskerville and Avenir Next should resolve using actual installed iOS font names, not CSS family strings.

Canonical layout coordinates: Snapshot 600×800/600×600/600×1066.6667; Widget 300×300/600×300/600×630. Size is relative to canonical width, not iOS points. Draw background, photo, illustration layers, verse, reference, then optional snapshot signature. Scale consistently to actual output geometry. Use actual font metrics; tune SwiftUI line wrapping against the reference exports and do not synthesize a bold weight.

### Snapshot integration

Replace the static `VerseSnapshotView` editor entry in `apps/ios/HerCrown/Design/VerseShareButton.swift` with Snapshot Studio, preserving normal text sharing. Pass the actual selected verse and current translation into the editor. Native export uses SwiftUI ImageRenderer at explicit target dimensions and `UIActivityViewController`/ShareLink for sharing the resulting PNG. Keep export controls disabled while rendering, handle cancellation silently, and retain the draft on failure.

Preserve the existing entitlement behavior: free snapshots always show the Her Crown signature; eligible Plus entitlements can remove it. Enforce this in the export renderer as well as in the switch UI. Do not invent a new paywall or billing rule. The browser prototype uses its existing mock entitlement states only.

### Widget integration

Add a Settings row in `Features/Settings/SettingsView.swift`; open Widget Studio without sending the user to onboarding. Continue using `Core/WidgetBridge.swift` for the selected/daily verse and timeline refresh. Do not replace its real `/me/widget` source with browser fixtures.

Existing App Group: `group.com.hercrown.app`. Existing verse key: `widgetVerse`. Preserve its fields and decoding compatibility. Store the new versioned design under a separate `widgetDesignV1` key (or migrate with backward-compatible decoding). Copy a processed photo to the shared App Group container using a stable relative file name. A PhotosPicker URL, browser blob URL, or app-private sandbox path will not be readable from the widget extension. Write the new asset atomically before updating metadata; keep the last good state on errors.

In `apps/ios/HerCrownWidget/HerCrownWidget.swift`, read shared design and payload in the timeline provider and render using the shared artwork component. Retain Small/Medium/Large support, midnight/daily refresh, app-triggered timeline reloads, and the existing quiet widget variant. Avoid large image decoding and network work in the widget body. Refresh with WidgetCenter only after successful save.

Use `containerBackground(for: .widget)` and test full-color, accented/tinted rendering, increased contrast, and system background removal. Exact custom colors are not guaranteed in system-tinted modes. Show the actual widget family preview and real-device result before promising pixel identity. A widget tap should retain the existing deep-link behavior. Explain how to add a widget; a save action cannot silently install one on the Home Screen.

### Photos and storage

Use PhotosPicker/system selection, not blanket Photos-library permission. Process on a background task with a bounded image size; decode orientation; no network upload is needed. Store separate photo IDs per saved design. Clean unreferenced processed images and revoke transient resources on dismissal. Storage failures must keep the draft available and show a recoverable error. Do not delete the original photo. Decide explicitly whether these designs are device-local or cloud-backed; this prototype is local-only.

### Navigation, accessibility and motion

Studio presentation is a dedicated full-screen editor with a back action, not a system permission prompt. Keep safe-area-aware controls while artwork backgrounds fill their preview. Keep the app's quiet visual language: Baskerville heading 26, DM Sans controls, monochrome primary action, restrained dividers, soft preview shadow. Use real native pickers for font/source/size controls where appropriate, not imitation dropdowns.

Support VoiceOver labels, meaningful selected states, Dynamic Type, reduced motion, and accessible alternatives to drag (position/size controls). On larger displays keep the canvas centered and cap the tray width at 740 points. A separate inspector column can be considered later; the current reference uses the same canvas-and-tray interaction at every width. Keyboard users can move a selected illustration with arrows, Shift+arrows for a larger step, Delete to remove. Confirm unsaved changes without losing keyboard focus. Haptics may be light selection feedback on discrete choices; do not buzz continuously while dragging a color slider.

## Verification and remaining native checks

Browser checks completed: Snapshot entry from Share, Settings Widget entry, independent saved designs, photo upload + reopen, custom gradient stop/intensity/third color, typeface and ink changes, add/remove illustration + position control, unsaved-change sheet, PNG rendering at 1080×1440, 1080×1080, and 1080×1920, Small/Medium/Large widget previews, daily/chosen source, Light/Dark chrome, and clean browser error logs at the tested states. Exported-image proof is in `proof`.

The in-app browser did not report its blob download event to automation, so export was verified using the actual generated image displayed by the editor and its PNG dimensions, not by asserting a Downloads-folder write. Save-again link remains available. Real iPhone share-sheet behavior, PhotosPicker HEIC/Live Photo handling, WidgetKit installation/tinted modes, memory limits, Dynamic Type, and SwiftUI font metrics still require native implementation and simulator/device verification.

Before release: test a very long verse, all translations, each family on multiple devices, rotation/iPad, photo replacement and missing file recovery, relaunch, membership changes, offline daily refresh fallback, and deleting a draft without touching the other studio. Do not change unrelated app functionality while integrating these features. Additional necessary native states may be added if they preserve the editor's behavior and design.

Primary Apple references: [WidgetKit strategy](https://developer.apple.com/documentation/widgetkit/developing-a-widgetkit-strategy), [TimelineProvider](https://developer.apple.com/documentation/widgetkit/timelineprovider), [Widget background](https://developer.apple.com/documentation/widgetkit/displaying-the-right-widget-background), [ImageRenderer](https://developer.apple.com/documentation/swiftui/imagerenderer).


## Canvas-first UX revision · 7 November 2026

This section supersedes the original small-preview/always-visible-inspector layout. The previous implementation is preserved in `backups/before-story-editor`, and the earlier ZIP remains a rollback artifact.

### Research and design rationale

[Meta’s official Stories sticker guide](https://about.fb.com/news/2024/05/new-stickers-in-instagram-stories/) describes a top-level sticker action, selection from a tray, and applying the selected object to the story. [Apple’s sheets guidance](https://developer.apple.com/design/human-interface-guidelines/sheets) describes sheets that rest at detents. Our design inference is to separate browsing/adjustment from direct arrangement, give the composition most of the screen, and keep tools temporarily out of the way. This is an adaptation, not a claim to replicate every current Instagram interaction.

### Current interaction contract

- On entry, the tray is collapsed. Fit the complete selected aspect ratio in the remaining canvas area; do not crop a Story poster merely to make it wider. Portrait, square and story share the same canonical export dimensions as before.
- Keep a 104-point peek containing a drag affordance and three 44-point-or-larger tool actions: Background, Text, Illustrations. Opening a tool expands the tray. Slide the handle down or tap it to collapse; slide up or tap a tool to reopen. Buttons provide an accessible alternative to the gesture.
- Expanded height is `min(54% of viewport height, 540)` with a safe maximum that leaves the header and footer available. The tray sits above the persistent Share/Save footer. The underlying artwork stays at the same size and coordinates during tray movement; do not scale it under an active drawing gesture.
- Adding a new illustration or choosing an existing layer closes the tray and selects that layer on the large canvas. A small selection bar offers Adjust and Remove. Adjust opens the precision inspector; selecting the Illustrations tool starts with the library rather than burying it beneath an old selection’s controls.
- Each drawing has an invisible touch area of at least 48×48 CSS points (including when the visible artwork is smaller). Rotated bounds are included. Native implementation must use real points and also support VoiceOver. These hit areas and handles are editor overlays, never part of the saved image.
- One finger drags the selected illustration. A 48-point corner handle changes its size and rotation with one hand. Two fingers may scale, rotate, and translate the selection simultaneously; after one finger lifts, continue the remaining drag without a position jump. A tap on blank canvas clears the selection. Keep selection until pointer release so two fingers can begin around a small selected object.
- Show center alignment guides within seven screen points of the center, then snap to the exact center. Hide guides on release. Keep precise size, rotation and x/y sliders as an alternative to freehand placement. Rotation values shown in the inspector are rounded to whole degrees while the saved transform may retain precision.
- Escape first collapses an open tray, then follows the unsaved-change close behavior. Explicit Back still exits the studio with the existing save/discard prompt. Collapsed controls are inert and cannot take keyboard focus.
- Full-screen local review links (`index.html?build=story2&studio=snapshot` / `studio=widget`) avoid scaling touch controls inside a simulated phone bezel. They are debugging entry points, not replacements for the app’s Share/Settings navigation.

### Native implementation details

Prefer an in-screen bottom tray in the full-screen editor’s ZStack so the persistent export footer remains independently visible. Use native pan/pinch/rotation recognizers with simultaneous recognition, starting from the live transform and committing state at gesture end. Snap the tray using projected drag momentum, retain grab continuity if interrupted, and use the app’s spring vocabulary. The browser uses a 260 ms ease-out settle as a prototype; that is not a measured native spring specification.

Do not present another full-screen route when opening a tool. The tray is transient editor state. Keep normalized transforms independent of canvas pixel size, and never bake editor chrome or selection into ImageRenderer output. Support Reduce Motion, native safe areas, and larger text. A light haptic can accompany a completed detent change or center snap, not every pointer movement; browser haptics are not simulated.

### Verification limits

Before the preview session restarted, browser input verified: pulling the tray upward, collapsing it by tap, adding artwork with automatic collapse, direct dragging changing the stored transform, the single-hand handle changing size/rotation, precision inspector entry, and a valid 1080×1920 PNG after the layout change. The normalizer accepts the expanded 7–50% illustration size range. Earlier photo, palette, format export, and separate persistence checks still apply to the shared engine.

After the session restarted, the current shell sandbox refused binding the preview server (`Operation not permitted`), and the in-app browser URL policy rejected local `file:` navigation. No alternate browser or execution path was used to bypass those restrictions. The self-contained offline HTML and runnable localhost distribution are supplied for user-side review. Current two-finger interaction, native spring timing, real-device haptics, VoiceOver and performance must still be tested on iPhone; do not describe them as device-verified.

### Rollback

The earlier ZIP `her-crown-verse-studios-handoff-2026-11-07.zip` preserves the complete pre-redesign build. To restore just the old editor inside this folder, copy `verse-studios.mjs`, `verse-studios.css`, and `studio-model.mjs` from `backups/before-story-editor` to `dist`, and remove the direct-studio review entry added at the end of `app.js`. Revert the schema size maximum to 0.32 when targeting that older renderer. Do not delete user media or local design preferences as part of a design rollback.
