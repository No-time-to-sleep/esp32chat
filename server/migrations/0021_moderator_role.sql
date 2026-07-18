-- Allow 'moderator' in users.role CHECK constraint

PRAGMA foreign_keys = OFF;

CREATE TABLE users_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    login TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('guest', 'user', 'moderator', 'admin')),
    status TEXT NOT NULL CHECK (status IN ('active', 'blocked', 'banned')),
    created_at_ms INTEGER NOT NULL,
    updated_at_ms INTEGER NOT NULL,
    phone TEXT,
    registration_device_id TEXT,
    display_name TEXT,
    profile_bio TEXT,
    avatar_path TEXT,
    avatar_updated_at_ms INTEGER
);

INSERT INTO users_new SELECT * FROM users;

DROP TABLE users;
ALTER TABLE users_new RENAME TO users;

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_login ON users(login);

PRAGMA foreign_key_check;
PRAGMA foreign_keys = ON;
