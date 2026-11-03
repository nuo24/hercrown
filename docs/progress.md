# Progress

Playbook phases ([ai-app-playbook AGENTS.md](https://github.com/blakeandersonw/ai-app-playbook/blob/main/AGENTS.md)) adapted to Bible Scroll. Updated 2026-11-03.

## Phase 0–1: Niche & brief — ⏭️ skipped on purpose
Product, design and mockup already exist (this kit). Pricing decided: see [decisions/0003](decisions/0003-trial-hard-paywall-decline-offer.md).

## Phase 2: Accounts & repo — ⚠️ partly done
- [x] `apps/api` scaffolded from the playbook templates
- [x] `AGENTS.md`, `CLAUDE.md`, `docs/progress.md`, `docs/decisions/`, `docs/later.md`
- [x] Root scripts: `dev`, `check`, `test`, `deploy:staging`
- [x] Local git repository and first commit
- [ ] **[HUMAN]** Create an empty private repo on your GitHub and share its URL, then push
- [x] Apple Developer account
- [ ] **[HUMAN]** Create accounts: Cloudflare (Workers Paid, $5/mo), Apple Small Business Program, Superwall, Tinybird, API.Bible, OpenRouter
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

## Phase 5: AI study tools — approved ([decision 0006](decisions/0006-ai-study-tools.md))
- [ ] Load sources: STEPBible lexicon/morphology, OpenBible cross-references, public-domain commentaries
- [ ] `ai.ts`: DeepSeek via OpenRouter + AI Gateway, timeout + fallback, `ai_call` cost events, Plus quota
- [ ] Explain Easier, Deeper Study, Original Language, Related Verses: generated once per verse, stored, cited, labeled
- [ ] Evals: 20+ verses scored for accuracy (e.g. authorship, context) before launch
- [ ] **[HUMAN]** OpenRouter account + key; Cloudflare AI Gateway

## Phase 7: iOS — not started

## Phase 8: Payments & entitlements — ⚠️ server side built locally
- [x] `POST /webhooks/superwall`: Svix signature verified, processed once, out-of-order safe → `entitlements`
- [x] `GET /me/entitlements` (also in `GET /me`) is the only Premium check; trial / active / grace / expired / refunded
- [x] Reading, saving and streaks free; reading plans need Plus (`premium_required`)
- [x] Subscription follows a guest who links an account
- [ ] **Restore on a new install / new account** (app sends the signed StoreKit transaction; server verifies it with Apple and reassigns the entitlement)
- [ ] **[HUMAN]** App Store Connect products: yearly $29.99 + trial, weekly $2.99, decline offer ~$19.99; Superwall project + webhook → `wrangler secret put SUPERWALL_WEBHOOK_SECRET`
- [ ] iOS: `Superwall.shared.identify(userId:)` with our user id right after guest sign-in; paywall placements; decline offer
- [ ] Trial-ending reminder (push, Phase 11)

## Phase 9: Analytics & errors — not started
- [ ] `POST /events` → Queue → Tinybird; funnel: download → onboarding → paywall → trial → paid

## Next, in order
1. Restore Purchases (verified App Store transaction → current user)
2. Offline BSB, WEB and CPDV (same verified pipeline as KJV)
3. Tinybird analytics (onboarding → paywall → decline → offer → trial → paid; restore outcomes)
4. **Trial-ending reminder** — Scroll the Bible's #2 complaint is being charged without the promised reminder. Server knows each trial's end; push + in-app notice 2 days before, visible in Settings → Subscription.
5. **AI study tools** (Phase 5 above)

## Gaps found in the competitor recording ([walkthrough](research/scroll-the-bible-walkthrough.md))
- [ ] Notes per verse (auto-saved) and a "library" (studies, studied, saved, notes)
- [ ] Bible progress: chapters completed of 1,189; days opened vs days read; weeks in a row; days this year
- [ ] Verse of the Day and Today's Devotional (+ devotionals-read count)
- [ ] Preferences: font size (4 steps), Words of Jesus in red (needs red-letter data), system theme
- [ ] Email sign-in (they use email only; we have Apple — add email OTP/magic link)
- [ ] App Tracking Transparency prompt for ad attribution (marketing decision)

## Phases 10–14 — not started

## Open owner decisions
- Licenses for the 10 online translations (NLT, NLTCE, AMP, NASB, NASB95, NKJV, CSB, CEV, GNT, NIV) — [decisions/0004](decisions/0004-scripture-sources.md)
- API.Bible caching terms (ask support@api.bible)
- Community tab direction ([later.md](later.md))
- Final bundle id (placeholder `com.biblescroll.app`)
