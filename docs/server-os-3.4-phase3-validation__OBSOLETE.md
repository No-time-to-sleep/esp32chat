# Server OS 3.4 — Phase 3 validation report

## Scope validated

- Combo API test harness: `firmware/integration/verify_device_combos.py` covers device login with `client_kind=device`, combo set, correct verify, wrong verify, reset after full re-login, and guest enrollment denial.
- StickC firmware combo additions: `firmware/devices/m5stickc_plus2/m5stickc_plus2.ino` includes button-based combo collection, `/devices/api/combos/set`, `/verify`, `/reset`, local combo gate before normal actions, and full-login reset handling.
- Cardputer combo plan: `docs/server-os-3.4-cardputer-combo-plan.md` documents keyboard sequence capture, actions-array mapping, verify/reset flow, exact firmware changes, and bootloader/COM blocker.
- Firmware profiles: `m5stickc_plus2.json`, `m5cardputer_client.json`, `m5cardputer_adv.json`, `t_embed_cc1101.json`, and `flipper_zero.json` now carry phase 1-2 combo/media/voice/file/edge capability flags.

## Alignment with `server_os_3.4.txt`

- Device action combos: aligned with section 3.3; combos are minimum 3 actions, device-bound, reset only after full login, and hardware clients must not use guest sessions.
- Voice/media limits: aligned with device sections 4.6-4.10 and the conservative policy; all new voice/media/download/upload flags remain false until storage, transport, and audio path are proven.
- Roles: M5Cardputer and M5StickC remain text/chat/blog clients; T-Embed remains text/buffered client with encoder path planned; Flipper remains limited and unconfirmed until network/FAP path is validated.

## Implemented now

- Server/API-side combo flow has a host harness for set/verify/reset/guest-deny validation.
- M5StickC Plus2 firmware contains concrete combo UX and API calls.
- Profiles declare truthful phase 1-2 capability flags without promoting clients to edge/server roles.
- Cardputer implementation path is documented but not flashed.

## Built and flashed

- M5StickC Plus2 firmware was built and flashed in previous steps.
- Previous step context reports: `03-stickc-build` ok and `04-stickc-flash` ok.

## Documentation-only / not hardware-validated

- M5Cardputer combo support is plan-only; firmware source exists but needs code changes and hardware flashing later.
- T-Embed combo support is profile-level only until device is connected and firmware implements encoder/button combo calls.
- Flipper combo support is not confirmed; profile keeps new `supports_device_action_combo` and `supports_combo_verify` false until Wi-Fi/dev-board/FAP behavior is proven.
- Media attachments, media download, voice record/playback, file upload are policy-gated false on the reviewed client profiles.

## Known hardware blockers

- Cardputer: no serial COM port visible; only USB/HID `VID_30FA`, so it cannot be flashed until the user puts it into serial/bootloader mode.
- T-Embed: not connected/validated in this phase.
- Flipper Zero: not connected/validated in this phase.

## Exact Raspberry Pi verification commands

Run on the Raspberry Pi or on a host that can reach the Pi server:

```bash
cd /opt/local-chat-server
export LOCAL_CHAT_SERVER_URL="http://127.0.0.1:18080"
export LOCAL_CHAT_DEVICE_LOGIN="device"
export LOCAL_CHAT_DEVICE_PASSWORD="devicepass"
export LOCAL_CHAT_DEVICE_ID="phase3-stickc-plus2-verify"
export LOCAL_CHAT_COMBO_ACTIONS="a,b,pwr"
export LOCAL_CHAT_WRONG_COMBO_ACTIONS="a,pwr,b"
python3 firmware/integration/verify_device_combos.py
```

If the repo path differs on the Pi, run the same script from the deployed project directory and adjust `LOCAL_CHAT_SERVER_URL` to the active API port.

## Proposed phase 4 plan

1. RFID hardware decision: verify PN532 wiring/transport, define card UID storage policy, and implement M5Tab/admin enrollment and deletion flow without banking-grade claims.
2. M5Tab firmware: implement structured API-driven HMI tabs `Сведения`, `Админ-панель`, and `Развёртывание`; no Raspberry Pi video streaming.
3. ESP32-S3 edge provisioning: define limited edge-node profile, provisioning API, node discovery, heartbeat, event queue, and safe disable path.
4. Cardputer firmware implementation: add keyboard combo code from the plan, build with PlatformIO, then flash only after serial/bootloader COM port is visible.
5. T-Embed/Flipper validation: connect hardware, implement or reject combo support based on real input/network path, and update profiles accordingly.

## Worker Result
Validated phase 3 state and documented implemented, flashed, pending, blocked, verification, and phase 4 items.
