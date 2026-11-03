# Bible Scroll illustration pack · v5

Twenty-five original generated assets: 24 photographic cutouts and one transparent cloud bank. Transparent PNG originals are kept at full resolution. Open `index.html` for a visual contact sheet; `manifest.json` includes stable asset names and generation prompts.

## Contextual expansion · v2

The pack now distinguishes feature meanings rather than repeating botanical art:

- cosmos: the personal Home greeting only.
- magnifier: Verse Search heading.
- journal: Today’s Reading card only.
- reflection: the single reflection card on Home; no candle repeated on every feed card.
- community: Community welcome screen, with paired tea cups representing connection.
- bookmark: saved collection banner or its empty state.
- sunrise: A quiet beginning plan.
- dove: Peace for anxious hearts plan.
- anchor: Rooted in strength plan.
- open-book: passage study sheet introduction.
- milestone: wreath shown only at 7, 30, 100 and 365-day streak milestones.
- olive: reserve asset for a future peace-themed editorial surface; not repeated as a generic decoration.

Feature illustrations do not replace action icons. Tabs and reader controls retain their consistent outlined symbols. Each feature gets one focal subject. Use semantic mapping above when expanding the app; don't scatter the same asset across unrelated screens.

## Instructions for coding agents

Use this pack for editorial illustrations, not interactive action icons. Keep the existing outlined icon system for tabs, hearts, sharing, study and settings. Use one illustration per section; leave the Scripture reader free of decorative imagery. Do not add invented text or theological symbols to the assets.

Render with `object-fit: contain` on the web; `resizeMode: 'contain'` in React Native; `.resizable().scaledToFit()` in SwiftUI. Preserve transparency, white contour and baked soft shadow. Do not crop, recolor, apply template rendering/tint, stretch or add another white box/outline. Use original assets on light and dark surfaces. Reserve dimensions to avoid layout shift. Treat decorative instances as `alt=""`, accessibilityElementsHidden or equivalent.

Sizes: greeting accent 24–36 CSS px; compact reading card 72–96 px; plan cover 120–150 px; empty state 140–170 px. Existing padding inside originals is intentional. Add no floating animation to controls or reading content. Keep body text on clear surfaces and never place text over the image.

## Extending the pack

Use the complete prompts in manifest.json. Match photorealistic natural materials, muted cream/sage/sky, upper-left soft lighting, a narrow white cutout contour and a soft offset shadow. Generate a separate transparent square image per object. Keep raw source originals and inspect the alpha on both light and dark backgrounds. Do not replace these assets with emoji or vector approximations.

Generated with OpenAI image generation for this project. No third-party brand artwork is included. The existing onboarding composition lives separately at `../assets/onboarding-collage.png`.

## Onboarding and Discover expansion · v3

- intention-heart: intention question; selected Identity topic.
- seedling: Bible familiarity / starting point.
- hourglass: reading rhythm.
- reminder-bell: optional reminder.
- butterfly: completion of onboarding.
- lantern: Discover introduction and Purpose.
- olive: onboarding topic choice and selected Peace topic (updates its former reserve status).

Discover renders one illustration at the topic introduction, never on every verse card. Existing related illustrations can represent the same concept across onboarding, Discover and plan entry points. Keep the palette and photographic cutout treatment consistent.

## Expressive topic artwork · v4

New subjects: faith-hands (Faith), purpose-compass (Purpose), relationship-hands (Relationships), gratitude-basket (Gratitude), wisdom-pearl (Wisdom), rest-stones (Anxiety). These replace generic subjects in Discover, whose topic header now gives artwork a larger role. Faith and Purpose also have functional Home topic cards linking directly into the corresponding filtered feed. Keep cream/sage/sky materials and photographic paper contours. Do not insert decorative illustrations into Scripture text or action controls.

## Cloud background

`cloud-bank.png` is a wide atmospheric background for onboarding and membership. Its feathered alpha edges intentionally have no paper contour. Render behind content at low opacity, preserve its aspect ratio, and keep copy legible. It is decorative and should be hidden from accessibility APIs.
