-- Expand the appearance CHECK without changing any saved preference or onboarding state.
-- No table references preferences; its outgoing user foreign key is preserved.
CREATE TABLE preferences_pink (
  user_id TEXT PRIMARY KEY REFERENCES "user" ("id") ON DELETE CASCADE,
  intention TEXT,
  familiarity TEXT,
  topics TEXT NOT NULL DEFAULT '[]',
  routine TEXT,
  reminders_enabled INTEGER NOT NULL DEFAULT 0 CHECK (reminders_enabled IN (0, 1)),
  reminder_time TEXT NOT NULL DEFAULT '08:00' CHECK (reminder_time GLOB '[0-2][0-9]:[0-5][0-9]'),
  time_zone TEXT,
  appearance TEXT NOT NULL DEFAULT 'dark' CHECK (appearance IN ('light', 'dark', 'system', 'pink')),
  gradient TEXT,
  onboarding_version INTEGER,
  onboarding_completed_at INTEGER,
  updated_at INTEGER NOT NULL,
  font_size TEXT NOT NULL DEFAULT 'default' CHECK (font_size IN ('default', 'large', 'larger', 'largest')),
  words_of_jesus_red INTEGER NOT NULL DEFAULT 1 CHECK (words_of_jesus_red IN (0, 1)),
  translation TEXT NOT NULL DEFAULT 'kjv',
  widget_ref TEXT,
  position_ref TEXT,
  position_updated_at INTEGER
);
INSERT INTO preferences_pink SELECT user_id, intention, familiarity, topics, routine,
 reminders_enabled, reminder_time, time_zone, appearance, gradient, onboarding_version,
 onboarding_completed_at, updated_at, font_size, words_of_jesus_red, translation,
 widget_ref, position_ref, position_updated_at FROM preferences;
DROP TABLE preferences;
ALTER TABLE preferences_pink RENAME TO preferences;
