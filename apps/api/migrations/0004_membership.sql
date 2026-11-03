-- Membership details from Superwall webhooks (App Store subscriptions).

ALTER TABLE entitlements ADD COLUMN will_renew INTEGER NOT NULL DEFAULT 1 CHECK (will_renew IN (0, 1));
ALTER TABLE entitlements ADD COLUMN period_type TEXT;               -- TRIAL | INTRO | NORMAL
ALTER TABLE entitlements ADD COLUMN environment TEXT;               -- PRODUCTION | SANDBOX (App Review purchases are sandbox)
ALTER TABLE entitlements ADD COLUMN last_event_at INTEGER NOT NULL DEFAULT 0;  -- ignore older, out-of-order events

-- Store events we couldn't attach to a user (e.g. purchase made before the app identified the user to Superwall).
-- Kept for reconciliation; never grants anything by itself.
CREATE TABLE unmatched_store_events (
  id                      TEXT PRIMARY KEY,   -- webhook delivery id
  app_user_id             TEXT,
  original_transaction_id TEXT,
  type                    TEXT NOT NULL,
  payload                 TEXT NOT NULL,
  received_at             INTEGER NOT NULL
);
CREATE INDEX unmatched_store_events_otx ON unmatched_store_events (original_transaction_id);
