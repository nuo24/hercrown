-- Trial-ending reminders (src/reminders.ts): push devices, and one row per reminder sent so nobody is reminded twice.

-- An iPhone's APNs token. One token belongs to one account at a time (re-registering moves it).
CREATE TABLE push_devices (
  token       TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
  environment TEXT NOT NULL CHECK (environment IN ('sandbox', 'production')), -- Xcode builds use APNs sandbox
  time_zone   TEXT,                                                           -- IANA, for the date in the message and quiet hours
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL
);
CREATE INDEX push_devices_user ON push_devices (user_id);

CREATE TABLE trial_reminders (
  user_id                 TEXT NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
  trial_ends_at           INTEGER NOT NULL,
  original_transaction_id TEXT,
  devices                 INTEGER NOT NULL, -- devices Apple accepted the push for
  sent_at                 INTEGER NOT NULL,
  PRIMARY KEY (user_id, trial_ends_at)
);
