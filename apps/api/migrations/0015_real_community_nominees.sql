-- Retain historical preview votes under their original round IDs.
-- The real shortlist uses a separate -charities-v1 round, so no preview vote is reused.
CREATE TABLE community_votes_real (
 user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
 round_id TEXT NOT NULL,
 cause_id TEXT NOT NULL CHECK(cause_id IN ('safe','girls','mothers','church','dress-for-success','camfed','womens-aid','educate-girls')),
 updated_at INTEGER NOT NULL,
 PRIMARY KEY(user_id, round_id)
);
INSERT INTO community_votes_real SELECT user_id,round_id,cause_id,updated_at FROM community_votes;
DROP TABLE community_votes;
ALTER TABLE community_votes_real RENAME TO community_votes;
