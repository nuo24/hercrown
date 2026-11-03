# Content: what's written, by whom, and how to approve it

Scripture text always comes from our verified Bibles. Everything below is **our** content, kept separate from Scripture in the app.

| Content | File | Status | Who signs off |
|---|---|---|---|
| Discover cards + reflection questions (9 themes × 8) | `apps/api/src/content/verses.json` | The first card of each theme is from the design kit; **63 are drafts** | Owner |
| Verse of the Day rotation (122 verses) | same file (`cards` + `verseOfTheDayExtra`) | Draft selection | Owner |
| Devotionals (29 drafts) | `content/devotionals.json` | **Drafted by AI** from the passage and public-domain commentaries; **none approved, none in the app** | Owner (or a pastor/editor) |
| Privacy policy, terms, refund policy | `apps/api/src/legal/*.md` | **Drafts**: fill in the [brackets], then legal review | Owner + lawyer |
| Credits (licenses) | `apps/api/src/legal/credits.md` | Complete; required by the CC BY sources | Done |

## Approving devotionals

1. Open `content/devotionals.json` and read each draft.
2. Edit freely: `title`, `body` (paragraphs separated by `\n\n`), `reflection`, `tag`.
   - Keep `ref` a real passage. The app shows its text from our Bibles.
   - `minutes` is the reading time.
3. When a devotional is right, set `"approved": true` and `"approvedBy": "Your name"`.
4. Run `npm run check` from the repo root to validate.
5. Load it with `npm run seed:devotionals --prefix apps/api` (local) or `seed:devotionals:staging`.
   - Only approved ones are loaded.
   - Today's Devotional rotates through them in order, one per day, the same for everyone.
   - With none approved, the Home card hides.

To draft more, add outlines to `OUTLINES` in `apps/api/scripts/draft-devotionals.mjs` and run `npm run draft:devotionals --prefix apps/api`. Existing entries are never overwritten. The Luke 1:45 outline failed twice; write it by hand or try again. The 29 drafts cost about $0.01.

## Editing Discover and Verse of the Day

Edit `apps/api/src/content/verses.json`, then run `npm run check`. The checker fails on:
- references missing from any of KJV, BSB or WEB;
- unknown themes;
- repeats;
- empty reflections.

Deploy to take effect. Verse of the Day is the same for everyone on a date and cycles through all 122 verses, mixed so that consecutive days don't share a theme.

## Rules (from the design kit and AGENTS.md)

- Never alter Scripture. Reflections and devotionals are labeled as ours, and AI-drafted devotionals say so.
- No fabricated activity, testimonials or numbers presented as real.
- Andrew Wommack (or any copyrighted teacher) only with written permission.
