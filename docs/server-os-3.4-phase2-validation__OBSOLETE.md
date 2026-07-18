# Server OS 3.4 — phase 2 validation

Scope: validates phase-2 backend changes against `server_os_3.4.txt` sections 4.2-4.5, 5, 1.4 and 7. Reviewed files: migrations `0016_module_registry.sql`, `0017_edge_nodes.sql`, `0018_edge_sync_queue.sql`; services/APIs `module_registry`, `module_control`, `discovery`, `edge_nodes`, `deployment`, `sync_queue`, `sync`; and updated `main.py` router wiring.

## Implemented now

- Module registry/data architecture:
  - `modules` and `module_detection_log` tables record module identity, kind, transport, criticality, status, heartbeat, feature flags and detection history.
  - Conservative default registry seeds Raspberry Pi as `hard_critical/ok`; PN532 as `soft_critical/absent`; M5Tab, ESP32-S3, M5Stamp S3, Atom S3 and external clients as optional/absent.
  - `/api/capabilities` computes feature availability and `edge_node_limit` from detected module state.
  - Admin module control endpoints can enable/disable registered modules and gate RFID routing when PN532 is disabled.
- Deployment modes and edge nodes:
  - Raspberry Pi remains the main server/API host; helper controllers are only deployable as limited edge-node records.
  - `edge_node_deployments` stores admin-requested deployments with selected module, SSID placeholder storage, password hash, status, profile JSON, local IP/mDNS and admin user.
  - Edge capacity is recomputed from actual detected M5Stamp S3 + ESP32-S3 modules and capped at 4.
  - APIs exist for M5Tab deployment view and admin start/stop/status: `/api/m5tab/deployment`, `/admin/api/deployment/start`, `/admin/api/deployment/stop`, `/admin/api/deployment/status`, `/devices/api/edge/capabilities`.
- M5Tab structured HMI foundation:
  - `/api/m5tab/info` returns structured JSON for user count, uptime, module status and edge limit; no Pi video-stream design is introduced.
  - `/api/m5tab/admin` returns structured admin summaries for users, support tickets and blog draft count.
- Sync/event data architecture:
  - `sync_event_queue` and `sync_tombstones` tables implement queued edge events, idempotency keys, status, attempts, expiry and conflict metadata.
  - `/sync/api/events`, `/sync/api/events/pending`, `/sync/api/events/{event_id}/ack` support push, pull/mark-sent and ack/conflict flows.
  - Duplicate handling is last-write-wins unless manual conflict markers are present; expired/duplicate events get tombstones.
- Main app integration:
  - `main.py` includes discovery, deployment, edge-node and sync routers; RFID route remains disabled unless PN532 is enabled.

## Validation against TZ 3.4 sections

- 4.2 ESP32-S3 USB-OTG: partially satisfied. It is represented as an optional edge-capable module and counted toward extra local deployments. Watchdog, telemetry, safe-shutdown and USB-OTG service-controller firmware are not implemented yet.
- 4.3 M5Stamp S3: partially satisfied. It is represented as an optional edge-capable module, and edge limits depend on actual detected/usable registry status. Multiple physical Stamp instances are not yet separately seeded; firmware deployment is not yet real.
- 4.4 Atom S3: partially satisfied. It is represented in the registry as an optional USB-serial service/client module, but status indication, emergency panel and quick actions are not implemented yet.
- 4.5 M5Tab: backend foundation is satisfied for structured data and deployment/admin/info tabs. Actual M5Tab firmware/UI rendering and physical admin workflows remain missing.
- 5 Module discovery/degradation: partially satisfied. Criticality/status tables, conservative defaults, capability recomputation, RFID gating and edge-limit degradation exist. Real USB/I2C probing, hard-critical hold-state UX, indicator output and no-error-spam runtime supervision remain missing.
- 1.4 Deployment modes: backend model is mostly satisfied. Raspberry Pi remains primary, extra nodes are admin-requested, limited to Stamp S3/ESP32-S3, capacity is recomputed by detected modules. Actual Wi-Fi provisioning on controllers and limited local web profile are not implemented.
- 7 Data architecture: satisfied for phase 2 backend foundation. SQLite tables now cover module map, deployment records and sync queue/tombstones. Media/files remain filesystem-managed elsewhere; proper encrypted Wi-Fi credential storage is still missing.

## Missing or incomplete

- Real hardware discovery for USB serial/I2C/Wi-Fi heartbeats; current discovery is registry/placeholder based.
- Separate registry rows for all 3 physical M5Stamp S3 units; current default has one generic `m5stamp-s3` row, so max 4 cannot be proven without manual additional rows.
- Firmware protocol to provision SSID/password/profile to ESP32-S3 or M5Stamp S3.
- Actual limited edge-node HTTP/cache profile on ESP32-S3/M5Stamp S3.
- M5Tab firmware screens for Info/Admin/Deployment and 5-second hold server-mode control.
- Atom S3 status/quick-action firmware.
- ESP32-S3 watchdog, telemetry, emergency shutdown and service API firmware.
- Secure credential vault/encryption for Wi-Fi password material; current SSID obfuscation is explicitly a placeholder and password storage is only a hash, not usable for real controller provisioning.
- RPi hold-state policy for missing hard-critical modules beyond conservative capability flags.

## Hardware decision still required

There is a conflict between TZ 3.4 expectations and an RPi-only implementation path: TZ 3.4 requires actual auxiliary controllers for edge deployments, M5Tab HMI, watchdog/telemetry and hardware degradation UX, while current phase 2 is Raspberry-Pi-side schema/API only. Decision needed before phase 3:

- If phase 3 remains RPi-only, mark ESP32-S3/M5Stamp/M5Tab/Atom functions as simulated/backend-only and do not claim real deployment or hardware hold-state.
- If phase 3 targets actual devices, select the first hardware lane: recommended order is M5Tab HMI + one ESP32-S3 edge/service controller, then add three M5Stamp S3 units and Atom S3.

## Exact RPi verification commands

Run from the Raspberry Pi checkout:

```bash
cd /opt/local-chat-server/server
python3 -m app.db.migrate
python3 -m compileall app
uvicorn app.main:app --host 127.0.0.1 --port 8000
```

In another shell:

```bash
curl -s http://127.0.0.1:8000/api/status
curl -s http://127.0.0.1:8000/api/capabilities
curl -s http://127.0.0.1:8000/devices/api/edge/capabilities
curl -s 'http://127.0.0.1:8000/api/m5tab/info'
sqlite3 data/sqlite/local_chat.db '.schema modules'
sqlite3 data/sqlite/local_chat.db '.schema edge_node_deployments'
sqlite3 data/sqlite/local_chat.db '.schema sync_event_queue'
curl -s -X POST http://127.0.0.1:8000/sync/api/events \
  -H 'Content-Type: application/json' \
  -d '{"event_type":"phase2.verify","payload":{"value":1},"source_node_id":"rpi","target_node_id":"esp32-s3-edge"}'
curl -s 'http://127.0.0.1:8000/sync/api/events/pending?target_node_id=esp32-s3-edge&limit=10'
```

For admin-only endpoints, first obtain a valid admin `session_token`, then verify:

```bash
ADMIN_TOKEN='paste-admin-session-token-here'
curl -s "http://127.0.0.1:8000/admin/api/modules?session_token=${ADMIN_TOKEN}"
curl -s -X POST http://127.0.0.1:8000/admin/api/modules/enable \
  -H 'Content-Type: application/json' \
  -d "{\"session_token\":\"${ADMIN_TOKEN}\",\"module_slug\":\"esp32-s3\"}"
curl -s "http://127.0.0.1:8000/devices/api/edge/capabilities"
curl -s -X POST http://127.0.0.1:8000/admin/api/deployment/start \
  -H 'Content-Type: application/json' \
  -d "{\"session_token\":\"${ADMIN_TOKEN}\",\"module_id\":\"esp32-s3\",\"ssid\":\"test-lan\",\"password\":\"test-password\",\"profile_options\":{\"mdns_name\":\"edge-esp32-s3.local\"}}"
curl -s "http://127.0.0.1:8000/admin/api/deployment/status?session_token=${ADMIN_TOKEN}"
```

## Proposed phase 3 plan: firmware action-combo enrollment on actual devices

1. Define a shared firmware enrollment state machine: full login token received, collect minimum 3 local actions, send `device_id + actions` once to `POST /devices/api/combos/set`, clear plaintext from RAM, then use `POST /devices/api/combos/verify` for unlock.
2. Implement first on M5Cardputer because keyboard input is easiest to validate and maps directly to TZ 3.4 combo examples.
3. Add M5StickC Plus2 button-combo profile with A/B/C and long-press escape; keep it text/blog only.
4. Add T-Embed encoder/button profile; validate encoder event normalization before enabling combo set/verify.
5. Add Flipper app/dev-board profile only if real network transport is available; otherwise document tethered/offline limitation.
6. Add server-side hardware verification script that enrolls, verifies, rejects wrong combo, resets after full login and confirms guest sessions cannot enroll.
7. After combo flow is stable, connect M5Tab deployment UI to real ESP32-S3 provisioning and then extend to individual M5Stamp S3 modules.

## Worker Result
Created phase 2 validation report for Server OS 3.4.
