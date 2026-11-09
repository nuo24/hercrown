# Analytics

How Her Crown measures its funnel (onboarding → paywall → decline → offer → trial → paid), restores and errors. Stack: [ai-app-playbook chapter 08](https://github.com/blakeandersonw/ai-app-playbook/blob/main/playbook/08-analytics-observability.md). Code: [apps/api/src/events.ts](../apps/api/src/events.ts). Tinybird project: [tinybird/](../tinybird/).

```
iOS ──POST /events──▶ Worker ──▶ Queue (bible-scroll-events-*) ──▶ Tinybird Events API ──▶ events data source ──▶ endpoints
Worker (onboarding, verified webhooks, restore, errors, features) ──┘
```

## Rules

- **Purchases come only from verified Superwall webhooks.** `POST /events` rejects `trial_started`, `subscription_started`, `trial_converted` and other verified billing event names. The separate client events describe the checkout UI and never grant Plus or count toward revenue or trial conversions.
- **One fact, one id.** Server events that must count once have deterministic ids: `trial_started:<original transaction id>`, `trial_converted:<original transaction id>`, `subscription_started:<original transaction id>`, `refunded:<transaction id>`, `onboarding_completed:<person id>`; other store events use Superwall's store event id, which is the same in webhook V1 and V2. App events use a UUID the app makes once and reuses on retry. Tinybird merges rows with the same `(event, event_id)` (ReplacingMergeTree); the funnel counts distinct people, so a duplicate never inflates it.
- **Privacy.** Events carry a pseudonymous `person_id` (a random user id), an install id, app version, platform and country (from Cloudflare). Client props accept only listed keys and types. Strings must be predefined labels or approved IDs. Names, emails, onboarding answers, note text, verse text and references, and free-form error messages and stacks are stripped at ingestion. Reading events record the action without the passage. Tests enforce this ([analytics.test.ts](../apps/api/test/analytics.test.ts)).
- **One person across sign-in.** When a guest links Sign in with Apple and gets a new user id, the new account keeps the guest's `person_id` (`analytics_ids` table), so the funnel isn't split. If the Apple account already existed, it keeps its own id and an `account_linked {previous_person_id}` event records the link. The row is deleted with the account.
- **Analytics never breaks the app.** Server events are queued after the response; failures are logged and dropped. Without `TINYBIRD_TOKEN` (local dev), the queue consumer logs the events instead of sending them.
- **Sandbox is separate.** `sandbox = 1` for store sandbox purchases (TestFlight, App Review) and for app builds that aren't from the App Store (`X-Build: testflight | debug`). Endpoints exclude it unless `include_sandbox=1`. `environment` is the Worker's `APP_ENV` (dev, staging, production).

## Events

| Event | From | Props | When |
|---|---|---|---|
| `onboarding_completed` | server | `version` | First `POST /me/onboarding/complete` for this person |
| `trial_reminder_sent` | server | `product_id`, `devices`, `hours_left` | Trial-ending push delivered to Apple ([trial-reminder.md](trial-reminder.md)) |
| `trial_started` | webhook | `product_id`, `period_type`, `store`, `price`, `proceeds` | `initial_purchase` with period TRIAL |
| `subscription_started` | webhook | same | `initial_purchase` without a trial (INTRO = the $19.99 offer) |
| `trial_converted` | webhook | same | `renewal` with `is_trial_conversion` |
| `subscription_renewed`, `subscription_cancelled`, `subscription_uncancelled`, `subscription_product_changed`, `billing_issue`, `subscription_expired`, `refunded` | webhook | same | The matching Superwall event (refunds: negative price) |
| `restore_completed` | server | `restored`, `reason`, `transferred`, `already_active` | Every `POST /me/restore` answer |
| `restore_failed` | server | `error` | Apple unreachable (503) |
| `account_linked` | server | `previous_person_id` | Guest linked to an account that already existed |
| `passage_read`, `passage_saved`, `plan_started`, `plan_step_completed` | server | plan events: `plan_id`, `position` | The action succeeded |
| `ai_call` | server | `feature`, `model`, `tokens_in`, `tokens_out`, `latency_ms`, `cost_usd`, `ok` | Every model call ([study-tools.md](study-tools.md)) |
| `study_viewed` / `study_reported` | server | `tool`, `cached` / `tool`, `reason` | A study opened (stored or new) / reported |
| `note_saved`, `study_saved`, `chapter_completed`, `devotional_read`, `support_sent` | server | `tool`/`saved`, `devotional_id`, `category` (never note or message text) | The action succeeded |
| `error` | server | `source`, `message`, `stack`, `route`, `method` | Unhandled server error (500) |

### iOS client events

All props below are optional. Types are string unless marked number or bool. The `source` column on the stored row is `ios`, including for names also emitted by the server (`plan_started`, `note_saved`, and `error`).

| Event | Props kept | When |
|---|---|---|
| `app_opened` | — | App opens, including before sign-in |
| `tutorial_step` | `index` (number), `entrypoint` (onboarding/settings) | A short app tutorial page appears |
| `tutorial_finished` | `skipped` (boolean), `entrypoint` (onboarding/settings) | Tutorial finishes or is skipped |
| `onboarding_step` | `step`, `index` (number) | An onboarding screen appears |
| `paywall_requested` | `placement` | The app requests a paywall |
| `paywall_viewed`, `paywall_declined` | Paywall props | Superwall opens a paywall or reports a decline |
| `paywall_closed` | — | Superwall closes a paywall |
| `paywall_error` | `placement` | Paywall presentation fails. The raw message is dropped. |
| `paywall_skipped` | `placement`, `reason` | Superwall skips a placement. Only its fixed skip reasons are kept. |
| `decline_offer_viewed`, `decline_offer_declined` | Paywall props | Reserved for the legacy Superwall offer |
| `return_offer_viewed`, `return_offer_dismissed` | `kind`: `decline\|trial` | Sandbox offer shown or explicitly dismissed |
| `purchase_started`, `purchase_failed` | Paywall props and `product_id` | Superwall reports a checkout start or failure |
| `purchase_abandoned` | — | Superwall reports checkout abandonment |
| `purchase_completed_client`, `trial_started_client` | — | Superwall reports a client checkout or free trial success |
| `restore_tapped` | — | The app starts a restore |
| `push_permission` | `granted` (bool), `placement` | The notification permission prompt resolves |
| `push_register_failed` | — | APNs token registration fails |
| `trial_notice_viewed`, `manage_subscription_tapped` | `placement` | Reserved for the trial notice and manage subscription interaction |
| `signed_in` | `method` | Sign in with Apple succeeds |
| `profile_updated`, `avatar_updated`, `account_deleted` | — | The account action succeeds |
| `settings_viewed`, `support_opened` | — | Settings or Support opens |
| `widget_studio_opened` | — | Widget Studio opens; no passage or design content is collected. |
| `widget_studio_saved` | `size`: `small\|medium\|large` | A widget design saves to the shared App Group. |
| `verse_snapshot_opened` | — | Verse snapshot preview opens. No verse text or reference is collected. |
| `setting_changed` | `setting`, `value` | Appearance changes |
| `topics_updated` | `count` (number) | The number of selected topics changes |
| `tab_viewed` | `tab` | The app switches tabs |
| `library_viewed` | — | Saved passages opens |
| `translation_changed` | `translation` | The reader changes translation |
| `study_opened` | `tool` | A study tool opens |
| `verse_search_studied`, `discover_card_read` | — | A search result opens for study or a Discover card is marked studied |
| `note_saved` | — | A note is saved |
| `discover_viewed` | `filter` | Discover loads for a selected filter |
| `home_topic_opened` | `topic` | A Home topic card opens Discover |
| `day_marked_read` | `source` | Today is marked read from Home |
| `streak_viewed` | `current` (number) | Streak details open |
| `plans_viewed` | — | The plans list opens |
| `plan_viewed` | `plan`, `locked` (bool) | Plan details open |
| `plan_started` | `plan` | The app attempts to start a new plan. Use the server event to count successful starts. |
| `plan_step_read` | `plan`, `step` (number) | The reader opens a plan step |
| `devotional_opened` | `id` | An approved devotional opens |
| `error` | `screen` | Reserved for client errors. Messages and stacks are dropped. |

Paywall props are `placement`, `paywall_id`, `variant`, and `experiment_id`. The current Superwall delegate forwards the event names without props. The Worker keeps the safe fields for clients that include them.

A purchase webhook that can't be matched to an account is still recorded (revenue stays complete) with `person_id` null, so it's left out of per-person funnel rates.

## Funnel rates and their denominators

`tinybird/endpoints/funnel.pipe`. **Cohort:** people whose *first* `onboarding_completed` falls in `[start, end)`. Each rate follows those same people, whenever they act later. Counts are distinct people.

| Rate | Numerator | Denominator | Reference |
|---|---|---|---|
| `onboarding_rate` (installs.pipe) | installs whose install id completed onboarding | installs first opened in the window | |
| `paywall_view_rate` | cohort who saw the paywall | cohort (onboarded) | should be ~100%: the paywall follows onboarding |
| `trial_start_rate` | cohort who started a trial | cohort who saw the paywall | playbook ~30% |
| `decline_rate` | cohort who declined the paywall | cohort who saw the paywall | |
| `offer_view_rate` | cohort who saw the $19.99 offer | cohort who declined the paywall | <100%: Apple allows one intro offer per person, so ex-trial users aren't shown it |
| `offer_take_rate` | cohort who bought `hercrown.plus.yearly.offer` | cohort who saw the offer | |
| `trial_to_paid_rate` | trials that converted | trials that **started more than 8 days ago** (7-day trial + 1 day for Apple's renewal) | playbook ~30% |
| `paid_rate` | cohort with any paid start (conversion or direct purchase, including the offer) | cohort (onboarded) | |

**Treat the 30% / 30% figures as rough reference points, not targets.** The playbook's numbers assume a hard paywall. Ours is soft: declining opens the free reader. So expect a lower trial start rate, and measure our own baseline. Trials still running are never counted as failures. Recent cohorts have a small `trials_ended` count until they mature.

Other endpoints: `installs.pipe` (top of funnel), `revenue.pipe` (daily trials, new, conversions, renewals, refunds, net USD), `restores.pipe` (outcomes), `errors.pipe` (hourly by origin, version, route/screen).

## The app's side (SwiftUI contract)

- **Every request** sends `X-Install-Id` (a UUID made on first launch and stored in UserDefaults, not the Keychain, so a reinstall counts as a new install), `X-App-Version` (`1.0 (12)`), `X-Platform: ios` and `X-Build` (`appstore`, `testflight` or `debug`).
- **`POST /events`** with `{ "events": [{ "id": UUID, "name": "...", "at": ms, "props": {...} }] }` (1–50). The bearer token is optional. Keep events in a small on-disk queue. Send on launch, on backgrounding, and every ~30 s. Delete them on 202. Drop the indexes listed in `rejected`. Keep and retry on anything else: offline, 429 or 5xx. Events older than 30 days are refused.
- **Superwall:** call `Superwall.shared.identify(userId:)` with our user id right after guest sign-in, so webhooks map to the person. Map `SuperwallDelegate.handleSuperwallEvent` cases to the paywall events above.

## Setup (human steps)

1. Create a Tinybird workspace. Note its **region API host**, for example `https://api.us-east.aws.tinybird.co`, and set `TINYBIRD_HOST` in `apps/api/wrangler.jsonc` for staging and production. The current value, `https://api.tinybird.co`, is one region's host.
2. Deploy from `tinybird/`: `tb --cloud --host https://api.us-east.tinybird.co --token <admin token> deploy` (done: deployment #1, validated by Tinybird). Tokens `hercrown_append` / `hercrown_read` are declared in `events.datasource`. The CLI writes `tinybird/.tinyb` with the token: it is gitignored.
3. Create a token with **DATASOURCES:APPEND on `events` only** and run `npx wrangler secret put TINYBIRD_TOKEN --env staging`.
4. Run `npx wrangler queues create bible-scroll-events-staging` (Workers Paid), then deploy staging.
5. For dashboards, use Tinybird endpoint charts or any tool that can read the endpoint URLs with a **read** token. Never use the append token for this.

## Verified

**Locally (`analytics.test.ts`):**
- `POST /events` accepts every event emitted by the Swift source, including the Superwall delegate mapping. It refuses server-only and unknown events, bad ids and stale events, strips unsafe props, works before sign-in, flags sandbox builds, and adds the person, install, version and platform.
- Onboarding completion counts once per person.
- Trial start → conversion → renewal from V2 webhooks:
  - A redelivery keeps the same `event_id`.
  - V1 and V2 of one store event get the same id.
  - The offer purchase, refund and sandbox flags work.
  - Unmatched purchases are recorded.
- Restore outcomes and Apple-unavailable failures are recorded.
- Feature events fire only on success and contain no verse references or profile data.
- The person id survives a guest → new account link, an `account_linked` event is recorded for an existing account, and the id is deleted with the account.
- The queue consumer posts NDJSON with the bearer token and acknowledges the batch. It retries on 5xx, 429, 401 and network errors, drops rows Tinybird returns as 400, and logs instead of sending when there's no token.

**Needs a Tinybird account:** the datafiles deploy (`tb deploy --check`), and the endpoint SQL runs and returns the expected numbers on staging data.

**Needs Superwall and sandbox purchases:**
- Real V2 payloads carry `is_trial_conversion`, `price` and `proceeds` as documented.
- `identify(userId:)` makes webhooks land on the right person.
- A staging run-through shows every funnel event in Tinybird, and a thrown test error appears there too.

### November 8 onboarding and Community

- `onboarding_step`: the new flow sends `welcome`, `time`, `demo`, `name`, `comparison`, `season`, `familiarity`, `topics`, `burden`, `loved_ones`, `rhythm`, `prayer`, `reminder`, `ready`; `index` is 0–13. Existing legacy step names remain accepted for older builds.
- `prayer_prepared`: `generated` boolean distinguishes a validated model result from the reviewed simple fallback. `prayer_recited` has no properties. Names, choices, concerns, loved ones and prayer text never enter analytics.
- Server `ai_call` feature `onboarding_prayer` records technical tokens, cost and success only, with a matching usage-ledger entry.
- Server `community_vote_saved`: machine IDs `cause_id` and `round_id`, emitted on a changed vote only; duplicate retries do not create another event or ballot choice.
- Server `community_cause_suggested`: no properties. Nomination names, location, website and reason stay in the authenticated review records, never the event stream.

- `verse_snapshot_shared`: native Snapshot Studio opened the iOS image share sheet; `format` is `portrait`, `square` or `story`. No Scripture, image, name, note or photo is sent to analytics. Opening the share sheet is not proof the user completed sharing.
