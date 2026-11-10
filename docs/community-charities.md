# Community charity shortlist

Researched November 10, 2026. The owner requested real women’s causes across the US, Africa, Europe and Asia to replace the four fictional design profiles. Selection is based on relevant programs and published accountability material, not a comparative efficiency rating or a verified partnership. No charity has been contacted by this task.

| Nominee | Region and reason | Official sources |
| --- | --- | --- |
| Dress for Success Worldwide | United States and international affiliates. Career services and professional clothing support women’s economic independence. | [Programs](https://dressforsuccess.org/about-us/what-we-do/), [annual reports and financials](https://dressforsuccess.org/about-us/who-we-are/) |
| CAMFED | Africa. Girls’ education and young women’s leadership, with a community-led model. | [Mission](https://camfed.org/who-we-are/), [finance and accountability](https://camfed.org/who-we-are/finance-accountability/) |
| Women’s Aid Federation of England | Europe, specifically England. A federation supporting specialist domestic abuse services, information and advocacy. Not the separate Irish, Scottish or Welsh charities. | [About](https://womensaid.org.uk/about-us/), [impact reports](https://womensaid.org.uk/about-us/impact-reports/) |
| Educate Girls US | Asia, specifically India through local implementation partners. US fundraising entity provides a practical donation route for a US business. | [Programs](https://educategirls.us/about-us/what-we-do/), [research and publications](https://educategirls.us/research-publications/) |

## Presentation and giving

Community members express a preference for future giving; voting does not transfer money, authorize payment or guarantee a grant. Recipient checks, funding availability and actual payment remain the owner’s responsibility. The previously owner-confirmed $7,350 donated and 30% revenue commitment are retained without attributing past donations to these new nominees. No fabricated vote totals, charity endorsements or beneficiary stories.

The real shortlist opens its own monthly `YYYY-MM-charities-v1` ballot. Legacy fixture votes remain preserved under their old round IDs and are not mapped to charities. Migration 0015 broadens the database check constraint. All new writes are validated against the current server-owned shortlist.

## Photography

Official charity website photos are not automatically licensed for reuse. Women’s Aid explicitly requires prior written permission for website material: [terms](https://womensaid.org.uk/terms-conditions/). We have not secured permission for beneficiary photos or logos, so none were copied. Use representative, face-free stock photography with an explicit caption instead; cards never identify the photographed people as charity staff or beneficiaries.

Images downloaded at 1200px from Pexels under its [commercial-use license](https://www.pexels.com/license/) on November 10, 2026:

| Card / bundled asset | Photo source | Subject |
| --- | --- | --- |
| Dress for Success / community-safe | [334979](https://www.pexels.com/photo/close-up-of-clothes-hanging-in-store-334979/) | Clothing hangers |
| CAMFED / community-girls | [1148399](https://www.pexels.com/photo/selective-focus-photo-of-pile-of-assorted-title-books-1148399/) | Books |
| Women’s Aid / community-mothers | [5080678](https://www.pexels.com/photo/holding-hands-5080678/) | Hands, illustrative connection |
| Educate Girls / community-church | [9065298](https://www.pexels.com/photo/person-holding-stack-of-books-9065298/) | Books being carried |

Asset keys are retained for older API compatibility; their old filenames do not describe the new nominees. These are not “photos of the charities.” Replace with actual approved program photos only after written permission and recording its scope.

## Rollout

1. Commit checked source, apply migration 0015 to staging, deploy staging, verify real votes and account isolation.
2. Deliver a new native candidate with the new photos, official-site links and nonbinding ballot text. Existing build 29 still contains prototype stock photos and old copy; backend deployment alone cannot update bundled assets.
3. Owner runs production migration and deployment from the recorded clean commit: `cd ~/Downloads/bible-scroll-ios-build-kit/apps/api`, `npm run db:migrate:production`, then `npm run deploy:production`. Do not enable this backend on production ahead of the matching native candidate.
4. Owner verifies production Community loads all four profiles and a vote survives reload. No real funds are moved by these commands.
