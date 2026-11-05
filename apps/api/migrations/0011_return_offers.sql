-- Sandbox offer scheduling; one shared rolling impression cap per Her Crown account.
CREATE TABLE return_offers (
  user_id TEXT PRIMARY KEY REFERENCES "user" (id) ON DELETE CASCADE,
  declined_at INTEGER,
  shown_at INTEGER
);
