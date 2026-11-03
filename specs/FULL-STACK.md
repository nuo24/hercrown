# Full-stack implementation guidance

These are proposed engineering contracts, not services already deployed by this kit. Choose a maintainable stack compatible with the team and document the choice. Do not let the browser’s local fixtures become the production backend by accident.

## Domain model

- Profile: stable user ID, display name, email where applicable, bio, avatar reference, created/updated timestamps. Separate guest identity from authenticated user.
- Preferences: intention, familiarity, topic IDs, routine, reminder opt-in/time/time zone, appearance, shared gradient configuration, onboarding version/completion.
- Scripture: translation ID, book ID, chapter/verse numbers, canonical text, source/version metadata. Preserve a stable canonical reference; maintain aliases for existing `ps23`, `pr31`, `mt11`, `jr29`, `pr3`, `ps119`, `ps107`, `pr17`, `jm1` IDs used by the prototype.
- Saved passage: user/guest ID, canonical passage reference, timestamp; unique per user/reference.
- Reading event: immutable event ID, local calendar day plus time zone and UTC timestamp, passage/plan context. Deduplicate day completion and sync safely across devices.
- Plan/progress: plan definition, ordered passage references, start date, completion events, current position and resume state.
- Membership: App Store product ID, verified transaction/original transaction identifiers, entitlement state and expiry, last server verification. No client-only paid boolean.
- Support request: category, message, contact preference, consent context, status and timestamps. Avoid retaining message drafts unnecessarily.
- Insight: canonical passage/version, content category, source citations/provenance, generated-vs-curated flag, model/content version and review/cache timestamps.

## Services and suggested API boundaries

Implement repository protocols first and provide fixture/local/remote adapters. Naming is illustrative; GraphQL, REST or another typed contract may be used.

- Session/profile: create guest session, sign in, link guest data, fetch/update profile and preferences, sign out, delete account when a real account service exists.
- Avatar: request authorized upload, upload validated image, update profile reference, delete/replace previous image as appropriate. Keep storage private unless public profiles are an explicit product feature.
- Scripture: list books/chapters/translations, fetch chapter, search canonical text, obtain source metadata. Bundle a useful offline starting library and cache fetched chapters.
- Reading/saved: upsert/delete saved reference, batch reading events, fetch streak/progress and resolve sync conflicts without losing completed days.
- Plans: list/filter plans, fetch exact references, start/resume/complete plan steps.
- Insights: request a passage-scoped insight with content type and translation context; return source references and clear status. Streaming is optional, not required for fidelity.
- Membership: verify App Store transaction, reconcile entitlement and process server lifecycle notifications idempotently. Client still listens to transaction updates.
- Support: create request, return a real reference/status; optionally hand off an authorized user-composed message to a real approved contact destination.

## Accounts and offline behavior

Keep guest reading, preferences, saves and streak functional without mandatory account creation. Add native sign-in where needed for sync. Use a standard secure auth provider; credentials/tokens belong in appropriate secure storage, never plaintext preference files. Define guest-to-account merge rules: union saves, deduplicate reading days, choose explicit preference conflict handling, preserve stable plan progress. Provide meaningful offline and token-expiry states.

Use a local durable store appropriate to the platform for bookmarks, progress and cache; lightweight preferences can use AppStorage/UserDefaults. Queue retryable mutations and use idempotency keys. Keep Scripture available when connectivity fails. Surface a recoverable sync error without erasing the local reading session.

## Scripture and insight integrity

The provided fixture has two complete chapters, not the whole Bible. Choose a complete source with rights suitable for intended distribution and territories, and keep metadata/attribution. The included source note is historical provenance, not blanket legal clearance for every translation. Preserve canonical text; personalized reflections are a separate content layer.

The current lens opens static sample content. If implementing AI, make a real provider-backed service with passage grounding, translation/source references, honest generated-content labeling, privacy controls, timeouts and retry states. Keep API secrets on the server. Handle unanswerable questions rather than fabricating original-language or scholarly claims. If AI is not part of the approved scope, retain useful curated insights and label them accurately.

## Subscription implementation

Proposed product IDs could be `biblescroll.plus.yearly` and `biblescroll.plus.weekly`; these are not configured App Store products. Create a StoreKit development configuration for local testing. Production display prices/currencies must come from StoreKit product responses, and any monthly equivalent must reflect that actual price.

Handle fetch/loading, product unavailable, purchase in progress, pending/Ask to Buy, user cancellation, failure, verified success, refund/revocation, expiry, restore and account changes. Never unlock on an unverified result or treat tapping Continue as a purchase. Keep the free exit usable. Existing research supports only comparator examples, not an industry-wide pricing claim; see historical MEMBERSHIP-PREVIEW.

Define which Plus benefits are actually gated before launch. The demo does not enforce entitlements. Ensure displayed benefits correspond to implemented services. Do not silently add a trial or change proposed annual/weekly terms.

## Notifications

Use native notification APIs after an explicit reminder opt-in. Persist time zone semantics, reschedule when settings change, handle permission denial/revocation and show clear status. Do not request push permission at cold launch just because a mock switch exists. Add push infrastructure only for real server-originated events.

## Community and support

Community is currently an honest empty/unavailable state. A real social feature requires actual storage, identities, lifecycle, pagination and user protections, with report/block/moderation flows, rather than seeded fake activity passed off as real. Do not expand its scope unnoticed.

The support form currently previews only. Before enabling delivery, choose a real destination, validation, rate limiting and user confirmation of transmitted contents. Replace fictional contact numbers. A WhatsApp-style badge does not authorize sending a message automatically.

## Release configuration and operational work

Provide local/staging/production configuration examples with no secrets. Include migrations, schema constraints, backup/restore expectations, least-privilege access policies and integration test fixtures. Define service health/error monitoring without logging private reading notes or support contents by default. Document provider setup and external dependencies clearly.

Before release, resolve App Store signing/product setup, final branding/icon, legal content, privacy disclosures, translation rights, subscription entitlement rules, account deletion where applicable and real support details. These are production tasks, not reasons to stop building the local reviewable implementation.
