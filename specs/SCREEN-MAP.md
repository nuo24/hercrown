# Screen and interaction contracts

The exact current copy/options/plan fixtures are in `content-fixtures.json`, with the source runtime as the final reference. Screen IDs below are handoff identifiers, not a requirement for any specific router library.

## Onboarding

- `onboarding.welcome` (step 0): photographic collage, centered regular/italic “Less scrolling. More Scripture.”, supporting copy, Get started, guest exit. No unwanted side-aligned brand lockup. All-device safe-area background coverage.
- `onboarding.time` (1): open book, hourglass, cosmos and ceramic heart; “If you scroll for 2 hours a day, that’s 14 hours a week.” This is conditional arithmetic, not a claim about all women. Supporting invitation for women; cloud atmosphere, Back, Continue.
- `onboarding.intention` (2): “What brings you here?” Four single-choice intentions. Ceramic heart artwork. Back, Skip, Continue.
- `onboarding.familiarity` (3): “Every journey begins somewhere.” Three familiarity choices. Seedling. Back/Skip/Continue.
- `onboarding.topics` (4): “What’s on your heart lately?” Nine multiselect topic chips. Olive. Choice affects discovery ordering, never canonical Scripture.
- `onboarding.rhythm` (5): “Make room for the Word.” 2/5/10 minutes or no time goal; hourglass. All choices optional; no punishment for a short session.
- `onboarding.reminder` (6): optional reminder switch and time picker when enabled. Bell artwork and notification preview. Back/Skip/Not now. Native permission requested contextually only after the user opts in; handle denial gracefully.
- `onboarding.ready` (7): butterfly, “You’re right where you need to begin.” Psalm 23:1. Start reading marks onboarding complete, selects Bible and opens optional membership. Guest exit enters Bible without a forced purchase.

State: persist completion and selections. Back retains choices; skipping a question clears that question in the current demo. Completion uses flowVersion 2. Preserve existing saved data during migrations. Normal Settings must never set completed=false or route to these screens.

## Main shell

Four tabs in order: **The Bible, Community, Discover, Home**. Bible is the initial tab after launch/onboarding. Maintain tab-specific navigation state where natural. Dock floats above the bottom safe area; content and rail reserve its height. Settings and plan detail flows are secondary destinations; the current demo does not show the main dock on Settings/plans.

## Bible

`bible.reader`: toolbar includes random verse, saved passages, native translation selection, bookmark-current and native chapter selection. Fixtures: Genesis 1 (31 verses), Psalm 23 (6). Vertical reader supports going forward/back, including long verses. Persistent left rail reflects the actual chapter count, active segment/number and total. Rail hit target stays practical even when segments are tiny; add an accessible alternative for long chapters. Scrubbing must not trigger tab navigation or lose the active verse.

Each verse has contextual illustration where mapped, large serif Scripture, reference, and trailing actions: **insights lens → heart → reflect → share**. Lens has no surrounding shape. Share uses native sheet, save persists and synchronizes across surfaces. End-of-chapter offers real chapter continuation in the full product rather than an artificial sample dead end.

`bible.insights`: native sheet with open-book illustration, exact verse and reference, Explain easier, Deeper study, Related verses. `insights.easier`: sample reading aid explicitly separate from translation; missing note has an honest fallback. `insights.deeper`: nearby verses and reflection. `insights.related`: selectable references. Original language and version comparison are explicitly unavailable in the prototype. Implement if appropriate with real sources; do not expose fake functionality. The lens does not imply that the current mockup has a live AI backend.

`bible.reflection`: Scripture plus reflection prompt, disclaimer separating reflection from canonical text, completion action. Marking a reading day updates the streak once per local calendar date.

## Community

`community`: intentional illustrated unavailable/empty state in this prototype, not fabricated social activity. Match it for initial parity. The full-stack agent may build a real community when product scope is established, including its necessary compose, privacy, moderation, report/block and empty/error states. Document the expansion and preserve the main tab identity.

## Discover

`discover.feed`: header, settings/saved access, topical filters, illustrated introduction with restrained glass/depth, Scripture cards and clearly separated reflections. Filter titles: For you, optional selected Plan, then nine themes. Mapping: lantern=For you, journal=Plan, olive=Peace, compass=Purpose, faith-hands=Faith, relationship-hands=Relationships, ceramic heart=Identity, rest-stones=Anxiety, gratitude-basket=Gratitude, sunrise=Hope, wisdom-pearl=Wisdom. Avoid repeating the same artwork indiscriminately.

Cards support save, reflect, share and read/reflect. Topic preference prioritizes relevant cards. Do not mutate scripture text to personalize it. Handle empty and loading results.

## Home, saved and plans

`home`: “Hi, {name}!” with small cosmos; right-hand fire/streak count replaces the former appearance shortcut; Settings contains appearance. Streak card, verse of the day, native passage search, Today’s Reading, Faith/Purpose topic cards and regular/italic reflection feature. Dynamic profile names must not break the header.

`saved`: one collection shared between reader and discovery; illustrated empty state, no duplicate IDs for the same passage.

`plans.list`: recommended and topic/season groups. Quiet beginning (5), Peace for anxious hearts (3), Rooted in strength (3). `plans.detail`: title, description, exact passage list, start/continue. Full build needs actual plan progress and resume behavior; current demo persists only plan choice.

`streak.detail`: local-date reading history, current/best counts, weekly status and conditional milestone artwork at 7/30/100/365 days. Deduplicate days, ignore invalid/future dates. A run remains current when the last read day is yesterday; missing a complete day breaks it. See `streak.mjs` tests for time-boundary semantics.

## Settings

`settings.root`: profile image/name, demo badge in fixture mode, illustrated membership feature, grouped Account & reading, Here for you, About & legal. Continuous app gradient through safe areas. Sticky header, no extra page-colored slab. Back returns to previous app destination.

- `settings.account`: native photo selection, preview, replace/remove, name, email, bio and Save. Photo remains draft until saved; leaving discards draft. Prototype center-crops to 320px JPEG, accepts JPG/PNG/WebP up to 10 MB; native flow may improve format handling and cropping. Local fixture mode stores on device. Production upload needs progress, cancellation, validation and error recovery.
- `settings.topics`: nine multiselect controls, Save updates state and returns to Settings. No onboarding route.
- `settings.appearance`: native light/dark selection; gradient model shared. System mode may be added when implemented clearly and tested.
- `settings.subscription`: current free plan, benefits, Explore Plus, Restore. Do not claim a paid plan without verified entitlement.
- `settings.contact` / `settings.support`: illustrated introduction, WhatsApp-style mock badge/details, native topic selector, message editor, Preview message. Support also has FAQs. Production message delivery is a separate service task, not a fake success toast. Mock 202-555 numbers are placeholders, never live recipients.
- `settings.about`, `privacy`, `terms`, `licenses`: full in-app reading pages with back navigation. Replace placeholder legal content and mock release details before launch. Do not return to onboarding.
- Reading pace and reminder preferences on root remain functional. Add time editing if reminders are implemented.

## Membership

`membership.paywall`: full-screen safe-area background, shared live gradient, book/cosmos/cloud artwork, serif regular/italic heading, three illustrated benefits, selectable annual and weekly plans, neutral CTA, free-reading exit, visible USD cadence/renewal/no-trial copy, close, restore and legal/privacy access.

Annual $29.99; weekly $2.99; annual initially selected. Annual approximately $2.50/month is supporting math, not the billing cadence. No automatic trial. Current CTA opens an explicit demo confirmation with no payment. Actual iOS purchase must use localized StoreKit product data and real transaction states; do not keep demo confirmation as purchase success.

## Expected additions

This inventory is the minimum fidelity baseline. Add the missing infrastructure and necessary flows for real authentication, sync, purchases, complete content, AI if selected, support, accessibility and recovery. New screens should inherit the system and not rearrange the approved ones without a clear functional reason.
