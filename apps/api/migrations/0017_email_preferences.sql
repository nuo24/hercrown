-- Email-list consent is separate from account identity and payment access.
CREATE TABLE email_preferences (
  user_id TEXT PRIMARY KEY REFERENCES "user"(id) ON DELETE CASCADE,
  subscribed INTEGER NOT NULL CHECK (subscribed IN (0, 1)),
  consent_version TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);
