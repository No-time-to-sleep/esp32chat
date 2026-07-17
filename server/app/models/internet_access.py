from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class WiFiInterfaceRole(str, Enum):
    AP = "ap"
    UPLINK = "uplink"
    UNASSIGNED = "unassigned"


@dataclass
class WiFiInterfaceInfo:
    ifname: str
    role: WiFiInterfaceRole
    priority: int
    chipset: str
    tx_power_dbm: int
    mac_address: str


@dataclass
class InternetAccessRecord:
    user_id: int
    enabled: bool
    bandwidth_limit_kbps: int | None
    granted_at_ms: int
    granted_by_admin_user_id: int | None


@dataclass
class WiFiNetwork:
    ssid: str
    signal_strength: int
    security: str


@dataclass
class WiFiUplinkStatus:
    ssid: str
    connected: bool
    interface_name: str
    ip_address: str | None
