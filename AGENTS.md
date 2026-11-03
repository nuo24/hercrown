# Bible Scroll: agent guide

> Built on the [ai-app-playbook](https://github.com/blakeandersonw/ai-app-playbook) stack. `CLAUDE.md` points here.

## App

For women who want to scroll less and read more, Bible Scroll turns spare phone minutes into a calm, swipeable Scripture reading habit.
Design authority: [IMPLEMENTATION.md](IMPLEMENTATION.md) → [specs/](specs/) → [reference-web/dist/](reference-web/dist/) (the working mockup). Copy what already works; don't reinvent screens.
Domain watch-outs: never alter or fabricate Scripture text; keep reflections and insights clearly separate from Scripture; translation licenses are per publisher.
Reading is free; Plus unlocks plans and study tools. Paywall after onboarding: $29.99/year with a free trial or $2.99/week; on decline, a one-time ~$19.99 yearly offer; declining again opens the free reader ([decision 0003](docs/decisions/0003-trial-hard-paywall-decline-offer.md)). Playbook benchmarks (rough, assume a hard paywall): ~30% trial start, ~30% trial → paid. Measure our own.

## Stack (nothing else)

- API: one Cloudflare Worker (`apps/api/src/index.ts`), plain `fetch` handler, no router framework
- Data: D1 plain SQL (`apps/api/migrations/*.sql`) · R2 (private avatars) · KV · Rate Limiting binding
- Auth: Better Auth (`apps/api/src/auth.ts`): anonymous first, Sign in with Apple, bearer tokens for iOS
- Scripture: KJV, BSB, WEB stored in D1 and bundled offline (`apps/api/seeds/`); other translations online via API.Bible (`apps/api/src/apibible.ts`)
- Payments: Superwall (iOS); `entitlements` table is the source of truth, written only by verified webhooks
- Analytics and errors: Tinybird via `POST /events` → Queue (`apps/api/src/events.ts`, `tinybird/`, [docs/analytics.md](docs/analytics.md)); purchases counted only from verified webhooks
- AI study tools: DeepSeek via OpenRouter (`apps/api/src/ai.ts`, `study.ts`), grounded only in cited free sources, generated once per verse and stored ([docs/study-tools.md](docs/study-tools.md), [decision 0006](docs/decisions/0006-ai-study-tools.md))
- iOS: SwiftUI (`starter-ios/` is an incomplete baseline; target `apps/ios`)

## Commands (run from the repo root)

| Do | Run |
|---|---|
| Install | `npm install --prefix apps/api` |
| Local database | `npm run db:migrate`, `npm run seed:scripture` (KJV, BSB, WEB), `npm run build:study && npm run seed:study` (study data) |
| Dev server (http://localhost:8787) | `npm run dev` |
| Typecheck | `npm run check` |
| Tests | `npm test` |
| New migration | `npx --prefix apps/api wrangler d1 migrations create DB <name>` (from `apps/api`) |
| Rebuild Scripture seeds | `npm run build:kjv`, `npm run build:bsb`, `npm run build:web` (verified, pinned sources) |
| Study-tool evals | `STUDY_EVAL_TOKEN=… node apps/api/scripts/eval-study.mjs [baseUrl]` → `docs/evals/` |
| Deploy staging | `npm run deploy:staging` |
| Deploy production | **humans only** |

Local secrets live in `apps/api/.dev.vars` (copy `.dev.vars.example`). Node 22 / npm (bun not installed).

## Rules

1. Run `npm run check && npm test` before saying done. UI changes: run the app and look.
2. Ask before adding dependencies or vendors. Never Vercel, Netlify, Lovable, Bolt, v0, Replit, Firebase, Supabase, Clerk, Auth0, Sentry, PostHog, Next.js, Hono, Drizzle, Prisma or any ORM.
3. All server logic on Cloudflare. Keys never ship in the app.
4. Every user-visible feature emits an event (once analytics exists). Stream AI and log every AI call with cost.
5. Schema changes are SQL migrations, staging first. Never edit a migration that has been applied remotely.
6. Never touch production data, deploy to production, or commit secrets.
7. Decisions go in `docs/decisions/NNNN-title.md`; parked ideas in `docs/later.md`; progress in `docs/progress.md`.
8. Settings edits never reset onboarding. Fixtures and mock data are never presented as real.

## Done means

Works in the running app, checks and tests pass, events fire, and the change says how it was verified.
