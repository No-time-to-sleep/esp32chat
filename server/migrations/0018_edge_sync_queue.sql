PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS sync_event_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT NOT NULL,
    payload_json TEXT NOT NULL,
    source_node_id TEXT NOT NULL,
    target_node_id TEXT NOT NULL,
    idempotency_key TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending',
        'sent',
        'acknowledged',
        'conflict',
        'expired'
    )),
    created_at_ms INTEGER NOT NULL,
    last_attempt_at_ms INTEGER,
    attempt_count INTEGER NOT NULL DEFAULT 0,
    expires_at_ms INTEGER,
    conflict_resolution TEXT
);

CREATE TABLE IF NOT EXISTS sync_tombstones (
    event_id INTEGER PRIMARY KEY,
    tombstoned_at_ms INTEGER NOT NULL,
    reason TEXT NOT NULL,
    FOREIGN KEY (event_id) REFERENCES sync_event_queue(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sync_event_queue_target_status
ON sync_event_queue(target_node_id, status, created_at_ms, id);

CREATE INDEX IF NOT EXISTS idx_sync_event_queue_expires
ON sync_event_queue(expires_at_ms);
