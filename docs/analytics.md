# Analytics

How Bible Scroll measures its funnel (onboarding → paywall → decline → offer → trial → paid), restores and errors. Stack: [ai-app-playbook chapter 08](https://github.com/blakeandersonw/ai-app-playbook/blob/main/playbook/08-analytics-observability.md). Code: [apps/api/src/events.ts](../apps/api/src/events.ts). Tinybird project: [tinybird/](../tinybird/).

```
iOS ──POST /events──▶ Worker ──▶ Queue (bible-scroll-events-*) ──▶ Tinybird Events API ──▶ events data source ──▶ endpoints
Worker (onboarding, verified webhooks, restore, errors, features) ──┘
```

## Rules

- **Purchases come only from verified Superwall webhooks.** The app can't send `trial_started`, `subscription_started`, `trial_converted` or any other billing event; `POST /events` rejects them. What the app reports (`purchase_started`) is a tap, not a sale.
- **One fact, one id.** Server events that must count once have deterministic ids: `trial_started:<original transaction id>`, `trial_converted:<original transaction id>`, `subscription_started:<original transaction id>`, `refunded:<transaction id>`, `onboarding_completed:<person id>`; other store events use Superwall's store event id, which is the same in webhook V1 and V2. App events use a UUID the app makes once and reuses on retry. Tinybird merges rows with the same `(event, event_id)` (ReplacingMergeTree); the funnel counts distinct people, so a duplicate never inflates it.
- **Privacy.** Events carry a pseudonymous `person_id` (a random user id), an install id, app version, platform and country (from Cloudflare). Never names, emails, Apple ids, onboarding answers (intentions, topics), notes or verse references. Billing events carry product, period type, store, and USD price and proceeds only. Reading events say that a passage was read or saved, not which one. Tests enforce this ([analytics.test.ts](../apps/api/test/analytics.test.ts)).
- **One person across sign-in.** When a guest links Sign in with Apple and gets a new user id, the new account keeps the guest's `person_id` (`analytics_ids` table), so the funnel isn't split. If the Apple account already existed, it keeps its own id and an `account_linked {previous_person_id}` event records the link. The row is deleted with the account.
- **Analytics never breaks the app.** Server events are queued after the response; failures are logged and dropped. Without `TINYBIRD_TOKEN` (local dev), the queue consumer logs the events instead of sending them.
- **Sandbox is separate.** `sandbox = 1` for store sandbox purchases (TestFlight, App Review) and for app builds that aren't from the App Store (`X-Build: testflight | debug`). Endpoints exclude it unless `include_sandbox=1`. `environment` is the Worker's `APP_ENV` (dev, staging, production).

## Events

| Event | From | Props | When |
|---|---|---|---|
| `app_opened` | app | | Every launch/foreground. Allowed before sign-in. |
| `onboarding_step` | app | `step`, `index` | Each onboarding screen shown |
| `onboarding_completed` | server | `version` | First `POST /me/onboarding/complete` for this person |
| `paywall_viewed` | app | `placement`, `paywall_id`, `variant`, `experiment_id` | Superwall `paywallOpen` for the main paywall |
| `paywall_declined` | app | same | Superwall `paywallDecline` on the main paywall |
| `decline_offer_viewed` | app | same | `paywallOpen` for the $19.99 offer (presented by the `paywall_decline` placement) |
| `decline_offer_declined` | app | same | `paywallDecline` on the offer; the free reader opens |
| `purchase_started` / `purchase_failed` | app | paywall props + `product_id` (+ `reason`) | Buy tapped / StoreKit error or cancel |
| `restore_tapped` | app | | Restore button tapped |
| `trial_started` | webhook | `product_id`, `period_type`, `store`, `price`, `proceeds` | `initial_purchase` with period TRIAL |
| `subscription_started` | webhook | same | `initial_purchase` without a trial (INTRO = the $19.99 offer) |
| `trial_converted` | webhook | same | `renewal` with `is_trial_conversion` |
| `subscription_renewed`, `subscription_cancelled`, `subscription_uncancelled`, `subscription_product_changed`, `billing_issue`, `subscription_expired`, `refunded` | webhook | same | The matching Superwall event (refunds: negative price) |
| `restore_completed` | server | `restored`, `reason`, `transferred`, `already_active` | Every `POST /me/restore` answer |
| `restore_failed` | server | `error` | Apple unreachable (503) |
| `account_linked` | server | `previous_person_id` | Guest linked to an account that already existed |
| `passage_read`, `passage_saved`, `plan_started`, `plan_step_completed` | server | plan events: `plan_id`, `position` | The action succeeded |
| `error` | both | `source`, `message`, `stack`, `route`/`method` (api) or `screen` (ios) | Unhandled server error (500); app crash or error |

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
| `offer_take_rate` | cohort who bought `biblescroll.plus.yearly.offer` | cohort who saw the offer | |
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
2. Install the Tinybird CLI. Then, from `tinybird/`, run `tb login` and `tb --cloud deploy --check`, then `tb --cloud deploy`. **These datafiles haven't been through Tinybird's checker yet.**
3. Create a token with **DATASOURCES:APPEND on `events` only** and run `npx wrangler secret put TINYBIRD_TOKEN --env staging`.
4. Run `npx wrangler queues create bible-scroll-events-staging` (Workers Paid), then deploy staging.
5. For dashboards, use Tinybird endpoint charts or any tool that can read the endpoint URLs with a **read** token. Never use the append token for this.

## Verified

**Locally (21 tests in `analytics.test.ts`, plus the earlier suites):**
- `POST /events` accepts listed events, refuses server-only and unknown events, bad ids and stale events, and strips unlisted props. It works before sign-in, flags sandbox builds, and adds the person, install, version and platform.
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
