-- Member choices are distinct from donations. No payments or sample vote totals.
CREATE TABLE community_votes (
 user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
 round_id TEXT NOT NULL,
 cause_id TEXT NOT NULL CHECK(cause_id IN ('safe','girls','mothers','church')),
 updated_at INTEGER NOT NULL,
 PRIMARY KEY(user_id, round_id)
);
CREATE TABLE community_suggestions (
 id TEXT PRIMARY KEY,
 user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
 name TEXT NOT NULL,
 type TEXT NOT NULL,
 city TEXT NOT NULL DEFAULT '',
 website TEXT NOT NULL DEFAULT '',
 reason TEXT NOT NULL,
 status TEXT NOT NULL DEFAULT 'submitted',
 created_at INTEGER NOT NULL,
 updated_at INTEGER NOT NULL
);
CREATE INDEX community_suggestions_owner ON community_suggestions(user_id, created_at);
