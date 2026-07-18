PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS edge_node_deployments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    module_id TEXT NOT NULL,
    network_ssid TEXT NOT NULL,
    network_password_hash TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN (
        'requested',
        'provisioning',
        'active',
        'degraded',
        'stopped'
    )),
    local_profile TEXT NOT NULL DEFAULT '{}',
    local_ip TEXT,
    mDNS_name TEXT,
    created_at_ms INTEGER NOT NULL,
    updated_at_ms INTEGER NOT NULL,
    deployed_by_admin_user_id INTEGER NOT NULL,
    FOREIGN KEY (module_id) REFERENCES modules(id) ON DELETE RESTRICT,
    FOREIGN KEY (deployed_by_admin_user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_edge_node_deployments_module_status
ON edge_node_deployments(module_id, status);

CREATE INDEX IF NOT EXISTS idx_edge_node_deployments_updated
ON edge_node_deployments(updated_at_ms DESC, id DESC);
