# Screen and navigation contract

`design/routes.json` is generated from the current reviewRoutes export. All routes and supporting overlays must survive the port; the following describes actual behavior beyond a list of screenshots.

## App shell and reader

Four tabs in order: The Bible, Community, Discover, Home. Initial ordinary destination is Bible; preserve last verse/chapter/translation position according to existing restoration behavior. Status and home areas are real OS chrome. Artwork backgrounds extend behind them; controls do not.

Bible: complete chapter feed, persistent left verse segments adapting to short/long chapters, current verse indication, tap/scrub/scroll synchronization, previous/next chapters, shuffle and saved/liked mode, translation picker and bookmark control. Do not hide the rail after scrolling. Test Psalm 23 (6), Genesis 1 (31), Psalm 119 (176) and a long verse at large text. Magnifier/lens insights action above Like has no decorative border. Like/save, reflection/comment, share and Snapshot/Widget entries retain current verse identity.

Chapter picker: searchable books and chapter grid; changing translation retains valid reference; recover from unavailable online translation without silently changing Scripture. Insights sheet exposes Explain easier, Original language, Deeper study, Related verses, Compare Versions, widget, snapshot/share and auto-scroll where available in the actual native baseline. Current review renderer and baseline together specify those flows. Preserve citations, separate commentary, saving and errors. Notes are attached to canonical reference and retained with translation metadata.

## Home and library

Home toolbar Search and Settings; avatar/name open account editor. Streak opens reading rhythm. Tabs Library / Bookmarks / Notes. Library: Verse of the Day, daily devotional, reading plans, reflection and contextual readings. Verse share/read/save are real actions. Devotional and plan details have back/close, progress and entitlement states.

Bookmarks show saved reading places with consistent rows and removal/open actions. Notes show the actual verse notes entered from Bible; open/edit/delete maintain the same record. Empty states offer an appropriate return to reading. Supporting saved verses/studies/studied library routes remain reachable from relevant flows; do not conflate them with place bookmarks.

Streak: original serif count and weekly circles, now Week and 6 months only. Six-month history is a responsive GitHub-style square grid, no sideways scroll. No one-year option. Main summary and CTA fit current phone sheet; additional stats under More progress. Read days are unique local calendar dates; duplicate opens do not inflate a streak. History shows actual recorded days, never simulated attendance. Time zone/DST decisions must be explicit and match existing repository semantics. Longer accessibility text may scroll vertically.

## Discover

Serif header, search and quiet overflow actions, sticky categories including For you/Saved/topics, featured passage with Begin reading, contextual artwork list, per-passage actions, saved state, searches and content/loading/error states. Every row opens its correct passage/reflection. Source mapping in discover-model.mjs is intentional: reuse thematic artwork at scale but avoid unrelated or repetitive giant decoration.

## Community

Current approved design is the photo gallery, matching Discover language, not “coming soon” or the older three concepts. Settings gear and Saved remain top right. Monthly intro, one mixed grid of four causes, vote/change-vote confirmations, cause details and separate local-cause suggestion flows. See COMMUNITY.md. No charity/church segmentation tabs. The screenshot supplied by the user is included as a visual reference if available.

## Settings and account

Account/profile: name and profile image selection, display/edit states, guest/sign-in, sign-out/delete confirmation, upload and validation failures. Keep mocked preview identity separate from actual account. Membership: subscription status, trial/grace/expired, manage subscription, restore, purchase pending/cancel/error and safe free exit. Appearance System/Light/Dark persists; System reacts to OS changes. Icon picker exposes four actual icons with one selected ring/tick.

On your heart/preferences, Bible translation, reading size, words of Jesus in red, reminder on/off and always-available time control where applicable. Widget Studio is a dedicated Settings destination. Contact/support/FAQs, privacy/terms/refund/license pages have their own content and navigation; none reset onboarding. Native support contact and legal endpoints require owner configuration.

## Studios, onboarding and presentation

Studios are distinct full-screen editors; opening a tool opens an in-screen tray, not another full-screen page. Back handles dirty drafts and returns to the initiating verse/Settings. Onboarding is 14 steps with optional answers; see ONBOARDING.md. Paywall is full-screen with scrolling content and an independently accessible footer; its background fills the screen. Free-reading exit always works.

Use push for browsable subpages, sheets for contextual verse actions/streaks, full-screen editor/paywall where the reference calls for it. Preserve back/close routes and interactive dismissal. After completed onboarding or verified purchase, Back cannot resurrect the obsolete flow. Do not let a global re-render reset keyboard, scroll, draft or animation state.
