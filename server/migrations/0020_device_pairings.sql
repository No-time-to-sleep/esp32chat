-- 0020_device_pairings: link devices to user accounts
CREATE TABLE IF NOT EXISTS device_pairings (
    device_id TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    device_type TEXT NOT NULL DEFAULT '',
    paired_at_ms INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','revoked'))
);
CREATE INDEX IF NOT EXISTS idx_device_pairings_user ON device_pairings(user_id);
