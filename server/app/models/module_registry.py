from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum


class ModuleKind(str, Enum):
    RASPBERRY_PI = "raspberry_pi"
    PN532 = "pn532"
    M5TAB = "m5tab"
    ESP32_S3 = "esp32_s3"
    M5STAMP_S3 = "m5stamp_s3"
    ATOM_S3 = "atom_s3"
    EXTERNAL_CLIENT = "external_client"


class ModuleTransport(str, Enum):
    USB_SERIAL = "usb_serial"
    I2C = "i2c"
    WIFI = "wifi"
    BLE = "ble"
    INTERNAL = "internal"


class ModuleCriticality(str, Enum):
    HARD_CRITICAL = "hard_critical"
    SOFT_CRITICAL = "soft_critical"
    OPTIONAL = "optional"


class ModuleStatus(str, Enum):
    ABSENT = "absent"
    DETECTED = "detected"
    DEGRADED = "degraded"
    OK = "ok"


@dataclass(frozen=True)
class ModuleInfo:
    id: str
    slug: str
    display_name: str
    kind: ModuleKind
    transport: ModuleTransport
    criticality: ModuleCriticality
    status: ModuleStatus
    last_heartbeat_ms: int | None = None
    feature_flags: dict[str, object] = field(default_factory=dict)
    notes: str | None = None
