-- Cost limits only. Prayer requests, answers, names and free text are never stored server-side.
CREATE TABLE onboarding_prayer_limits (
  user_id TEXT NOT NULL REFERENCES "user" (id) ON DELETE CASCADE,
  day TEXT NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (user_id, day)
);
