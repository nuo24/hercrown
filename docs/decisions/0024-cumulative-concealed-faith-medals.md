# 0024: Cumulative progress with concealed medals

Date: 2026-11-23

The owner replaced decision 0020's separate, sequential stages with concurrent lifetime thresholds, following the Opal example: two reading days count as 2/14 and 2/365 simultaneously. Completing one milestone never resets or spends another milestone's progress.

All collections use verified account-scoped reading history. Fruit still requires both distinct reading days and distinct completed chapters; Armor requires reading days and complete canonical books. Themed collections retain their own required books or chapter identities. Duplicate chapters, invalid/future activity and other accounts cannot inflate eligibility.

Progress is visible for every goal. The original artwork stays completely concealed behind a neutral sealed-lock placeholder until that goal's entire requirement is met, including on Home. Fading an unearned illustration is insufficient. Sharing and collected counts remain restricted to earned medals. Labels and requirements remain available so users understand the goal.

The progress endpoint returns medalRulesVersion 5 with cumulative medalStages. Native code ignores legacy sequential stage counters and falls back to lifetime totals; chapter identities remain required for themed milestones. Version 4 local caches/award detection dates are discarded, then recalculated from verified progress. No historical award date is invented.

No onboarding, goal thresholds, payments or production data changes are part of this correction.

## Owner clarification: locked artwork remains visible

On November23 the owner clarified that “not revealed” means original artwork stays visible in grayscale/faded form, then becomes full-colour when the goal is earned. Lock-symbol substitution was incorrect and is removed. This supersedes the placeholder/concealment rendering above; cumulative progress and full earning thresholds remain unchanged. Applies to carousel, collection tiles and Home.
