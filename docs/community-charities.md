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

### Follow-up: authentic people photography

Owner prefers actual participants/program activity over illustrative objects. Do not treat stock models as beneficiaries.

- Dress for Success Twin Cities publishes a [brand-kit photo gallery](https://www.dressforsuccesstwincities.org/brand-kit.html) expressly welcoming journalists, corporate partners and supporters to use its photos to highlight its mission/events. Credit: Meredith Gruenes — crosslakemedia.com. These depict that affiliate, not necessarily Worldwide programs; any eventual card must identify the affiliate accurately. Example official image: `https://www.dressforsuccesstwincities.org/uploads/1/2/9/5/129566098/clm-4872_1.jpg`.
- CAMFED has authentic participant imagery, but its [communications/image-release policy](https://camfed.org/wp-content/uploads/2021/12/Camfed_Child_Protection_Policy.pdf) specifies controlled external release, accurate captions and photographer credits. Request an approved app-use image before bundling.
- Educate Girls US lists media enquiries on its [media kit](https://educategirls.us/media/); no reusable beneficiary-photo license was established during this search.
- Women’s Aid requires permission for site material. Its own About page also uses stock images, so an official-site image alone is not proof that someone is a beneficiary. Request an approved staff/program photograph rather than identifying survivors.

No messages sent, no additional photo permissions obtained, and no beneficiary images deployed by this follow-up.

1. Commit checked source, apply migration 0015 to staging, deploy staging, verify real votes and account isolation.
2. Deliver a new native candidate with the new photos, official-site links and nonbinding ballot text. Existing build 29 still contains prototype stock photos and old copy; backend deployment alone cannot update bundled assets.
3. Owner runs production migration and deployment from the recorded clean commit: `cd ~/Downloads/bible-scroll-ios-build-kit/apps/api`, `npm run db:migrate:production`, then `npm run deploy:production`. Do not enable this backend on production ahead of the matching native candidate.
4. Owner verifies production Community loads all four profiles and a vote survives reload. No real funds are moved by these commands.


## Selected revision, November 10

Owner selected Mercy Multiplied (USA), Sharing the Mission (Nigeria), House of Grace (Thailand), and Meninadança (Brazil). Native cards and the local web preview now use their official program photos. These assets are bundled locally for review only; public reuse permission and photo-specific credits remain unconfirmed. Do not distribute this revision until cleared. Migration 0016 retains all historical vote identifiers and uses a fresh charities-v2 ballot so old votes are not reassigned. Staging and production have not received this revision. Earlier nominee and stock-image notes above are historical.


### Permission update from owner, November 10

Owner confirms photo-sharing permission for the selected Meninadança, Sharing the Mission and House of Grace images. This supersedes the pending-permission notes for those three selections; permission correspondence is held by the owner and has not been independently inspected. Mercy Multiplied permission is not confirmed: removed its official program photo from native/preview card assets and substituted existing Pexels stock photo 6646918, explicitly identified as representative, not Mercy participants or staff. Pexels license checked at https://www.pexels.com/license/; do not imply endorsement. No staging/production deployment or TestFlight upload in this update.
