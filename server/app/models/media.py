from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class MediaKind(str, Enum):
    IMAGE = "image"
    AUDIO = "audio"
    FILE = "file"


@dataclass(frozen=True)
class MediaAttachment:
    attachment_id: int
    owner_user_id: int
    original_filename: str
    stored_filename: str
    storage_path: str
    mime_type: str
    media_kind: MediaKind
    size_bytes: int
    sha256_hex: str
    created_at_ms: int


@dataclass(frozen=True)
class MediaDownload:
    attachment: MediaAttachment
    absolute_path: str
