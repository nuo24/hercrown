# Billing analytics and email preferences

November 19, 2026. Prepared for the next app update, with the account-deletion correction.

## Confirmed diagnosis

The reported iCloud password prompt occurred during Apple checkout, not a reproduced Her Crown sign-in failure. Apple can require purchase authentication even when already signed in: https://support.apple.com/en-us/119848 . Do not suppress StoreKit authentication or force a second Her Crown login after subscribing.

Sign in with Apple requests email and Better Auth stores the identity email in D1's `user` table. It can be an Apple private relay address. Guests and purchases alone do not provide a usable mailing address. Identity storage does not imply marketing consent.

Both Superwall endpoints accepted the November 19 live trial. Tinybird uses `(event,event_id)` as its replacement key, which omitted environment. The staging copy of the same trial replaced the production copy. Read-only queries confirmed the live trial in staging and the entitlement still valid in production. This was a reporting collision, not a failed checkout.

## Corrections

- Billing event IDs are prefixed with the Worker environment. Staging acknowledges and ignores live store events.
- Webhooks await durable queue acceptance. A queue error returns 500; a signed retry requeues the same event without reapplying the entitlement. Tinybird deduplicates the repeated scoped ID.
- Do not turn client checkout callbacks into revenue facts.
- An optional Email updates toggle appears in Your account after Apple sign-in. It defaults off, uses only the verified account email, records a versioned opt-in/withdrawal, and disappears with account deletion. No addresses enter Tinybird. No mailing vendor or email campaign has been configured.
- Account deletion uses the dedicated valid-session guest endpoint; Apple users with an old session reauthenticate, match the intended account, then explicitly confirm deletion again. Apple subscriptions are cancelled separately.

## Staging and production rollout

Apply migration `0017_email_preferences.sql` before deploying the Worker or distributing the new native app. Production commands remain human-run. Deploy/archive only from a clean source checkout, retaining existing user changes outside this update.

The recovery script defaults to read-only. It reads only initial purchases retained in `unmatched_store_events` joined to verified `webhook_events`, preserves real store facts, and skips events already present under either the legacy or scoped ID for the target environment. It repairs analytics only, never entitlements. It needs existing Cloudflare authentication and Tinybird credentials (`TINYBIRD_READ_TOKEN`/`TINYBIRD_TOKEN`, or the gitignored Tinybird CLI configuration). It prints counts, not addresses or tokens.

```sh
node apps/api/scripts/recover-billing-analytics.mjs --env production --since 2026-11-19T00:00:00-05:00
```

November 19 dry-run: one verified purchase examined, one missing production row, zero writes. After the production Worker fix is deployed, the owner can run the same command with `--apply`, then rerun without it to confirm zero missing rows. Do not broadly replay old historical billing events: legacy already-counted events must not be counted again under new IDs.

## Mailing list export

Use the following read-only query for an owner-controlled export after consent is available. Do not export every account as a subscriber, include anonymous placeholder emails, print addresses in analytics, or upload them to a new vendor without approval.

```sql
SELECT DISTINCT u.email, p.consent_version, p.updated_at
FROM email_preferences p
JOIN "user" u ON u.id = p.user_id
WHERE p.subscribed = 1 AND u.emailVerified = 1 AND u.isAnonymous = 0;
```

Before sending, configure the sending domain/provider and Apple private-email-relay authorization, unsubscribe handling, suppression records and appropriate email-use declarations in App Store privacy. Existing accounts remain opted out. This update collects consent; it does not send campaigns.

## Release checks

- API check and regression tests; native regression tests and visual account-screen inspection.
- Real-device Apple sign-in, private relay sign-in and preference reload; revoke consent and verify export exclusion.
- Guest and Apple account deletion after an older session; cancellation/mismatched Apple account must not delete anything.
- Confirm the repaired production trial in both Superwall and Tinybird after owner recovery.
- App Store version/build upload and review are still required for the native changes.
