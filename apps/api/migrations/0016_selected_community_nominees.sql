-- Preserve prior ballots. The revised shortlist uses a separate -charities-v2 round.
CREATE TABLE community_votes_selected (
 user_id TEXT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
 round_id TEXT NOT NULL,
 cause_id TEXT NOT NULL CHECK(cause_id IN ('safe','girls','mothers','church','dress-for-success','camfed','womens-aid','educate-girls','mercy-multiplied','sharing-the-mission','house-of-grace','meninadanca')),
 updated_at INTEGER NOT NULL,
 PRIMARY KEY(user_id, round_id)
);
INSERT INTO community_votes_selected SELECT user_id,round_id,cause_id,updated_at FROM community_votes;
DROP TABLE community_votes;
ALTER TABLE community_votes_selected RENAME TO community_votes;
