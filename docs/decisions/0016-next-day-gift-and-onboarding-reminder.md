# 0016 — Next-day gift invitation and branded setup reminder

Accepted by the owner November 22, 2026; local/staging implementation, production activation pending.

## Gift timing

Closing a main Plus paywall schedules a gift, rather than immediately showing another offer. Show it only on a later foreground session at least 24 hours after that dismissal, once per account. Canceling StoreKit's payment sheet is not itself a main-paywall decline. Do not repeat the offer after it is claimed, even on another device. The first recorded dismissal starts a server-clocked timer; subsequent dismissals do not reset it. New `gift_offers` rows cascade with account deletion.

Authenticated endpoints record the dismissal, read availability, and atomically claim the invitation. Only claim after current StoreKit products, introductory eligibility, matching annual renewal and 25% pricing have been resolved. Active subscriptions, wrong accounts, background state, an existing modal or paywall, and unavailable products suppress presentation. Claims are consumed before native presentation to prevent duplicate impressions across devices; a presentation interrupted at that final boundary may be skipped rather than repeated. Retry an offline dismissal on the next foreground for the same account. Production's native flag remains off until product/campaign and checkout validation.

## Motion and copy

Use the original paper/ribbon artwork with a layered, hinged closed flap. Reveal opens the flap, lifts the already-present paper out of the envelope, and moves that same folded sheet forward with uniform scale and perspective, then opens three rigid panels about their hinges into the offer surface. Fixed-scale tiled paper grain avoids stretching; fold shading settles away as the offer appears. The sequence takes roughly two seconds. Simulator review exports must preserve captured frame timing (`-fps_mode passthrough`), with close-frame review and normal-speed playback. Ignore repeated taps while opening; cancel unfinished work on dismissal. Reduce Motion uses a brief fade. Revealing never purchases. Keep free reading and close exits.

Remove the long renewal paragraph above the purchase CTA as requested. Retain a concise renewal/auto-renewal/no-trial note in the price card and the Terms/Privacy links. Prices in the labelled design preview are fixtures with purchase/restore disabled; the real offer uses current StoreKit terms.

## Setup reminder

The Lock Screen Live Activity uses a shared native card with the original wreath, original book artwork, consistent small rounded UI typography, plum resume Link and subtle progress rail. The Link and widget URL remain `hercrown://onboarding`; no personal onboarding answers appear on the Lock Screen. The sample preview is labelled and does not change onboarding state.

Keep the card within 160 points at narrow and wide sizes, as [Apple's ActivityKit guidance](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities) notes that taller content may truncate. Apple's Allow/Don't Allow permission UI is system-owned. Physical-device Lock Screen and resume validation remains required.

## Analytics and release

Server emits `mystery_gift_scheduled` on first insertion. Native emits actual-flow viewed/revealed/dismissed events, never from design previews. The funnel source recognizes the gift-view and dismissal names alongside legacy decline-offer events; its production deployment is separate. Purchases and revenue remain verified-webhook-only. New migration 0020 goes to staging first. No production writes/deployments or public release in this work.
