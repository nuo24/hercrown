-- Restore Purchases: log every time a verified restore moves a subscription between accounts.
-- A subscription belongs to an Apple ID; the account that restores it becomes the owner.
CREATE TABLE entitlement_transfers (
  id                      TEXT PRIMARY KEY,
  original_transaction_id TEXT NOT NULL,
  from_user_id            TEXT NOT NULL,
  to_user_id              TEXT NOT NULL,
  reason                  TEXT NOT NULL,      -- 'restore'
  created_at              INTEGER NOT NULL
);
CREATE INDEX entitlement_transfers_otx ON entitlement_transfers (original_transaction_id, created_at);
