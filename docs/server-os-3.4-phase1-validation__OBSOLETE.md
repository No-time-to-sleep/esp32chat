# Server OS 3.4 phase 1 validation

Validated against `server_os_3.4.txt` after the phase-1 backend/frontend/media/device-combo slices. No hardware flashing was performed.

## Static checks performed

- `git status --short` — repository has many pre-existing dirty/untracked files. This validation did not commit or clean them. New phase-1 files observed include media API/service/migration from prior slices and this slice's combo policy/API/migration.
- `python -m compileall server\app` — passed; server Python files compile, including `server/app/api/device_combos.py`, `server/app/services/device_combos.py`, and updated `server/app/main.py`.

## Implemented now

- Backend FastAPI/SQLite base already present: auth/session, open/closed mode, applications, chat, private chat, blog, support, account/admin/device catalog, ops/security baseline.
- Media attachment foundation is present from earlier phase-1 work: `server/migrations/0014_media_attachments.sql`, `server/app/api/media.py`, `server/app/services/media.py`, `server/app/models/media.py`.
- Device capability policy added: `docs/server-os-3.4-device-capability-policy.md` documents honest limits for M5Cardputer, M5StickC Plus2, T-Embed, Flipper, M5Tab, ESP32-S3, Stamp S3, Atom S3 and PN532, especially media/voice constraints.
- Device action combination foundation added:
  - `server/migrations/0015_device_combo_hashes.sql` stores per-user/per-device combo hash metadata.
  - `server/app/services/device_combos.py` hashes combos with PBKDF2-SHA256 and random salt, requires at least 3 actions, counts failures, and blocks guests/inactive users.
  - `server/app/api/device_combos.py` exposes `POST /devices/api/combos/set`, `/verify`, `/reset` with session + `device_id` binding.
  - `server/app/main.py` registers the combo router.
- Hardware guest login remains forbidden by existing auth rules and by the combo service guard.

## Still missing against TZ 3.4

- Real hardware discovery map with hard-critical/soft-critical/optional criticality and automatic feature recalculation.
- Active edge-node orchestration for Stamp S3 / ESP32-S3, including deployment records, local profile serving, event queue and sync.
- M5Tab structured-data HMI screens for Сведения / Админ-панель / Развёртывание.
- PN532 RFID activation decision: code exists but RFID router is still disabled in `main.py`; policy conflict with the older RPi-only/deprecated context remains.
- Firmware changes for action-combo enrollment/verification were intentionally not made/flashed in this slice.
- End-to-end API tests and live browser/device tests were not run here.

## Known risks

- The working tree is heavily dirty before/around this validation; unrelated modified firmware/docs/context files must not be attributed to this slice without review.
- Combo reset currently clears server-side combo material after an authenticated session; firmware/UI must force full password login before calling reset.
- Combo verification still requires a valid server session. If future firmware wants offline unlock, a separate local-only design is needed and must not reuse server hashes as plaintext secrets.
- Device media support is policy-gated only; firmware profiles still need real storage/audio validation before exposing files/photos/voice.
- RFID/M5Tab/edge-node features remain architecture-gated because current project context conflicts with TZ 3.4's expanded hardware scope.

## Exact RPi human verification commands

Run on the Raspberry Pi from the deployed repository/server directory:

```bash
cd /opt/local-chat-server/server
python -m compileall app
python -m app.db.migrate
sqlite3 /opt/local-chat-server/data/sqlite/local-chat-server.db '.schema device_combo_hashes'
systemctl restart local-chat-server
systemctl status local-chat-server --no-pager
curl -s http://127.0.0.1:8000/api/status
```

Manual API smoke, replacing credentials/token/device ID:

```bash
TOKEN=$(curl -s -X POST http://127.0.0.1:8000/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"login":"USER","password":"PASSWORD","client_kind":"device"}' | python3 -c 'import sys,json; print(json.load(sys.stdin)["session"]["token"])')

curl -s -X POST http://127.0.0.1:8000/devices/api/combos/set \
  -H 'Content-Type: application/json' \
  -d "{\"session_token\":\"$TOKEN\",\"device_id\":\"m5cardputer-demo-001\",\"actions\":[\"left\",\"right\",\"ok\"]}"

curl -s -X POST http://127.0.0.1:8000/devices/api/combos/verify \
  -H 'Content-Type: application/json' \
  -d "{\"session_token\":\"$TOKEN\",\"device_id\":\"m5cardputer-demo-001\",\"actions\":[\"left\",\"right\",\"ok\"]}"

sqlite3 /opt/local-chat-server/data/sqlite/local-chat-server.db \
  'select user_id, device_id, combo_hash_algorithm, combo_actions_count, length(combo_hash) from device_combo_hashes;'
```

Expected: verification returns `"verified": true`; SQLite output shows hash metadata length, not plaintext actions.

## Proposed phase 2 orchestration plan

1. **Capability registry**: add module inventory tables for Raspberry Pi, PN532, M5Tab, ESP32-S3, Stamp S3, Atom S3 and external clients; include criticality, transport, detected status, last heartbeat and feature flags.
2. **Discovery adapters**: implement read-only discovery for USB-serial, I²C PN532 presence, and configured firmware profiles. Default to absent/degraded without error spam.
3. **RFID gate**: keep PN532 disabled until profile flag enables it; then re-enable router, add admin card enrollment/removal UI, and log modest UID-based decisions.
4. **M5Tab deployment API**: expose structured JSON for Сведения / Админ-панель / Развёртывание; no Pi video streaming.
5. **Edge-node records**: add deployment table for eligible Stamp S3 / ESP32-S3 only, compute max active nodes from discovered hardware, store SSID/profile/status, and require admin session.
6. **Edge sync**: implement event queue with idempotency keys, timestamps and conflict rules before enabling offline writes.
7. **Firmware action combos**: update each client firmware to collect local actions, call set/verify/reset endpoints after full login, never persist plaintext combo server-side, and hide media controls unless device profile confirms storage/audio.
