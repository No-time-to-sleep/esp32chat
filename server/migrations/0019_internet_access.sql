-- 0019_internet_access: per-user internet access flags, WiFi uplink config, interface mapping
-- v2: interface assignment (AP vs uplink)

CREATE TABLE IF NOT EXISTS wifi_uplink_config (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    ssid TEXT NOT NULL DEFAULT '',
    connected INTEGER NOT NULL DEFAULT 0,
    last_connected_at_ms INTEGER DEFAULT NULL,
    interface_name TEXT NOT NULL DEFAULT 'wlan1',
    updated_at_ms INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS wifi_interface_map (
    ifname TEXT PRIMARY KEY,
    role TEXT NOT NULL DEFAULT 'unassigned' CHECK(role IN ('ap','uplink','unassigned')),
    priority INTEGER NOT NULL DEFAULT 0,
    chipset TEXT DEFAULT '',
    tx_power_dbm INTEGER DEFAULT 20,
    assigned_at_ms INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS internet_access (
    user_id INTEGER PRIMARY KEY REFERENCES users(id),
    enabled INTEGER NOT NULL DEFAULT 0,
    bandwidth_limit_kbps INTEGER DEFAULT NULL,
    granted_at_ms INTEGER NOT NULL DEFAULT 0,
    granted_by_admin_user_id INTEGER DEFAULT NULL
);

INSERT OR IGNORE INTO wifi_uplink_config (id, ssid) VALUES (1, '');
