# Trial-ending reminder

People on a free trial hear from us before they're charged. It's Scroll the Bible's #2 complaint: their paywall promises a "Trial reminder", and reviewers say they were charged without one. Code: [apps/api/src/reminders.ts](../apps/api/src/reminders.ts), [push.ts](../apps/api/src/push.ts).

## The format we copy (Scroll the Bible's paywall)

From the screen recording, the trial paywall reads, top to bottom:

```
            (logo)
   Unlock Lifescrolling
     Beat Doomscrolling
 4.8★ App Store | 100K+ Readers | 7-day Free trial
 [ one review card ]
 🔒 Full access  |  🔔 Trial reminder  |  ⊗ Cancel anytime
       ✓ No commitment, cancel anytime
              $39.99/year ($3.33/mo)
            [        Continue        ]
 [ SAVE 44%  7-Days Full Access ~~$79.99~~ $39.99/year   $0.76/week ]
```

**Ours, in Superwall:** the same layout and chips ("Full access · Trial reminder · Cancel anytime"), with our own headline, numbers and prices. Under the price, Apple wants the trial terms spelled out, so we say: *"7 days free, then $29.99/year. We'll remind you 2 days before your trial ends."* Only show numbers we really have, like ratings and reader counts. Until then, use a different stat or leave it out.

## What we actually do

| When | What | Where |
|---|---|---|
| Trial starts | The app asks: *"Want a reminder before your trial ends?"* → iOS notification permission | App, right after purchase |
| 2 days before the trial converts (day 5 of 7) | **Push:** "Your free trial ends in 2 days" / "Her Crown Plus becomes a yearly plan on Friday, Nov 7. To avoid being charged, cancel before then in Settings → Subscriptions." | Server, Cron Trigger every 15 min |
| Day 5 until it ends | **In-app notice** on Home, with Cancel / Manage | App, from `subscription.trial` |
| Always during a trial | Settings → Subscription: "Free trial · ends Fri, Nov 7 · then $29.99/year · Manage" | App |

Rules:
- **Once per trial.** Sending is recorded in `trial_reminders`.
- **Not if cancelled.** If auto-renew is off, no reminder goes out, and the app says "Your trial ends Fri, Nov 7. You won't be charged."
- **Not at night.** Sends only between 9:00 and 21:00 local time. Once fewer than 30 hours are left, it sends anyway.
- **No later than 12 hours before the end.** A reminder that late can't help, so it isn't sent.
- **No price in the push.** App Store prices depend on the country, so the app shows the price it gets from StoreKit.
- **Lead time is configurable:** `TRIAL_REMINDER_LEAD_HOURS`, default 48.
- **Don't turn on Superwall's built-in "Trial Reminder Notifications."** They're scheduled on the phone at purchase time. They'd still fire after someone cancels, and they'd duplicate ours.

## API

- `GET /me` and `/me/entitlements` return `subscription.trial` while a trial is running:
  ```json
  { "endsAt": 1799000000000, "convertsToPaid": true, "remindFrom": 1798827200000,
    "manageUrl": "https://apps.apple.com/account/subscriptions" }
  ```
  Show the Home notice when `now ≥ remindFrom` and `convertsToPaid`. For "Manage", prefer StoreKit's `AppStore.showManageSubscriptions(in:)`; `manageUrl` is the fallback.
- `PUT /me/devices` `{ token, environment, timeZone }`
  - Call it after permission is granted, and on every launch.
  - `token` is the APNs token in hex.
  - `environment` is `sandbox` for Xcode builds and `production` for TestFlight and the App Store.
  - `timeZone` is `TimeZone.current.identifier`.
- `DELETE /me/devices/{token}`: when notifications are turned off, or the user signs out.
- Tapping the push opens `hercrown://settings/subscription`.
- Events:
  - From the server: `trial_reminder_sent`.
  - From the app: `push_permission {granted}`, `trial_notice_viewed`, `manage_subscription_tapped`.

## Setup

1. Create an Apple Developer key with **Apple Push Notifications service** enabled. One key can also do Sign in with Apple.
2. Load it into staging:
   - `npx wrangler secret put APNS_PRIVATE_KEY --env staging < AuthKey_XXXX.p8`
   - `npx wrangler secret put APNS_KEY_ID --env staging`
   - `npx wrangler secret put APPLE_TEAM_ID --env staging`
3. In Xcode, add the **Push Notifications** capability to the app target.

## Verified

**Locally (14 tests in `reminders.test.ts`):**
- Device register, move and unregister, including following a guest who signs in.
- The trial info returned to the app; cancelled trials and paid plans.
- The push goes once to every device on the right APNs host, with the right headers and text, and isn't re-sent.
- Not sent too early, not for cancelled trials, held during quiet hours, sent anyway when the trial is about to end.
- No device: checked again on later runs.
- Dead tokens are removed; retried when Apple is busy.
- The analytics event, wording in different time zones, and a valid APNs signature.
- Without a key, nothing is sent and the in-app notice still works.

**Needs the APNs key and a real iPhone (staging):**
- Apple accepts our token and the push arrives, which can only happen on a deployed Worker, not `wrangler dev`.
- Sandbox trials renew in minutes, not days, so a 7-day sandbox trial can't show the 2-day lead. To test on staging:
  1. Register the phone.
  2. Insert a test trial ending in 40 hours for that staging account.
  3. Wait for the next 15-minute run.
