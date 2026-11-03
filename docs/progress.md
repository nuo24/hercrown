# Progress

Playbook phases ([ai-app-playbook AGENTS.md](https://github.com/blakeandersonw/ai-app-playbook/blob/main/AGENTS.md)) adapted to Bible Scroll. Updated 2026-11-02.

## Phase 0–1: Niche & brief — ⏭️ skipped on purpose
Product, design and mockup already exist (this kit). Pricing decided: see [decisions/0003](decisions/0003-trial-hard-paywall-decline-offer.md).

## Phase 2: Accounts & repo — ⚠️ partly done
- [x] `apps/api` scaffolded from the playbook templates
- [x] `AGENTS.md`, `CLAUDE.md`, `docs/progress.md`, `docs/decisions/`, `docs/later.md`
- [x] Root scripts: `dev`, `check`, `test`, `deploy:staging`
- [x] Local git repository and first commit
- [ ] **[HUMAN]** Decide where the code lives on GitHub (suggested: a shared GitHub organization), then push
- [ ] **[HUMAN]** Create accounts: Cloudflare (Workers Paid, $5/mo), Apple Developer (start now; takes days) + Small Business Program, Superwall, Tinybird, API.Bible
- [ ] `apps/ios` (port `starter-ios`)

## Phase 3: Backend + database — ⚠️ built locally, not deployed
- [x] D1 migrations: auth, app tables, Scripture catalog (`apps/api/migrations/`)
- [x] `GET /health`, JSON errors, rate limits on auth
- [x] Core API: profile, avatar, preferences, onboarding, saved passages, reading events + streak, plans
- [x] Scripture: full KJV (31,102 verses, verified), chapters, passages, search, API.Bible connector
- [ ] Error events to Tinybird (Phase 9)
- [ ] **[HUMAN]** Cloudflare account → staging D1/KV/R2 → deploy → `curl https://<staging>/health` returns 200

## Phase 4: Auth — ⚠️ built locally
- [x] Anonymous sign-in, bearer tokens, account deletion, guest → account merge (tested)
- [x] Sign in with Apple (code ready; switched off until keys exist)
- [ ] **[HUMAN]** Apple Services ID + key → `wrangler secret put APPLE_CLIENT_ID / APPLE_CLIENT_SECRET`
- [ ] Verify Apple sign-in end to end on staging

## Phase 5: AI — ⏸️ undecided
Insights lens currently shows curated sample content. Decide whether insights use AI.

## Phase 7: iOS — not started

## Phase 8: Payments & entitlements — next
- [ ] `/webhooks/superwall` (verified, idempotent) → `entitlements`; `GET /me/entitlements`
- [ ] Free trial + hard paywall, decline offer (~$19.99), Restore Purchases, trial-ending reminder

## Phase 9: Analytics & errors — not started
- [ ] `POST /events` → Queue → Tinybird; funnel: download → onboarding → paywall → trial → paid

## Phases 10–14 — not started

## Open owner decisions
- Which online translations, and their licenses ([decisions/0004](decisions/0004-scripture-sources.md))
- API.Bible caching terms (ask support@api.bible)
- Community tab direction ([later.md](later.md))
- Final bundle id (placeholder `com.biblescroll.app`)
