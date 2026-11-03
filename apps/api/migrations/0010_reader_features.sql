-- Features from the competitor walkthrough and the design kit: verse notes, library (studied / saved studies),
-- Bible progress, days opened, devotionals, reader preferences (font size, red letters, translation, widget verse,
-- reading position). Every per-person table is deleted with the account and merged when a guest signs in (users.ts).

-- Notes on a verse ("Your Notes · Auto-saved"). Private: never logged or sent to analytics.
CREATE TABLE verse_notes (
  user_id    TEXT NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
  ref        TEXT NOT NULL,
  text       TEXT NOT NULL CHECK (length(text) BETWEEN 1 AND 10000),
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (user_id, ref)
);
CREATE INDEX verse_notes_recent ON verse_notes (user_id, updated_at);

-- Library → "Studied": verses she opened a study tool on.
CREATE TABLE study_history (
  user_id         TEXT NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
  ref             TEXT NOT NULL,
  tool            TEXT NOT NULL CHECK (tool IN ('explain', 'deeper', 'original', 'related')),
  first_viewed_at INTEGER NOT NULL,
  last_viewed_at  INTEGER NOT NULL,
  PRIMARY KEY (user_id, ref, tool)
);
CREATE INDEX study_history_recent ON study_history (user_id, last_viewed_at);

-- Library → "Studies": studies she saved to come back to.
CREATE TABLE saved_studies (
  user_id  TEXT NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
  ref      TEXT NOT NULL,
  tool     TEXT NOT NULL CHECK (tool IN ('explain', 'deeper')),
  saved_at INTEGER NOT NULL,
  PRIMARY KEY (user_id, ref, tool)
);

-- Bible progress: chapters finished, of 1,189.
CREATE TABLE chapter_completions (
  user_id      TEXT NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
  book_id      TEXT NOT NULL REFERENCES books (id),
  chapter      INTEGER NOT NULL,
  local_day    TEXT NOT NULL,
  completed_at INTEGER NOT NULL,
  PRIMARY KEY (user_id, book_id, chapter)
);

-- "Days opened" (vs days read): one row per local day the app was opened.
CREATE TABLE app_open_days (
  user_id   TEXT NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
  local_day TEXT NOT NULL,
  PRIMARY KEY (user_id, local_day)
);

-- Today's Devotional. Only reviewed devotionals are loaded (content/devotionals.json, "approved": true).
CREATE TABLE devotionals (
  id          TEXT PRIMARY KEY,
  position    INTEGER NOT NULL UNIQUE,    -- order of the daily rotation
  title       TEXT NOT NULL,
  ref         TEXT NOT NULL,              -- canonical passage; the text comes from our Bibles
  tag         TEXT NOT NULL,              -- e.g. "Give Thanks"
  minutes     INTEGER NOT NULL,
  body        TEXT NOT NULL,
  reflection  TEXT NOT NULL,
  origin      TEXT NOT NULL,              -- 'ai-draft-reviewed' or 'written'
  sources     TEXT NOT NULL DEFAULT '[]', -- JSON: commentaries the draft drew on
  approved_by TEXT NOT NULL,
  updated_at  INTEGER NOT NULL
);

CREATE TABLE devotional_reads (
  user_id       TEXT NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
  devotional_id TEXT NOT NULL,
  local_day     TEXT NOT NULL,
  read_at       INTEGER NOT NULL,
  PRIMARY KEY (user_id, devotional_id)
);

-- Reader preferences (Settings → General) and state.
ALTER TABLE preferences ADD COLUMN font_size TEXT NOT NULL DEFAULT 'default' CHECK (font_size IN ('default', 'large', 'larger', 'largest'));
ALTER TABLE preferences ADD COLUMN words_of_jesus_red INTEGER NOT NULL DEFAULT 1 CHECK (words_of_jesus_red IN (0, 1));
ALTER TABLE preferences ADD COLUMN translation TEXT NOT NULL DEFAULT 'kjv';
ALTER TABLE preferences ADD COLUMN widget_ref TEXT;          -- "Widget Verse"; NULL = verse of the day
ALTER TABLE preferences ADD COLUMN position_ref TEXT;        -- bookmark: where she left off reading
ALTER TABLE preferences ADD COLUMN position_updated_at INTEGER;

-- Support replies: rate limiting and delivery status.
ALTER TABLE support_requests ADD COLUMN delivered_at INTEGER; -- emailed to the team inbox
