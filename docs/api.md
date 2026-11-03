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
| `GET /me/widget?translation=` | Home-screen widget: her chosen verse, else today's |

## Discover

| Call | Use |
|---|---|
| `GET /discover?filter=for-you\|plan\|Peace…&translation=` | Cards: verse (from our Bibles) + `reflection` (not Scripture), `saved`. `filters[]` gives the chip titles in order |

## Saved / library

| Call | Use |
|---|---|
| `GET /me/library` | Counts: `savedVerses`, `notes`, `studies`, `studied` |
| `GET /me/saved` · `GET /me/notes` · `GET /me/studies` · `GET /me/studied` | The four lists. Pages of 50: pass `?before=<value from nextBefore>` |

## Settings

| Call | Use |
|---|---|
| `GET /me/entitlements` | Subscription row (`trial` details while trialing) |
| `POST /me/restore` `{ transactionId }` | Restore Purchases ([restore-purchases.md](restore-purchases.md)) |
| `GET /me/support` · `POST /me/support` `{ category, message, contactEmail?, contactPreference? }` | Contact & Support. Returns reference `HC-XXXXXXXX`. 5 per day |
| `GET /legal/{privacy\|terms\|refunds\|credits}` | In-app reading pages (`?format=md` for Markdown) and the App Store URLs |

## Analytics

`POST /events` with `{ events: [{ id, name, at, props }] }`. See [analytics.md](analytics.md) for the event list and when to send each.
