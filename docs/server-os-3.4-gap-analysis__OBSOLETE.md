# Server OS 3.4 Gap Analysis

Active spec: `server_os_3.4.txt`. Current baseline: `project_agents.md`, `docs/mvp-scope.md`, `docs/architecture.md`, `docs/device-matrix.md` describe v1.00.00 RPi-only, with internal controllers/RFID/M5Tab marked deprecated or inactive.

## Summary matrix

| Area | Status | Gap / conflict | Action |
| --- | --- | --- | --- |
| Backend core | Partial | FastAPI, SQLite migrations, auth, chat, blog, support, devices, admin mode, security baseline and ops services exist. Media attachment storage and active module discovery/edge orchestration are incomplete. | Add attachment service/API first; then capability registry, edge-node policies, full admin surfaces. |
| Frontend web | Partial | Core pages exist for chat/support/etc., but Server OS 3.4 wants complete portal UX: account avatars, device firmware/instructions, admin module/edge controls, closed/open captive landing behavior. | Keep existing pages working; incrementally add media UI, devices tab details, admin capability screens. |
| Firmware / clients | Partial | Firmware folders and profiles exist, but hardware validation is pending; compact clients are text-first. | Preserve honest limits; add media only to profiles with confirmed storage/audio. |
| Media/files/images/voice | Missing/partial | Storage layout has `media`, `avatars`, `uploads`; account avatar model exists, but generic chat/support attachments and voice metadata are missing. Hardware clients cannot be assumed to record voice. | Implement server-side stored attachments for image/audio/generic files; expose capability flags so clients only show supported media features. |
| RFID / PN532 | Conflict/partial | Spec 3.4 requires PN532 RFID access; current v1.00.00 context says RFID/PN532 deprecated/disabled though old server code/migration exists. | Do not silently re-enable. Document policy conflict and gate RFID behind explicit profile/capability decision. |
| M5Tab | Conflict/missing active path | Spec 3.4 requires M5Tab HMI tabs and edge-node deploy control; current context marks M5Tab deprecated/inactive. | If TZ 3.4 wins, reintroduce M5Tab as structured-data HMI only; otherwise leave deprecated. |
| Edge nodes | Conflict/missing active path | Spec 3.4 requires up to 4 auxiliary local deployments on 3x Stamp S3 + ESP32-S3; current context is RPi-only and deprecated internal controllers. | Resolve architecture decision first; implement capability map before any deploy commands. |
| Module discovery | Partial/conflict | Docs describe discovery/capability gating; active backend only has device runtime pieces, not full hardware discovery/criticality enforcement. | Add module inventory table/service and safe hold/degraded state policy. |
| Device action combinations | Partial | Requirements mention per-device local unlock combinations; active code likely has device/user controls but no complete secure combination flow verified here. | Add hashed per-device combination model/API and firmware contract; no guest login on hardware. |
| Device action combinations + auth | Missing/partial | Need binding to concrete hardware device and full password re-login reset flow. | Phase after media/auth slice to avoid auth regressions. |

## Implemented / partial / missing / conflict details

### Backend
- Implemented: FastAPI app factory, SQLite migration system, storage layout, auth/session, mode, chat, private chat, blog, support, account/admin/device/security/ops routes.
- Partial: defensive security is baseline, not audited hardening; support/chat have text messages but no attachment metadata; device runtime exists but not full Server OS 3.4 discovery/edge state machine.
- Missing: generic media attachment API, module criticality table, edge deployment orchestration, complete hardware capability recalculation.
- Conflict: Server OS 3.4 expands active hardware scope while current context constrains the product to RPi-only.

### Frontend
- Implemented/partial: static HTML pages exist for major sections.
- Missing: complete Server OS 3.4 portal behavior, media upload/download UX, admin HMI parity, module/edge visual controls, full device firmware catalog instructions.

### Firmware
- Partial: project structure and docs/profiles exist; hardware acceptance remains pending.
- Missing/conflict: active M5Tab/internal controller firmware is deprecated in current context but required by TZ 3.4.

### Media / files / images / voice
- Partial: storage directories and avatar concepts exist.
- Missing: `media_attachments`, safe upload, message attachment joins, access-checked download.
- Constraint: server may store audio attachments; do not claim M5Stick/Flipper/Cardputer voice recording unless exact hardware audio/storage path is validated.

### RFID
- Partial: old RFID migration/API/service present but router disabled in `main.py`.
- Conflict: TZ 3.4 says PN532 required; current v1.00.00 says RFID deprecated/disabled.

### M5Tab / edge / module discovery
- Missing active implementation under current RPi-only posture.
- Conflict must be resolved before enabling deploy controls or treating M5Tab as hard-critical.

## Highest-risk conflicts
1. **TZ 3.4 vs RPi-only/deprecated context**: TZ 3.4 requires internal controllers, M5Tab, PN532 and edge nodes; current project rules exclude them from active architecture.
2. **Hardware media claims**: TZ 3.4 asks for files/photos/voice on devices where storage/audio may be absent; only server-side attachment storage is safe now.
3. **Critical modules**: TZ 3.4 suggests hold-state for missing critical modules; RPi-only baseline should not block startup on deprecated modules.
