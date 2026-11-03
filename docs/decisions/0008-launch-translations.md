# 0008: Launch with free translations; add licensed ones after revenue

**Date:** 2026-11-03 · **Status:** accepted

**Decision:** Launch with the three public-domain translations already bundled offline: KJV, BSB and WEB. Don't buy API.Bible commercial licenses yet. Add licensed translations once subscriptions cover them, starting with NKJV and NLT.

**Why:** API.Bible's commercial plan is a $29/month base fee plus a license per publisher. These are the prices the owner saw on 2026-11-03:

| License | Translations | Price |
|---|---|---|
| Lockman bundle | AMP, NASB, NASB 2020, LBLA, NBLA | $25/mo |
| Tyndale + NavPress bundle | NLT, NLT-CE, NTV, NVT, MSG | $25/mo |
| American Bible Society bundle | GNT, CEV | $12/mo |
| HarperCollins | NKJV | $10/mo |
| Lifeway | CSB | $10/mo |

All of these come to about $111/month before the first subscriber. NIV wasn't in the list that was seen. KJV, BSB and WEB cost nothing, work offline, and are verified ([0005](0005-offline-translations.md)).

**Consequences:**
- No online translations are registered yet, so the app shows KJV, BSB and WEB only. The API.Bible connector (`apps/api/src/apibible.ts`) is built and tested.
- Enabling a licensed translation later takes four steps: buy the license, set the key with `wrangler secret put API_BIBLE_KEY`, add a small migration that registers the translation with its API.Bible id, and test it on staging.
- Suggested first step: NKJV + NLT (HarperCollins $10 + Tyndale bundle $25 + base $29 ≈ $64/month).
- We stay behind Scroll the Bible's 12 translations at launch. Revisit once the funnel shows how many people leave the translation picker without choosing one.
- Licenses don't cover caching; ask support@api.bible before caching anything ([0004](0004-scripture-sources.md)).
