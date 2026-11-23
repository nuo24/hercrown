# Sequential Faith Medal stages

November 23, 2026. Owner requested one active medal per collection, with separate reading for each goal. Supersedes cumulative progress in 0019/0017; artwork, icon tiles, selection haptics and thresholds remain unchanged. Onboarding tap-to-finish is explicitly on hold for a decision and remains unchanged.

Each collection progresses independently in catalog order. Love requires 14 reading days and 14 distinct chapters; Joy then requires another 21 reading days and 21 distinct chapters. All activity on the award's local day belongs to that award; the next stage begins on the next reading day. No surplus days, chapters or books are banked. A complete reread in a later stage can count again; duplicate chapter completions within one stage cannot.

Armor retains its 1/3/5/10/20/40 complete-book goals and 21/30/45/60/90/180 reading-day requirements. Every chapter of a qualifying book must be read within the active Armor stage. Psalms, Women and Promises follow the same sequence, retaining their specific books/journeys. Their exact requirements remain visible.

The Worker deterministically replays account-scoped local reading days and chapter-end events chronologically. It combines legacy first-completion rows with daily chapter-end reports, validates canonical references and excludes unmarked chapters/future dates. Ordinary verse-view events never qualify as chapter completion. No schema or production data migration is needed. Reader reports chapter ends again on subsequent reading days to support rereading.

The native client consumes server stage counters and retains original art. Later medals stay locked with zero counters until their predecessors finish. Older payloads fail closed for later medals. Award-cache rules v4 clears obsolete locally detected award dates; recalculation uses verified reading, not invented dates. Existing reading history is never erased. Existing faith_medal_earned/viewed/selected events remain.

Ship only after API/native tests, running Simulator inspection and staging rollout. Build 36 already uploaded cannot be modified; these changes require a subsequent TestFlight build. No public/production deployment is authorized by this decision.
