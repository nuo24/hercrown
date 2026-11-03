# 0003 · Paywall: free scrolling, Premium trial, decline offer

**Date:** 2026-11-02 · **Status:** accepted (implementation in Phase 8)

**Decision:** Copy what works for Scroll the Bible rather than the playbook's hard paywall:

- Paywall after onboarding. Annual **$29.99 with a free trial** (Scroll the Bible uses 7 days on yearly) and **weekly $2.99**.
- Declining shows a one-time **decline offer** (yearly ~$19.99). Declining again enters the app.
- **Scrolling the Bible is free.** Premium unlocks reading plans and the study tools (Explain easier, Deeper study, Related verses, Original language).
- The server's `entitlements` table is the only Premium check.

**Supersedes:** the earlier "hard paywall" choice (same day) and the kit spec's "no trial" (specs/CURRENT-DESIGN.md). The free-reading exit from the kit spec is kept.

**Why:** Scroll the Bible (1M+ downloads, 4.8★) gates study features, not reading. Note: the playbook's 30% / 30% benchmarks assume a hard paywall, so expect a different trial-start rate; compare against our own funnel.

**Decided 2026-11-03:** 7-day free trial on both yearly and weekly; the ~$19.99 decline offer is a first-year introductory price (renews at $29.99). Keep trial length and offer price configurable (App Store Connect + Superwall), not hard-coded.
