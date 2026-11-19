# 0014 — Guest paywall at a chapter boundary

Date: 2026-11-19. Owner selected “After completing a chapter” in chat.

Keep Explore as a guest and free reading. Exploring skips the remaining onboarding and its initial paywall. After a meaningful completed chapter, offer the standard dismissible paywall on moving into the next chapter. No initial 24-hour wait. Require the chapter ending and at least three distinct verses (all verses when a chapter is shorter). A jump straight to the final verse is insufficient.

Automatic offers are limited to once every rolling 24 hours on the device, persisted across relaunches. A guest's other paywall requests, including full onboarding or tapping a locked feature, also start that cooldown so the automatic offer does not immediately follow them. Manual premium-feature paywalls remain available regardless of the automatic cooldown.

Suppress automatic offers while signed in, premium, offline, backgrounded, showing a reader sheet, or presenting another billing flow. Bind a pending offer to the guest account and expire it after five minutes; account switching clears it. Dismissal retains free reading. No account is created with Apple or purchase initiated automatically.

Reuse the existing `onboarding_complete` Superwall campaign to show the same standard paywall without requiring a new remotely configured placement. The separate `guest_chapter_paywall_requested` event distinguishes the automatic guest trigger from the general paywall event. Existing server-verified entitlements remain authoritative. The disabled $19.99 return offers stay disabled.
