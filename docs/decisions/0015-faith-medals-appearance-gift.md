# 0015 — Faith medals, book illustrations, Pink and gift fallback

2026-11-21. Integrate the four supplied handoffs in sequence, against the existing build-34 code. Do not modify global fonts, Dynamic Type or the welcome layout: the owner explicitly deferred that work.

Faith medals use the existing account-scoped `/me/progress` response, not the prototype's sample earned states. Both distinct reading days and distinct completed chapters must reach the displayed goal. Fruit goals run from 14 days/14 chapters through 365/365. Armor runs from 21/21 through 180/180. Psalms requires 30/75/150 Psalms chapters plus 30/90/180 reading days. Women requires all of Ruth/Esther/Luke plus 30/60/90 reading days. Promises requires 60/120/365 reading days and 50/120/365 chapters. These are reading milestones, not measurements of virtue or faith. They do not require Plus, AI calls, or a purchase.

Rarity is an editorial difficulty tier, explicitly labeled as such. Do not show invented percentages of users. Sharing is only available after real progress qualifies. Cached progress belongs to the signed-in account; missing data is an unavailable state, never a fabricated accomplishment. First-detected award dates are not historical completion dates.

Preserve the supplied original artwork, including sprite cells and individual overrides. Bible-book images map canonical IDs to the 66 verified manifest entries; no Scripture changes.

Pink is a persistent third explicit appearance alongside Light, Dark and System. The owner's `#31222B` overrides the older reference's wine accent for buttons, pills and interactive accents. Preserve existing light/dark layouts.

The gift fallback must not invent prices, eligibility, or billing terms. Show an actual available discounted first-year annual product only after resolving StoreKit terms; reveal itself never purchases. Continue-free and close always exit. Existing disabled return-offer campaigns stay disabled. No production deployment or release is part of this work.
