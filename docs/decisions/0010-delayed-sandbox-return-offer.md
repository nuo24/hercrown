# 0010 · Show the first-year offer on a later reopen

Closing the Main paywall goes straight to free reading. Keep Superwall's built-in `paywall_decline` placement paused so it cannot stack a second paywall.

In the US Apple sandbox, check the offer after a cold launch or return from the background. For a reader who declined Main and remains on Free, require a 20-minute sandbox grace period and a verified $19.99 first-year introductory price on `hercrown.plus.yearly.offer`, renewing at $29.99. For a still-active annual sandbox free trial with auto-renew off, use the existing `trial_return_1999` promotional offer on `hercrown.plus.yearly`. StoreKit provides the displayed prices, eligibility, and checkout. The staging server checks Apple status before reserving or signing a trial offer and verifies purchases before granting Plus.

Both paths share one impression per rolling 24 hours per Her Crown account. The offer is in the app and uses no push notification. Before a production rollout, decide the grace period, eligibility after trial expiry, and whether to enable either offer at launch.
