# 0002 · Guest-first accounts and merge rules

**Date:** 2026-11-02 · **Status:** accepted

**Decision:** Every install starts as an anonymous Better Auth user (bearer token in the Keychain). Sign in with Apple links it to a real account. When a guest links into an account that already has data:

- Saved passages, reading events and plan step completions are combined. Streak days count once.
- The existing account's preferences and profile win; the guest only fills blanks.
- Onboarding completion is never lost (earliest completion kept).
- Plan progress: furthest position, earliest start.
- Entitlements move over, keeping whichever period ends later, so a guest purchase is never lost.

Account deletion removes all rows and R2 files on every deletion path (`databaseHooks.user.delete.before`).

**Why:** Nobody should have to sign up to read (spec + playbook), and nothing a person did as a guest should disappear. Implemented in `apps/api/src/users.ts`, tested in `test/auth.test.ts`.
