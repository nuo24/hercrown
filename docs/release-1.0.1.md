# Her Crown 1.0.1

## App Store What's New

Make a little more room for the Word.

- A new Pink appearance, with coordinated buttons and a calmer, consistent background.
- Faith Medals with illustrated collections, cumulative reading progress and clear milestones. Unearned medals retain their original artwork in a greyed-out style.
- Original illustrations for all 66 Bible books, a four-column book picker and artwork at the beginning of each book.
- Six additional free offline Bible editions: ASV, Young's Literal Translation, Darby, Webster, Majority Standard Bible and Spanish Reina-Valera 1909.
- Refined Home and Discover layouts, consistent dividers and improved title wrapping.
- A redesigned onboarding reminder and smoother onboarding interactions.
- An animated gift invitation and first-year annual offer for eligible readers.
- Improved account deletion, optional email preferences, review and feedback prompts, and paywall loading preparation.
- Reading navigation and progress fixes, plus subscription tracking improvements.

## Full change list and release limits

This is the consolidated release candidate following internal builds 34–44, not a claim that every intermediate design shipped. Native source is the current clean codex/four-handoffs checkout. Standard Release must use production; do not reuse the HC_STAGING_TESTFLIGHT archives or internal-only uploads.

### Reading and content

- Bundle ASV, YLT, Darby, Webster, MSB and Spanish RV1909, with pinned, verified source text and source attributions. KJV, BSB and WEB remain available offline. Licensed online editions remain provider-backed; CSB, ESV and NIV have not been added.
- Remove online/offline suffixes from translation names and preserve free-reader fallback when an online edition is unavailable.
- Original 66 book illustrations; four book columns, centred whole-word names, existing chapter-number grid and search. Book artwork appears at chapter 1 verse 1, not every chapter.
- Stable verse scroll targets and first-visible-verse tracking, including short-chapter completion and retained session reading state.

### Appearance and navigation

- Saved Pink appearance, #31222B accents, one #FBF1F4 Home/Discover canvas without darker rounded verse/feature cards.
- Compact, consistently spaced Home rows; full-colour Home fruit teaser, inline View medal arrow and matching 1pt section dividers.
- Discover verse/completion metadata grouped separately from theme/reflection. Long headings preserve whole words.
- Original Scripture typography and text retained; no global font-size override.
- Repeated Plus labels removed while entitlement and paywall access checks remain.

### Faith Medals

- Illustrated Fruit, Armor, Psalms, Women and Promises collections with subtle selection haptics.
- All milestones count the same verified cumulative activity concurrently. No sequential resets. Reading days and distinct chapters, fully completed books or specified passages must meet the respective goal.
- Ungranted medals show grey/faded original icons, never substitute lock icons. Sharing and Collected status require earned thresholds.
- Versioned caches discard superseded progress rules; duplicate chapter events do not inflate progress.

### Onboarding, membership and accounts

- Resumable onboarding and branded Lock Screen Live Activity after app launch, subject to iOS permission. Tap finishes the current animated text/haptics without automatically advancing screens; user-requested reversal was held pending comparison.
- Guest automatic standard paywall after chapter completion, with a 24-hour presentation cooldown. The later proposed first-visit-after-24-hours/one-standard-prompt-only policy has NOT been implemented.
- Paywall preloading removes a fixed presentation pause. Physical-device loading latency still needs measurement; do not claim the earlier reported three-second delay is eliminated.
- Native closed-envelope, printed-letter lift and unfolding transition into the actual offer surface; same off-white paper across header, safe areas and offer. Reduced Motion supported.
- Neutral pricing box, red struck-out original price and unchanged new-price style. Eligible US offer: $29.99 first year, then $39.99/year, no free trial, only when current Apple terms match. Native checkout uses Superwall reporting. No fabricated eligibility or forced purchase.
- Gift eligibility is account-scoped: prior standard-paywall decline, a subsequent opening at least 24 hours later, no Plus and current Apple introductory-offer eligibility. No immediate same-session gift.
- Account-deletion flow handles fresh authentication for Apple accounts and preserves safety confirmations. Optional marketing email consent defaults off and is separate from storing account email.
- Native rating request after at least seven days and three reading days, once per version and at least 120 days apart, subject to Apple's display decision. Separate feedback invitation after 14 days/five reading days, at least 90 days apart; no five-star gating.

### Billing and analytics

- Environment-scoped verified billing IDs, durable queue handling and replay-safe recovery; production trial recovery was previously verified exactly once. TestFlight remains sandbox; never report test activity as real customer revenue.
- Additional events cover onboarding reminders, medals, guest paywalls, gift invitation/reveal/purchase and account controls.

## Production rollout: owner-run only

Completed by the owner on November 24 from clean source `63008e87978b37a2117e59a3bc31394d88b7b54e`: migrations 0018–0020 and all six free-edition imports succeeded; Cloudflare version `0e63a432-989e-4d36-9115-4e0e3ebd0862`. Independent read-only health/privacy/terms/support/credits checks returned HTTP 200; health reports production. Do not rerun the completed rollout. Production-connected physical-device checks remain outstanding; public health does not verify account, purchase, restore or gift behavior.

Do not submit for public review until physical-device checks complete. AGENTS.md forbids agent production data changes and deployments. The prior owner deployment was fa89f54 / 9b0767cd-1d25-456e-a499-6ecb80b3512a with migration 0017. The commands below are the completed rollout record, not a request to rerun them.

From this clean checkout, in apps/api, the owner runs:

```sh
npm run db:migrate:production
npx wrangler d1 execute DB --env production --remote --file seeds/asv.sql
npx wrangler d1 execute DB --env production --remote --file seeds/ylt.sql
npx wrangler d1 execute DB --env production --remote --file seeds/darby.sql
npx wrangler d1 execute DB --env production --remote --file seeds/webster.sql
npx wrangler d1 execute DB --env production --remote --file seeds/msb.sql
npx wrangler d1 execute DB --env production --remote --file seeds/rv1909.sql
npm run deploy:production
```

Stop on any error. Do not reseed the existing KJV/BSB/WEB data or rotate credentials. Record source SHA, migration results and Cloudflare version. Then verify production health and use dedicated test accounts on the production-connected release candidate to check sign-in, Pink persistence, free editions, medals, deletion, onboarding/Live Activity, sandbox purchase/restore and gift eligibility/reporting. Owner changed App Store release to automatic after approval on November 24; complete verification before submitting for review, because approval can publish the update without another release action. Existing customer accounts must not be used for deletion tests.
