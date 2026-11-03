# 0007: Analytics: verified purchases, one person, no personal data

**Date:** 2026-11-03 · **Status:** accepted

**Decision:** Events flow app/Worker → `POST /events` → Cloudflare Queue → Tinybird (playbook chapter 08). Purchases, trials, conversions and refunds are counted **only** from verified Superwall webhooks; the app can't send them. Facts that must count once get deterministic ids (e.g. `trial_started:<original transaction id>`) and Tinybird merges duplicates. A guest who links a new Apple account keeps their analytics `person_id`. Events never carry names, emails, onboarding answers, notes or verse references.

**Why:** The funnel (trial start %, trial → paid %) drives pricing and marketing. Client-reported purchases over-count (retries, jailbreaks, cancelled sheets), and a split identity at sign-in would undercount conversions. Reading and profile data aren't needed to measure billing and would make the analytics store sensitive.

**Consequences:** Rates are per onboarding cohort, with stated denominators ([docs/analytics.md](../analytics.md)). Trial → paid counts only trials that have ended. Unmatched store events still count toward revenue but not toward per-person rates. Deleting an account removes the id mapping; Tinybird rows keep only the pseudonymous id.
