# Personalized onboarding — current flow and edge cases

Authoritative source: `reference-web/dist/onboarding-new.mjs` and `personal-onboarding-motion.mjs`. The older questions array and baseline eight-step screenshots are superseded. Detailed extracted branch copy is in `copy/onboarding-audit`; exact live source wins if an audit excerpt differs.

Current flow IDs: **0, 1, 2, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15** (14 screens; missing numeric IDs are intentional). Progress uses eight visual segments mapped across these steps, not 16 separate pages.

1. Welcome: “Less doomscrolling. More Scripture.”, existing collage, Get started, Explore as a guest, no account requirement.
2. Time reframing: “If you scroll for 2 hours a day, that’ll be 10 years of your life spent on social media.” Pink accent #A94F75; then “Let’s show you how to turn some of that time toward Christ.” Flower pops in after that sentence. Continue remains hidden/inert until the entire sequence finishes.
3. Solution demonstration: “We’re going to help you spend less time scrolling social media and more time in the Bible.” No italic emphasis. iPhone demonstration frame with Dynamic Island treatment, 297px reference height (10% larger than previous), embedded video and compact-height fallback. Verify recorded video content/phone framing for production.
4. Name: lead “Now let’s build a Bible experience that’s for you.” / paragraph break / “We’ll ask a few questions to shape your own For You page.” Then first-name question and input. Trim and capitalize the first Unicode letter before using it on later pages. Preserve the rest of a person's chosen spelling; no compulsory account.
5. Comparison: social media / Bible / about the same, nonjudgmental acknowledgement.
6. Season: Single, Dating, Married, Motherhood, Separated or divorced, Prefer not to say; multi-select. Prefer not to say excludes other answers and vice versa. Acknowledge motherhood/single/relationship combinations as implemented, never assume marital status from motherhood.
7. Familiarity: Just starting / I know a little / I read regularly.
8. Heart: Peace, Purpose, Faith, Relationships, Identity, Anxiety, Gratitude, Hope, Wisdom; up to three. Fourth selection shows the existing limit message and preserves answers.
9. Free text: “Tell us something that’s been weighing you down.” No italics; optional, max100 reference characters.
10. Prayer for someone: “Who’s someone in your life you’d like to pray for?” No italics; optional names, max60 reference characters.
11. Pace: “How much time can you give to God each day?” with personalized name prefix; 2/5/10 minutes or No set goal.
12. Personalized prayer: uses name, season priority, heart needs and optional shared words/names. Slow reveal with haptic ticks; Keep this prayer appears only after complete. Hold-to-hear uses native speech, release stops. Save/download optional copy; prayer is separate from Scripture.
13. Reminder: “When would you like a moment with God?” personalized prefix. Daily reminder switch, time always visible (default08:00), current native-style notification example. Save my choice asks OS notification authorization only when enabled and appropriate; disabled/denied paths still continue. Denied users can later open Settings; never repeatedly prompt or hide the time until toggle.
14. Ready: “You don’t have to begin perfectly.” in regular, non-italic type, personalized welcome, saved prayer copy, Open my Bible. Complete/guest paths must integrate with existing onboarding/paywall business boundary; prototype's completion callback is not a purchase.

## Personalization and state rules

Source `responseFor(previous)` is exhaustive for implemented acknowledgements; `prayer()` defines actual deterministic prayer composition, including empty answers and season precedence. Preserve branch wording and escaping. `names` overrides legacy `children` if provided; do not add an extra children page because the variable exists. No separate unused intention/more-question routes should be invented from stale objects.

Personalized acknowledgement is shown alone, types completely, holds, exits, then the next question enters. The question must never overlap acknowledgement. Questions type first; options/input/subcopy appear after completion and cannot accept input early. No italic markup should return to the two explicitly plain-text questions. Latest display type reduction is already in onboarding-new.css; use effective metrics rather than old 32/37px defaults.

Skip leaves the answer empty and must not fabricate an acknowledgement. Back clears the previous acknowledgement and returns to the actual preceding flow ID. Name max24, prayer names max60, concern max100 in reference; native Unicode/grapheme handling should avoid splitting user-visible characters. Empty names use “you”/“Your daughter” fallbacks exactly where source specifies. User text is plain text, never markup/HTML. Do not send sensitive prayer/free-text answers as analytics properties.

Persist prayer, reminder/time, pace, heart topics and appropriate profile choices into native repositories with clear local/cloud behavior. The browser keeps answers in memory during the flow; process-death/resume and secure persistence are native work. Never re-onboard an existing user after editing Settings. Cancel speech and all pending animations on navigation/interruption.

## Copy/content decisions before release

The “10 years” statement is present in the approved prototype but assumes an unstated lifetime duration. Retain it in the reference; validate the claim or approve clearer qualification before publishing. Onboarding preferences should actually shape For You in production: do not claim personalization if no recommendation mapping is connected. The saved prayer is deterministic copy, not evidence of a live AI model. Optional private questions and reminder consent must remain optional.
