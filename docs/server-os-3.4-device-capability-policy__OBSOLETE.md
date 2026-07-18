# Server OS 3.4 device capability policy

> **RPi-Only architecture (v1.00.00+).** Из главного блока остаётся только Raspberry Pi 5.
> Все внутренние контроллеры (ESP32-S3, M5Stamp S3, Atom S3, M5Tab, PN532/RFID, Cardputer Console)
> помечены **DEPRECATED**. Код сохранён, но не используется в активной архитектуре.
> Функции module_registry, edge_nodes, deployment, sync_queue, RFID gate, M5Tab API
> реализованы для полноты ТЗ 3.4, но **не активны в RPi-only режиме**.
>
> Активные устройства: M5Cardputer Client, M5StickC Plus2, T-Embed CC1101, Flipper Zero.

This policy records honest device capabilities. Raspberry Pi 5 remains the single server and media store; external devices are text-first clients only.

## Global rules

- Hardware devices must never authenticate as guests. A user must complete normal login first, then bind a device-specific action combination.
- Device combinations are local UX shortcuts, not primary credentials. Server storage must keep only salted password-hash-style combo material, bound to `user_id + device_id`; plaintext sequences are forbidden.
- Files/photos/voice are allowed only where the concrete device revision has storage, memory, audio path and network bandwidth for it. Otherwise the MVP is text, short reactions, notifications and blog reading.
- I²C is reserved for short in-box service data: heartbeat, telemetry, status and peripheral signals. It must not carry files, photos, voice, logs or chat media.
- Additional local network nodes may run only on detected Stamp S3 / ESP32-S3 controllers and only as limited profiles, never as Raspberry Pi replacements.

## Capability matrix

| Device/module | Real role in TZ 3.4 | Chat/blog | Files/photos | Voice/audio | Main limitations |
|---|---|---:|---:|---:|---|
| M5Cardputer | Built-in service console or external keyboard client. | Yes, text-first. | Only if the used revision has usable microSD/storage and firmware implements bounded upload/download. No I²C media. | Possible only as small buffered audio if firmware/audio path proves reliable; otherwise no. | Small screen, limited RAM, keyboard UX, media depends on actual storage. |
| M5Cardputer Adv | Same codebase as Cardputer unless a verified hardware profile exposes extra storage/audio. | Yes. | Same as profile; do not assume extra media. | Same as profile. | Treat as Cardputer profile until hardware delta is verified. |
| M5StickC Plus2 | Lightweight client. | Yes, text/blog summaries. | No practical photo/file client in baseline without storage. | Only if microphone/speaker path and buffering are validated; MVP is reactions. | Tiny display/buttons, RAM/storage limits, weak media UX. |
| T-Embed CC1101 | Text client/control panel; CC1101 is not Internet transport. | Yes over Wi-Fi/BLE/USB profile, not CC1101 chat backbone. | Only small binary attachments if storage/channel verified. | Not baseline. | Encoder UX, storage uncertainty, sub-GHz legal/regulatory constraints. |
| Flipper Zero | Lightweight client/service app. | Yes only with Wi-Fi dev board or tethered bridge; otherwise offline/limited. | Do not promise photos/files without external storage and network model. | No baseline voice. | No built-in Wi-Fi, limited app environment, must not be treated as mini-server. |
| M5Tab | ~~Local admin HMI~~ **DEPRECATED RPi-Only**. | — | — | — | Код `/api/m5tab/*` сохранён, не активен. |
| ESP32-S3 USB-OTG | ~~Internal service controller~~ **DEPRECATED RPi-Only**. | — | — | — | Код `edge_nodes/deployment` сохранён, не активен. |
| Stamp S3 (x3) | ~~Internal service controller~~ **DEPRECATED RPi-Only**. | — | — | — | Код module_registry строк сохранён, не активен. |
| Atom S3 | ~~Indicator module~~ **DEPRECATED RPi-Only**. | — | — | — | Код сохранён, не активен. |
| PN532 | ~~RFID/NFC~~ **DEPRECATED RPi-Only**. | — | — | — | Код `rfid.py` сохранён, router отключён. |

## Device action combination policy

- Minimum length: 3 actions.
- Examples: Cardputer keys, Stick buttons, T-Embed encoder/button events, Flipper arrows/OK.
- The server stores only PBKDF2-SHA256 hash metadata with a random salt and action count.
- Binding key is the authenticated `user_id` plus a firmware-supplied stable `device_id`.
- Reset requires a valid registered user session after full login; forgotten combos are not recovered.
- Verification failures are counted and temporarily locked after repeated bad attempts.
- Guest sessions and inactive/banned users cannot set, reset or verify hardware combos.

## Phase-1 implementation status

Server-side combo metadata and API foundation are implemented without firmware flashing. Firmware must still be updated later to call these endpoints after normal login and to keep the raw action sequence local/in-memory only.

Endpoints:

- `POST /devices/api/combos/set`
- `POST /devices/api/combos/verify`
- `POST /devices/api/combos/reset`

Each endpoint requires `session_token` and `device_id`; set/verify also require `actions`. The API does not return or store plaintext combinations.
