# Restore Purchases

How a Bible Scroll Plus subscription gets back to a person after a reinstall, on a new phone, or after signing in.

## Why the server must verify it

Superwall's `restorePurchases()` unlocks Plus **on the device** (it calls `AppStore.sync()`), but it sends no webhook, and Superwall keeps the subscription on the *original* app user id. Our server gates plans (and later study tools) by the `entitlements` table, so the app must also tell the server — and the server must check with Apple, never trust the device.

## Flow

1. App: `Superwall.shared.restorePurchases()` (or the paywall's Restore button).
2. App: read the current Plus transaction from StoreKit 2 and send its id:
   ```swift
   for await result in Transaction.currentEntitlements {
       if case .verified(let tx) = result, plusProductIDs.contains(tx.productID) {
           try await api.restore(transactionId: String(tx.originalID))
       }
   }
   ```
   If there is no current entitlement, still call the endpoint with the most recent Plus transaction from `Transaction.all` (the server then explains why nothing was restored).
3. Server → Apple: `GET https://api.storekit.apple.com/inApps/v1/subscriptions/{transactionId}` with an ES256 JWT (`iss` issuer id, `kid` key id, `aud` `appstoreconnect-v1`, `bid` bundle id, 20-minute lifetime). If Apple doesn't know the id in production and `APP_STORE_ALLOW_SANDBOX=true`, it retries `api.storekit-sandbox.apple.com` (App Review and TestFlight purchases are sandbox).
4. Server checks: bundle id matches `APPLE_APP_BUNDLE_IDENTIFIER`; product is in `PLUS_PRODUCT_IDS`; Apple status (1 active, 2 expired, 3 billing retry, 4 grace, 5 revoked); expiry date; revocation date.
5. Server writes the entitlement and returns the new membership. The app refreshes `GET /me`.

## Request / response

`POST /me/restore` with the user's bearer token.

```json
{ "transactionId": "2000000123456789" }
```

**200** — a business outcome (show it, don't retry):

```json
{
  "restored": true,
  "transferred": false,
  "membership": {
    "premium": true,
    "subscription": { "status": "active", "productId": "biblescroll.plus.yearly", "expiresAt": 1798934400000,
                      "willRenew": true, "isTrial": false, "store": "app_store", "sandbox": false }
  }
}
```

| `restored` | `reason` | What to show |
|---|---|---|
| true | — | "Welcome back to Plus." |
| true, `transferred: true` | — | Same; the subscription moved here from another account on this Apple ID. |
| true, `alreadyActive: true` | — | Plus is already active on this account (a longer-running subscription). |
| false | `not_found` | "We couldn't find a purchase for this Apple ID." |
| false | `no_plus_subscription` | Same as above. |
| false | `expired` | "Your Plus subscription has ended." + offer to resubscribe |
| false | `billing_retry` | "Apple couldn't renew your subscription. Update your payment method in Settings." |
| false | `revoked` | "This purchase was refunded." |
| false | `wrong_app` | Should never happen; log it. |

**Errors:** 400 `invalid_request` (malformed id) · 401 no session · 429 `rate_limited` (10 per minute per account) · **503 `restore_unavailable`** (Apple unreachable/busy, or not configured — safe to retry; tell the user to try again).

## Ownership rules

- A subscription belongs to an **Apple ID**, not an app account. A verified restore makes the restoring account the owner; any other account holding that `original_transaction_id` loses it. Every move is logged in `entitlement_transfers` (deleted with the account).
- If the restoring account already has a **different** subscription that runs at least as long, nothing changes (`alreadyActive`).
- Repeating a restore is harmless (same row, no new transfer).
- Later Superwall webhooks find the owner by `original_transaction_id` first, so renewals, cancellations and refunds update the account that restored it, even though Superwall still reports the old user id.
- Guests who link Sign in with Apple keep their subscription through the normal merge (decision 0002).

## Configuration

| Name | Where | Value |
|---|---|---|
| `APP_STORE_ISSUER_ID` | secret | App Store Connect → Users and Access → Integrations → In-App Purchase: Issuer ID |
| `APP_STORE_KEY_ID` | secret | Key ID of an **In-App Purchase** key |
| `APP_STORE_PRIVATE_KEY` | secret | Contents of that `.p8` file (`npx wrangler secret put APP_STORE_PRIVATE_KEY --env staging < SubscriptionKey_XXXX.p8`) |
| `APPLE_APP_BUNDLE_IDENTIFIER` | var | Real bundle id (placeholder `com.biblescroll.app`) |
| `PLUS_PRODUCT_IDS` | var | `biblescroll.plus.yearly,biblescroll.plus.weekly,biblescroll.plus.yearly.offer` (proposed ids) |
| `APP_STORE_ALLOW_SANDBOX` | var | `true` everywhere, including production (App Review uses sandbox) |

**App Store Connect products (one subscription group, "Plus"):**
- `biblescroll.plus.yearly` — $29.99/year, introductory offer: 7-day free trial.
- `biblescroll.plus.weekly` — $2.99/week, introductory offer: 7-day free trial.
- `biblescroll.plus.yearly.offer` — $29.99/year, introductory offer: pay up front $19.99 for 1 year (the decline offer, first year only). Apple allows one introductory offer per customer per group, so someone who already used a free trial isn't eligible for the $19.99 intro price — Superwall should only show the offer to eligible users.
- Turn on **Family Sharing** for the group (a complaint in Scroll the Bible's reviews).

## Verified locally vs. still to verify

**Verified locally (87 tests):** JWT header/claims and a valid ES256 signature; the request URL; production → sandbox fallback and the sandbox switch; active, trial, grace, expired, billing retry, revoked, wrong app, wrong product, not found; choosing between several subscriptions; ownership transfer + log + later webhook routing; the "longer subscription" guard; repeat restores; malformed ids (no Apple call); Apple down / busy / 401; rate limit; account deletion.

**Needs Apple credentials and real sandbox purchases:**
- A real In-App Purchase key authenticates against Apple (expect 401 → 503 if it's wrong).
- The products exist and Apple's responses match the documented fields (`offerType`/`offerDiscountType` for trials, `gracePeriodExpiresDate`).
- Sandbox purchase → delete app → reinstall → Restore → Plus returns, plans unlock.
- Two app accounts on one Apple ID → restore moves Plus; the next Superwall webhook updates the new owner.
- Refund in sandbox → `refund` webhook ends access.
- Hardening (optional): verify Apple's JWS certificate chain (x5c → Apple Root CA G3) in addition to trusting the authenticated API response.
