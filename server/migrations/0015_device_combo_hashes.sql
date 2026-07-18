PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS device_combo_hashes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    combo_hash TEXT NOT NULL,
    combo_hash_algorithm TEXT NOT NULL DEFAULT 'pbkdf2_sha256',
    combo_actions_count INTEGER NOT NULL CHECK (combo_actions_count >= 3),
    failure_count INTEGER NOT NULL DEFAULT 0 CHECK (failure_count >= 0),
    locked_until_ms INTEGER,
    created_at_ms INTEGER NOT NULL,
    updated_at_ms INTEGER NOT NULL,
    verified_at_ms INTEGER,
    reset_at_ms INTEGER,
    UNIQUE(user_id, device_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_device_combo_hashes_device
ON device_combo_hashes(device_id, updated_at_ms DESC);

CREATE INDEX IF NOT EXISTS idx_device_combo_hashes_user
ON device_combo_hashes(user_id, updated_at_ms DESC);
