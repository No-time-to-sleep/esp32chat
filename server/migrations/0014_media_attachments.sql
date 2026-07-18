PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS media_attachments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    owner_user_id INTEGER NOT NULL,
    original_filename TEXT NOT NULL,
    stored_filename TEXT NOT NULL,
    storage_path TEXT NOT NULL UNIQUE,
    mime_type TEXT NOT NULL,
    media_kind TEXT NOT NULL CHECK (media_kind IN ('image', 'audio', 'file')),
    size_bytes INTEGER NOT NULL CHECK (size_bytes >= 0),
    sha256_hex TEXT NOT NULL,
    created_at_ms INTEGER NOT NULL,
    FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_media_attachments_owner
ON media_attachments(owner_user_id, created_at_ms DESC, id DESC);

CREATE TABLE IF NOT EXISTS chat_message_attachments (
    message_id INTEGER NOT NULL,
    attachment_id INTEGER NOT NULL,
    position INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (message_id, attachment_id),
    FOREIGN KEY (message_id) REFERENCES chat_messages(id) ON DELETE CASCADE,
    FOREIGN KEY (attachment_id) REFERENCES media_attachments(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_chat_message_attachments_attachment
ON chat_message_attachments(attachment_id);

CREATE TABLE IF NOT EXISTS support_message_attachments (
    message_id INTEGER NOT NULL,
    attachment_id INTEGER NOT NULL,
    position INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (message_id, attachment_id),
    FOREIGN KEY (message_id) REFERENCES support_messages(id) ON DELETE CASCADE,
    FOREIGN KEY (attachment_id) REFERENCES media_attachments(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_support_message_attachments_attachment
ON support_message_attachments(attachment_id);
