# Snapshot Studio and Widget Studio — mandatory integration

The complete editor source is verse-studios.mjs/css and studio-model.mjs. `STUDIOS-DETAIL.md` retains the detailed editor interaction/production mapping; its old sandbox/server notes are historical and do not apply to this kit's working preview. This current page wins on package paths and scope.

## Separation and entry

Two separate studios, independently saved designs and dirty drafts. Snapshot: selected verse Share / Snapshot Verse; Widget: Settings / Widget Studio and Set as widget verse from passage actions. Preserve selected canonical reference, exact translation and text; no silent fallback to Psalm23 for unresolved production verses. Widget may choose daily or selected source; Snapshot stays the chosen passage.

Shared native components: versioned Codable design, immutable verse payload, renderer, illustration assets, photo processing, type controls and tray. Independent repository keys/files for snapshot and widget. UI theme changes editor chrome only, never mutate saved artwork colors.

## Canonical formats and rendering

Snapshot Portrait600×800 ->1080×1440PNG; Square600×600 ->1080×1080; Story600×1066.6667 ->1080×1920. Widgets Small300×300, Medium600×300, Large600×630 are canonical design spaces, not promises of specific-device WidgetKit point dimensions. Resolve family geometry natively and scale transforms consistently.

Render background, optional cover photo/shade, illustration layers, verse/reference/translation and optional Snapshot signature. Text stays above illustrations. No editor controls, selection boxes, guides or handles in export. Exact Scripture is never cropped/reworded to fit; adapt rendered text size/geometry for long passages. Shared ImageRenderer/artwork implementation must match editor preview and final output.

Background presets: Pure white, Soft sky, Quiet garden, Rose mist, Evening. Exact colors/defaults are exported in contracts/studio-presets.json. Two or three custom hex stops; intensity0–100 mixes toward white; direction0–360. Photo choose/replace/remove, shade0–70, vertical crop0–100, cover centered horizontally. Native PhotosPicker decodes HEIC/orientation; browser currently accepts JPG/PNG/WebP under15MB, processed max1600px longest edge.

Fonts Baskerville, Baskerville Italic, Avenir Next, DM Sans. Ink choices #111111/#FFFFFF/#526D82/#506554/#8C5B6B plus custom. Canonical text size22–52, left/center/right. Preserve selected ink once customized. Up to6 illustration layers from34 editor assets, normalizedx.07–.93,y.06–.94,size.07–.5ofcanonicalwidth, rotation−180…180. New layer23%; saved older sizes are retained. No random illustration substitution.

## Canvas-first UX

Fit whole artwork aspect ratio into large workspace. Persistent header/back/Done and export/save footer.104pt peek tray exposes Background/Text/Illustrations actions; expanded tray min(54%height,540) with safe constraints. Slide down or tap handle collapses it. Opening a tool does not rescale/rebase canvas. Adding/selecting artwork collapses tray and selects that layer. Keep48pt invisible touch area and accessible Adjust/Remove, x/y/size/rotation controls.

Single drag; one-hand48pt resize/rotate handle; simultaneous pinch+rotation+translation; remaining finger continues without jump. Snap within7screenpoints of center and show guides only during movement. Escape/Back/close behave consistently; dirty draft offers Save & close / Discard / Keep editing. Reset only resets draft until saved. Export disables mutation while busy, retains draft on failure/cancel, re-enables prior control states.

## Native widget bridge

Existing target HerCrownWidget, App Group `group.com.hercrown.app`, legacy key `widgetVerse` {ref,label,text,translation,chosen}. Keep compatibility. Add a versioned `widgetDesignV1` payload and stable relative photo filename in App Group. Atomic image write before metadata; last good timeline survives failure. Do not put sandbox-only URLs or PhotosPicker temporary URLs in extension data.

Extend WidgetBridge.refresh and TimelineProvider without replacing GET /me/widget or daily behavior with fixture verses. Copy artwork/fonts into extension/shared bundle; reload relevant timelines only after successful save. Cover missing photo/offline/date rollover/change translation/logout/reset cases. Widget gallery installation is user-driven; Save only stores design and refreshes. Test system full-color/tinted/accented modes; OS may alter colors/backgrounds. Deep link to actual verse.

## Entitlements, persistence and tests

Free snapshot retains Her Crown signature; eligible Plus can remove. Enforce at export time and UI; entitlement loss must not remove watermark illegally from later exports. Snapshot export normal share sheet and PNG fallback; save cancellation is not failure. Widget design save does not purchase/activate membership. Store processed image references per studio; clean only orphaned processed copies, never source photo.

Test independent stores, long verse/all translations, every format/family, photo replace/remove/missing/storage fail, add6/reject7/remove, transforms persist, tray gesture interruption, dirty dialog, relaunch/theme/rotation, native share cancellation, exact PNG dimensions, user widget installation and reload. Browser source is complete functional reference; these new studios are not fully implemented in the supplied native baseline.
