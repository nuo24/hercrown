-- Account-scoped, server-clocked next-day gift. Does not enable a store product or campaign.
CREATE TABLE gift_offers (
  user_id TEXT PRIMARY KEY REFERENCES "user"(id) ON DELETE CASCADE,
  declined_at INTEGER NOT NULL,
  shown_at INTEGER
);
