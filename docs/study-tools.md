# Study tools (Plus)

The four tools behind the "Study verse" button, built from free sources ([decision 0006](decisions/0006-ai-study-tools.md)). Code: [apps/api/src/study.ts](../apps/api/src/study.ts), [ai.ts](../apps/api/src/ai.ts), [morph.ts](../apps/api/src/morph.ts). Data: [scripts/build-study.mjs](../apps/api/scripts/build-study.mjs).

| Tool | What she sees | Made from | AI? |
|---|---|---|---|
| **Explain easier** | "Simple explanation" + "Key takeaway" | Commentaries on this verse | Yes, summarizing only the sources given |
| **Deeper study** | Historical context · Original language · Life in biblical times (only when the sources describe customs) · Related passages · Reflect | Commentaries + Greek/Hebrew words + cross-references | Yes, same rules |
| **Original language** | Every Greek or Hebrew word: original, transliteration, English gloss, dictionary meaning, grammar ("Verb · aorist active indicative · 3rd person singular"), full definition | STEPBible | No |
| **Related verses** | Up to 12 passages, best first, with their text in her translation | OpenBible.info | No |

## Sources

| Source | License | What we use |
|---|---|---|
| Jamieson, Fausset & Brown, *Commentary Critical and Explanatory* (1871) | Public domain | 18,213 verse notes |
| Matthew Henry, *Commentary on the Whole Bible* (1706) | Public domain | 5,278 passage notes |
| Adam Clarke, *Commentary on the Bible* (1831) | Public domain | 14,148 notes (57 books) |
| STEPBible TAGNT/TAHOT + TBESG/TBESH lexicons (Tyndale House Cambridge) | CC BY 4.0 | 440,927 Greek/Hebrew words in 31,084 verses; 16,702 dictionary entries |
| OpenBible.info cross-references | CC BY | 307,319 links (top 20 per verse, by votes) |

- **Where the data comes from.** The commentaries come from the [Free Use Bible API](https://bible.helloao.org); STEPBible is pinned to commit `5de0a47`; OpenBible's file is downloaded as-is.
- **Changed sources are caught.** Checksums are recorded in `apps/api/seeds/study-sources.json`, and a changed source fails the build until it's reviewed.
- **Credit is required, so the app must show it.** The CC BY sources must be credited. Each API response includes a `source` / `sources` field. Show it under the tool, plus a credits line in Settings → About.
- **Some notes are cut off.** In this copy of the data, 36 of Matthew Henry's long passage notes and 2 of Clarke's stop at about 32 KB. A long note that never reaches the verse isn't given to the AI, so John 3:16 uses Jamieson-Fausset-Brown and Clarke but not Henry. Fix: load Henry from CCEL.
- **A source we could add:** Tyndale Open Study Notes, which are modern and good. Their CC BY-SA license would make AI answers built from them share-alike too. That's an owner decision.

## How the AI part works

1. **Generated once, shared by everyone.** The first Plus member to open a verse's study triggers generation. The answer is stored and served to everyone after that, and later opens cost nothing. In the eval, each new answer took 1–9 seconds.
2. **The prompt holds only our data.** It contains the verse in BSB and KJV from our verified seeds, the 3 verses before and 2 after, and the source excerpts, each with a tag (`[JFB]`, `[Henry]`, `[Clarke]`, `[Lexicon]`, `[Cross-ref]`). It also lists which tags are allowed for this verse. The rules:
   - use only these sources;
   - cite after each claim;
   - never invent verses or references;
   - say so where Christians differ;
   - plain, warm, modern English, keeping none of the old commentaries' harsh tone.
3. **The answer is checked before it's stored.**
   - The exact sections must be there, in order, and every citation must be a tag it was given. Otherwise the answer is rejected and retried once.
   - References outside its sources are logged for review.
   - Scripture text always comes from our database, never from the model.
4. **The model.** `deepseek/deepseek-v4.1-flash` with `deepseek/deepseek-v4-flash` as fallback, through OpenRouter, with reasoning off (`STUDY_MODEL`, `STUDY_FALLBACK_MODEL`, `STUDY_REASONING`).
   - It costs about **$0.0003 per answer**: 54 calls cost $0.014.
   - To route through Cloudflare AI Gateway (caching, logs, spend limits), create a gateway and set `AI_GATEWAY_URL` to `https://gateway.ai.cloudflare.com/v1/{account}/{gateway}/openrouter`.
5. **Every call is logged.** Each one writes `usage_ledger` (tokens and cost per person) and an `ai_call` event.
6. **Limits:** 60 *new* generations per person per day (`STUDY_DAILY_LIMIT`). Stored answers are unlimited.
7. **Reports.** "Report a problem" accepts inaccurate, unclear, offensive or other. When 3 different people report an answer, it's hidden and regenerated on the next open.
8. **Labeled.** Every answer carries the notice *"AI-generated from the sources cited below. It isn't Scripture: check it against the Bible and the sources."*

## API (Plus only: 403 `premium_required` otherwise)

| Request | Answer |
|---|---|
| `GET /study/{ref}/related?translation=kjv` | `{ ref, label, translation, related: [{ ref, label, text, votes }], source }` |
| `GET /study/{ref}/original` | `{ ref, label, language: "grc"\|"hbo", words: [{ text, transliteration, gloss, strong, morphology, parsing, lemma, lemmaTransliteration, meaning, definition, editions? }], source }` |
| `GET /study/{ref}/explain` · `/deeper` | `{ ref, label, tool, sections: [{ title, text }], sources: [{ tag, name, author, published, license, url }], notice, cached, generatedAt }` |
| same, with `Accept: text/event-stream` | When not stored yet: `delta` {text}… (`reset` {} = clear and start again) … `done` {answer} or `error` {error, message} |
| `POST /study/{ref}/{explain\|deeper}/report` | `{ reason: inaccurate\|unclear\|offensive\|other, note? }` → `{ reported: true }` |

- `{ref}` is one verse, such as `JHN.3.16`.
- Errors:
  - 400: a range or an unknown verse.
  - 429 `study_limit`: the daily limit is reached.
  - 502/503 `study_unavailable`: show "Try again".
- In the app:
  - Render `[Tag]` citations as small chips that open the source list.
  - For Greek words, `editions` "N" means the word is in the Nestle-Aland text (BSB and most modern Bibles) and "K" means it's in the Textus Receptus (KJV). Grey out words missing from her translation's text.

## Data commands

- `npm run build:study`: download (cached in `apps/api/.cache/`), verify and build `apps/api/seeds/study/*.sql`, about 100 MB. The full seeds are gitignored; the 1 MB test subset `seeds/study-test.sql` is committed.
- `npm run seed:study`: load the data into the local database.
- `npm run seed:study:staging --prefix apps/api`: load it into staging. On a "fetch failed" error, re-run the file that failed; each file replaces its own table.
- `STUDY_EVAL_TOKEN=… node apps/api/scripts/eval-study.mjs [baseUrl]`: run the accuracy evals and write a report.

## Verified

**Tests (16 in `study.test.ts`, mocked model):**
- Plus-only access, and one verse at a time.
- Related verses: ranked, with text.
- Greek and Hebrew words with grammar.
- What the model is sent: our verse, the commentaries, allowed tags, reasoning off, a fallback model.
- Generated once, then served from storage.
- Cost logged.
- SSE streaming.
- Rejecting a wrong format or an unlisted source, with one retry.
- Model down → "try again".
- Daily limit.
- Hidden after 3 reports, then regenerated.
- Deeper study's extra sources.
- Long-note handling.

**Evals ([docs/evals/study-2026-11-03.md](evals/study-2026-11-03.md)):**
- 26 verses × 2 tools generated for real: **51/52 passed the automatic checks**. The one failure, Ruth 1:16, named "Clarke" in prose instead of using the [Clarke] tag.
- I read the sensitive ones: Hebrews (no claim that Paul wrote it), Jeremiah 29:11 (the exile context), Proverbs 31, Ephesians 5:22, 1 Timothy 2:12 (says readings differ), Psalm 23 (correct Hebrew). They're accurate to their sources.
- **The owner still needs to review the full report** before launch.

**Staging (live, real model):**
- Psalm 23:1 explained in 1.7 s.
- Matthew 6:34 deeper study streamed.
- Greek words with definitions.
- Free accounts blocked.

## Open for the owner

- **Sensitive passages:** 1 Timothy 2, Ephesians 5, 1 Corinthians 14 and similar. Our sources are 150–300-year-old male commentators. The answers are balanced and say readings differ, but this is a women's app. You could write and approve those answers by hand, since stored answers can be replaced with reviewed ones.
- Whether to add Tyndale Open Study Notes (CC BY-SA) and a complete Matthew Henry.
- Whether to use AI Gateway now or later.
