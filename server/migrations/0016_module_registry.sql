PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS modules (
    id TEXT PRIMARY KEY,
    slug TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    kind TEXT NOT NULL CHECK (kind IN (
        'raspberry_pi',
        'pn532',
        'm5tab',
        'esp32_s3',
        'm5stamp_s3',
        'atom_s3',
        'external_client'
    )),
    transport TEXT NOT NULL CHECK (transport IN (
        'usb_serial',
        'i2c',
        'wifi',
        'ble',
        'internal'
    )),
    criticality TEXT NOT NULL CHECK (criticality IN (
        'hard_critical',
        'soft_critical',
        'optional'
    )),
    status TEXT NOT NULL DEFAULT 'absent' CHECK (status IN (
        'absent',
        'detected',
        'degraded',
        'ok'
    )),
    last_heartbeat_ms INTEGER,
    feature_flags TEXT NOT NULL DEFAULT '{}',
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_modules_kind_status
ON modules(kind, status);

CREATE INDEX IF NOT EXISTS idx_modules_slug
ON modules(slug);

CREATE TABLE IF NOT EXISTS module_detection_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    module_id TEXT NOT NULL,
    detection_method TEXT NOT NULL,
    detected_at_ms INTEGER NOT NULL,
    details TEXT,
    FOREIGN KEY (module_id) REFERENCES modules(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_module_detection_log_module_time
ON module_detection_log(module_id, detected_at_ms DESC);
