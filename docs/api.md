# Her Crown API: reference for the iOS app

Every endpoint the SwiftUI app calls, grouped by screen. Staging: `https://bible-scroll-api-staging.bible-scroll-api.workers.dev`. Code: [apps/api/src/index.ts](../apps/api/src/index.ts). Tests in `apps/api/test/` show exact requests and responses.

## Conventions

- **Auth.** On first launch, `POST /api/auth/sign-in/anonymous` with `{}`, then keep the `set-auth-token` response header in the Keychain. Send it as `Authorization: Bearer <token>` on every call. Everything below needs it, except `/health`, `/legal/*` and `/webhooks/*`.
- **Headers on every call:**

  | Header | Value |
  |---|---|
  | `X-Install-Id` | A UUID, kept in UserDefaults |
  | `X-App-Version` | e.g. `1.0 (12)` |
  | `X-Platform` | `ios` |
  | `X-Build` | `appstore`, `testflight` or `debug` |

- **References** are canonical: `BOOK.CHAPTER.VERSE` or `BOOK.CHAPTER.START-END`, with USFM book ids (`JHN.3.16`, `PSA.23.1-3`). The design kit's aliases (`ps23`, `pr31`…) also work.
- **Days.** Reading activity is sent as the phone's local calendar day, `localDay: "YYYY-MM-DD"`, plus `timeZone` (IANA). Days after the earliest time zone's today are rejected.
- **Errors** are JSON: `{ "error": "<code>", "message": "<show this>" }`.

  | Status | Meaning |
  |---|---|
  | 400 | `invalid_request` |
  | 401 | No session |
  | 403 | `premium_required`: show the paywall |
  | 404 | Not found |
  | 413 | Too large |
  | 429 | `rate_limited` / `study_limit` |
  | 503 | Temporarily unavailable: retry |

- **Offline.** Queue writes with client-generated ids or timestamps (`id`, `at`) and retry; every write is safe to repeat.

## Launch and account

| Call | Use |
|---|---|
| `POST /api/auth/sign-in/anonymous` | Guest account (first launch) |
| `POST /api/auth/sign-in/social` `{ provider: "apple", idToken: { token } }` | Sign in with Apple. Links the guest's data |
| `POST /api/auth/email-otp/send-verification-otp` `{ email, type: "sign-in" }` → `POST /api/auth/sign-in/email-otp` `{ email, otp }` | "Continue with Email". 6-digit code, 10 minutes, 5 tries. Links the guest's data. Only on when email is set up |
| `POST /api/auth/delete-user` `{}` | Delete account and all data |
| `GET /me` | Profile, preferences (incl. `fontSize`, `wordsOfJesusInRed`, `translation`, `widgetRef`, `position`), onboarding, membership |
| `POST /me/opened` `{ localDay }` | Once per launch: "Days opened" |
| `PATCH /me/profile` `{ displayName?, bio? }` · `PUT`/`GET`/`DELETE /me/avatar` | Settings → Account (JPG/PNG/WebP ≤ 10 MB) |
| `PATCH /me/preferences` | Any of: `intention`, `familiarity`, `topics[]`, `routine`, `remindersEnabled`, `reminderTime` ("HH:MM"), `timeZone`, `appearance` (light/dark/system), `gradient`, `fontSize` (default/large/larger/largest), `wordsOfJesusInRed`, `translation`, `widgetRef` (verse or null) |
| `POST /me/onboarding/complete` | End of onboarding (first time only counts) |
| `PUT /me/devices` `{ token, environment, timeZone }` · `DELETE /me/devices/{token}` | Push token, for trial reminders |

## The Bible tab

| Call | Use |
|---|---|
| `GET /scripture/translations` | Translation picker (with copyright lines) |
| `GET /scripture/books?translation=bsb` | Book/chapter picker and the rail's verse counts |
| `GET /scripture/{translation}/{BOOK}/{chapter}` | A chapter: `title` (psalm superscription), `verses[{ verse, text, wordsOfJesus? }]`, neighbours |
| `GET /scripture/{translation}/passages/{ref}` | A passage |
| `GET /scripture/search?q=&translation=` | Search, or jump to a reference typed in |
| `GET /scripture/random?translation=` | Toolbar's random verse |
| `PUT /me/position` `{ ref, at }` | Bookmark: where she left off |
| `PUT`/`DELETE /me/saved/{ref}` · `GET /me/saved` | Heart / saved verses |
| `GET`/`PUT`/`DELETE /me/notes/{ref}` `{ text, at }` | "Your Notes · Auto-saved". Empty text deletes |
| `POST /me/chapters/{BOOK}/{chapter}/complete` `{ localDay, timeZone }` · `DELETE` · `GET /me/chapters?book=` | End of chapter: Bible progress, also a reading day |
| `POST /me/reading-events` `{ events: [{ id, localDay, timeZone, ref?, planId?, planStep? }] }` | Reading days (streak) |

`wordsOfJesus` holds `[start, length]` ranges in UTF-16 units, which is Swift's `NSRange`. Colour them only when `wordsOfJesusInRed` is on.

## Study (Plus)

All of these return 403 `premium_required` for free users. See [study-tools.md](study-tools.md).

| Call | Use |
|---|---|
| `GET /study/{ref}/explain` · `/deeper` | AI notes with cited sources. Send `Accept: text/event-stream` to stream (`delta`, `reset`, `done`, `error`) |
| `GET /study/{ref}/original` | Greek/Hebrew words, meanings and grammar |
| `GET /study/{ref}/related?translation=` | Related verses |
| `POST /study/{ref}/{explain\|deeper}/report` `{ reason, note? }` | Report a problem |
| `PUT`/`DELETE /me/studies/{ref}/{explain\|deeper}` | Save a study |
| "Widget Verse" | `PATCH /me/preferences { widgetRef }` |

## Home

| Call | Use |
|---|---|
| `GET /scripture/verse-of-the-day?translation=` | Same verse for everyone today, with `theme` and `reflection` |
| `GET /devotionals/today?translation=` · `GET /devotionals/{id}` · `POST /me/devotionals/{id}/read` `{ localDay }` | Today's Devotional. 404 = none approved yet: hide the card |
| `GET /me/streak?today=` | Streak card |
| `GET /me/progress?today=` | Streak sheet: Bible progress (of 1,189), days opened vs read, weeks in a row, days this year, devotionals read |
| `GET /plans` · `GET /plans/{id}` · `POST /plans/{id}/start` · `POST /plans/{id}/steps/{n}/complete` | Today's Reading / plans. Plus |
| `GET /me/widget?date=&translation=` | Home-screen widget: her chosen verse, else today's |

## Discover

| Call | Use |
|---|---|
| `GET /discover?filter=for-you\|plan\|Peace…&translation=` | Cards: verse in the selected enabled edition + `reflection` (not Scripture), `saved`. `filters[]` gives the chip titles in order. Licensed editions return up to 12 cards with `nextOffset`; request `offset=nextOffset` for more |

## Saved / library

| Call | Use |
|---|---|
| `GET /me/library` | Counts: `savedVerses`, `notes`, `studies`, `studied` |
| `GET /me/saved` · `GET /me/notes` · `GET /me/studies` · `GET /me/studied` | The four lists. Pages of 50: pass `?before=<value from nextBefore>` |

## Settings

| Call | Use |
|---|---|
| `GET /me/entitlements` | Subscription row (`trial` details while trialing) |
| `POST /me/return-offer/decline` | Staging only. Records the first Main paywall decline for a free user. |
| `POST /me/return-offer/impression` `{ kind: "decline" \| "trial" }` | Staging only. Checks eligibility and atomically reserves one display per account per rolling 24 hours. |
| `POST /me/trial-return-offer` | Staging only. Signs the Apple promotional offer for a verified annual sandbox trial with auto-renew disabled. |
| `POST /me/restore` `{ transactionId }` | Restore Purchases ([restore-purchases.md](restore-purchases.md)) |
| `GET /me/support` · `POST /me/support` `{ category, message, contactEmail?, contactPreference? }` | Contact & Support. Returns reference `HC-XXXXXXXX`. 5 per day |
| `GET /legal/{privacy\|terms\|refunds\|credits\|support}` | In-app reading pages (`?format=md` for Markdown) and the App Store URLs |

Settings → Suggestions & bugs uses the existing `Feedback` and `Something isn't working` categories. Reports are saved in D1 `support_requests` with their reference, category, message, app version and status. The user's own history comes from authenticated `GET /me/support`. Message text is excluded from analytics. Email delivery requires `EMAIL_FROM` and `SUPPORT_INBOX`.

The owner can export suggestions and bugs as a spreadsheet-compatible CSV. Run from `apps/api`, with Cloudflare authentication, and keep the output outside Git because it contains user messages.

```sh
node scripts/export-feedback.mjs staging /tmp/hercrown-feedback-staging.csv
```

After launch, the human operator can use `production` instead of `staging` to review production tickets.

## Analytics

`POST /events` with `{ events: [{ id, name, at, props }] }`. See [analytics.md](analytics.md) for the event list and when to send each.

## Personal onboarding prayer and Community (November 8)

- `POST /me/onboarding/prayer` (any authenticated reader, no Plus required): optional `name` (24), `season` (fixed choices), `heart` (up to 3 fixed topics), `familiarity`, `burden` (100), `lovedOnes` (60). Returns `{prayer,kind:"personal_prayer",version:1}` only after validation. Three attempts per user per UTC day; 429 at cap; 503 retry/simple-prayer fallback on invalid or unavailable generation. Input is neither stored nor logged; technical AI usage is recorded.
- `GET /me/community`: owner-confirmed giving `{totalCents,currency,revenuePercent,reportedAt}`, server-owned `{id,title,closesAt,preview}` round or null, causes, and this member’s vote. Both environments return the researched independent nominees (Mercy Multiplied, Sharing the Mission, House of Grace Thailand, Meninadança). `ballotNote` explains nonbinding preference voting and independent nominee status; each cause includes an official `website`. Real rounds use `YYYY-MM-charities-v2`, separate from historical fixture rounds. Production requires migrations 0015 and 0016 before deploying this change.
- `PUT /me/community/vote`: `{roundId,causeId}`; rejects stale/unknown round and candidate IDs, one atomic upsert per member/month, duplicate same-choice retry is idempotent. No purchase or payment.
- `GET /me/community/suggestions`: this member’s private suggestions (up to 100).
- `POST /me/community/suggestions`, `PATCH /me/community/suggestions/:id`: `{name,type,city,website,reason}`; name 2–90, type Charity/Local church/Community project, optional city <=90 and http(s) website <=500, reason 10–500. Five new suggestions/day; duplicate same-name/city retries return existing receipt; only owner/submitted records can be edited. No automatic publication or promise of funding.

Daily passage personalization: `/scripture/verse-of-the-day` rotates among curated references matching the signed-in reader’s saved topics. No matching topics uses the shared daily pool. `/me/widget` uses the same selection unless an explicit widget verse is set. Scripture text still comes from the selected licensed translation.

#### Licensed online editions (2026-11-08)
NKJV, MSG, AMP and NLT are fetched on demand through the Worker with `API_BIBLE_KEY`. Migration 0014 registers the provider IDs and publisher credits. Remote responses use `Cache-Control: no-store`; iOS retains at most six chapters in memory, without bundling or seeding copyrighted text. A verse bridge has optional `end` (e.g. verse 1/end 3), is shown once and is not split into invented verses. Study generation continues to use existing public-domain sources. Native-only mobile apps are exempt from FUMS reporting: https://docs.api.bible/resources/fair-use/. Web clients would need reporting.

Licensed daily content: Home, Discover, devotional passage quotations and library snippets resolve NKJV/MSG/AMP/NLT through API.Bible when selected. Canonical refs remain stable for notes/saves, while `label` reports the actual provider verse bridge (e.g. Psalm 23:1–3). Provider errors are surfaced rather than silently substituting KJV. Devotional commentary and public-domain study grounding are unchanged; licensed passage text is never supplied to the model. The iOS offline session uses bundled KJV when the saved selection requires the network.

Discover supports `includeText=false` for its editorial catalog: all references and reflections return without fetching online translation chapters (`text` is empty, `nextOffset` is null). Fetch the selected passage separately before displaying Scripture. The default text-filled response remains compatible with existing builds.


### Next-day gift (migration 0020; production activation pending)

- `POST /me/gift-offer/decline`: authenticated main-paywall dismissal; records first server timestamp, excludes Plus. Returns `{scheduled:boolean}`.
- `GET /me/gift-offer`: returns `{due:boolean}` after 24 hours if still unsubscribed and not previously claimed. Read-only.
- `POST /me/gift-offer/claim`: atomic account-wide impression claim; returns `{available:boolean}`. Call only after fresh StoreKit eligibility and safe foreground presentation checks. No purchase or entitlement mutation.

Faith Medal progress: `GET /me/progress` includes `bible.completedChapterRefs` (`["JHN.3", "PSA.23", ...]`), canonical identities of the authenticated user’s completed chapters through the requested local day. Existing totals/book fields are unchanged. Thematic medal clients match exact chapter lists rather than infer completion from totals.

### Sequential Faith Medal counters

`GET /me/progress` returns `medalRulesVersion: 5` and `medalStages`: per-medal records with `id`, cumulative `days`, `units`, `earned` and `completedChapterRefs` (matched journey refs only). All milestones count the same verified account-scoped history concurrently; counters cap at each goal's target and never reset when another goal is earned. Armor units are fully completed canonical books. Other themed goals count only their assigned books or chapter identities. Both the reading-day and chapter/book requirements must be met to earn/reveal full-colour artwork. Repeated chapters do not inflate distinct chapter counts; ordinary verse reading does not count as chapter completion. Native clients ignore pre-v5 sequential counters and invalidate pre-v5 local medal caches. Lifetime Bible/streak fields are unchanged.
