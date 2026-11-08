# Community photo gallery and suggestions

Current source community-voting.mjs/css. The screenshot the user supplied and current captures show the approved direction. Main gallery is locked to `gallery` in the live app; old variant code is retained only as source history and must not create new production tabs. Community is no longer “coming soon”.

Top: Community serif title, Saved and Settings actions. Headline “A little care, close to home.” and plain explanation of monthly voting for women/girls. Suggest a local cause is a quiet text+arrow action leading to its own page. Monthly ballot: mixed two-column photographs of causes and church projects, title and small category label below, small translucent Vote/Voted action on photo. Do not frost the photograph with a full pane or add bolts/pins. No charity/church segment controls and no italics in this community UI.

Four sample entries are fictional Her Safe Place, Open Doors for Girls, The Motherhood Fund and Grace Church Pantry. Photos are representative stock, with credits in community-photos/CREDITS.txt. Do not publish fiction as actual partner charities or imply shown people are beneficiaries. Replace/approve content and usage with the owner before production.

One member/one vote per period. Vote opens confirmation; confirm persists, cancel preserves prior vote. Change vote before deadline opens a clear move-vote confirmation. Story sheet preserves current gallery and scroll position. Saved header keeps actual app saved passages behavior, not an invented charity collection.

Suggest page: Name(required>=2), native Type picker(Charity/Local church/Community project), City(optional), website(optional fullhttp/https), reason(required>=10,max500). Name/locationmax90. Field error focuses appropriate field. Save confirmation -> view suggestions/edit or return Community. No suggestion is promised ballot inclusion. The mock stores locally and sends nothing.

Production additions required: authenticated ballot IDs, server-owned deadlines/timezone, per-member atomic/upsert vote, duplicate/retry/idempotency handling, eligible voter policy, finalized/closed states, tie/funding rules, nomination submission/moderation and verification workflow, confirmation/error/retry status, abuse controls and privacy. Implement endpoints following existing Cloudflare/API architecture after product rules are settled. Do not let a client choose arbitrary month IDs, deadline or donation amount. A vote never authorizes a payment. No financial checkout is specified here.

Month names/year/deadline and next-month label are hard-coded November/December2026 in reference: replace with real round data. The prototype's retained impact/variant code and sample results are not a finalized production results policy. Loading/empty/closed/already-voted/ineligible/offline/error/duplicate nomination must be designed using the same existing app components.

## Giving total update · giving44

The top of Community now shows **$67,700 donated so far**, with a small Sample total label in the prototype. It uses the existing serif/UI fonts, theme tokens and a thin divider, without a new card or icon. Production must read the aggregate from verified giving records and must not ship this sample amount as an actual financial claim. Loading/unavailable totals should not show a fictional fallback. Currency/locale and what counts as donated require owner-defined reporting rules.
