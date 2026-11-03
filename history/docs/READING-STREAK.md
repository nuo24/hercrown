# Reading streak

Home greets the demo user with “Hi Nate”. The reading streak shows current consecutive days, best run and a rolling seven-day history. Mark today as read on Home, or Finish today’s reading in a reflection sheet. Each local calendar date counts once. A streak remains active until the day after its last completed day; missing a full day resets the current run while preserving the best run.

Reading dates persist locally under bible-scroll-reading-days-v1, independently of onboarding preferences. No account or server sync is provided. Browser verification recorded today once and confirmed persistence after reload. The preview therefore starts with a one-day streak from verification; no earlier history was seeded.

Test: node --test streak.test.mjs test.mjs reader-scroll.test.mjs. Coverage includes calendar boundaries, DST dates, duplicates, missing days, best run, malformed/future dates and recent history. Browser demo implementation only.
