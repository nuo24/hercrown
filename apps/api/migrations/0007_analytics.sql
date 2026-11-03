-- Analytics identity. Events go to Tinybird (src/events.ts); nothing else about analytics is stored here.
--
-- A person's analytics id stays the same when a guest links Sign in with Apple and gets a new user id,
-- so the funnel (onboarding → paywall → trial → paid) isn't split across two ids. No row means the
-- analytics id is the user id itself.
CREATE TABLE analytics_ids (
  user_id   TEXT PRIMARY KEY REFERENCES "user" ("id") ON DELETE CASCADE,
  person_id TEXT NOT NULL
);
