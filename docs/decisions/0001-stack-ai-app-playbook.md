# 0001 · Stack: ai-app-playbook

**Date:** 2026-11-02 · **Status:** accepted

**Decision:** Build on the [ai-app-playbook](https://github.com/blakeandersonw/ai-app-playbook) stack: Cloudflare Workers + D1 (plain SQL) + R2/KV, Better Auth, Superwall, Tinybird, OpenRouter/DeepSeek, SwiftUI.

**Why:** One opinionated, low-cost stack, and its funnel benchmarks (~30% trial start, ~30% trial → paid, ≈ $2.70 per download) give a yardstick for marketing.

**Consequences:** Supabase, Firebase, Clerk, Sentry, PostHog, ORMs and router frameworks are out. npm is used instead of bun because bun isn't installed (functionally equivalent).
