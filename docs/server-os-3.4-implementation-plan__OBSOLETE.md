# Server OS 3.4 Implementation Plan

This plan follows `server_os_3.4.txt` while explicitly preserving the current RPi-only/deprecated context until the architecture conflict is resolved.

## Conflict note

`server_os_3.4.txt` requires active PN532 RFID, M5Tab HMI, internal ESP32/M5Stamp/Atom service controllers, and up to four auxiliary edge nodes. Current project context (`project_agents.md`, `docs/architecture.md`, `docs/mvp-scope.md`) says v1.00.00 is **RPi-only** and marks those internal modules/RFID/M5Tab paths deprecated or disabled. Safe implementation must therefore:

1. avoid re-enabling deprecated hardware by accident;
2. implement server-side primitives behind capability/profile gates;
3. require an explicit architecture decision before M5Tab/RFID/edge nodes become active or hard-critical.

## Phase 1 — Safe backend primitives

- Add media attachment schema/service/API for image/audio/generic files on Raspberry Pi storage.
- Link attachment metadata to chat/support messages without breaking text-only clients.
- Enforce filename sanitization, MIME allowlist, file size limits, ownership and session checks.
- Keep audio as stored attachment only; do not claim hardware voice recording.
- Result after phase: web/API clients can upload and download authorized attachments; existing chat/support remains compatible.

## Phase 2 — Frontend media integration

- Add upload controls to web chat/support pages.
- Render attachment list with type, filename, size and download link.
- Add avatar flow using the same safe storage primitives where possible.
- Result after phase: browser users can send/read attachments; hardware clients may ignore the new field.

## Phase 3 — Capability registry and module discovery foundation

- Add module inventory/criticality schema: hard-critical, soft-critical, optional.
- Add backend service that computes feature availability: RFID, M5Tab HMI, edge-node limit, media capability by client profile, safe shutdown controls.
- Default profile remains RPi-only: deprecated modules are absent but not startup blockers.
- Result after phase: backend can honestly report available functions without enabling deprecated hardware.

## Phase 4 — Device action combinations

- Add per-user/per-device combination records with salted hashes and reset-after-full-login policy.
- Expose firmware-safe API: enroll, verify, reset, status.
- Enforce no guest login for hardware clients.
- Result after phase: hardware clients can use local action combinations without storing plaintext sequences.

## Phase 5 — RFID decision gate

- If architecture decision reactivates PN532: re-enable RFID router under explicit feature flag, add admin policy UI/API, and keep crypto claims modest.
- If RPi-only remains canonical: keep RFID code disabled and document as deprecated.
- Result after phase: no contradiction between active APIs and product architecture.

## Phase 6 — M5Tab and edge nodes decision gate

- If TZ 3.4 hardware scope is restored: implement M5Tab structured-data API tabs: сведения, админ-панель, развёртывание.
- Add edge-node deployment records and safe commands for only discovered Stamp S3 / ESP32-S3 controllers.
- Never let edge nodes replace Raspberry Pi AP/server; limit functions to restricted local profile with event queue.
- If RPi-only remains canonical: expose these only as documentation/backlog.

## Phase 7 — Firmware/client rollout

- Update device profiles and firmware contracts for attachment metadata.
- Keep text-first clients working.
- Enable file/photo/voice only for confirmed device revisions with storage/audio and tested transport.

## Safety rules across all phases

- No commits, no flashing hardware unless explicitly requested.
- Preserve dirty working tree and unrelated changes.
- Add migrations as monotonic SQL files.
- Backward compatibility: existing auth/chat/blog/support/admin APIs must keep their text-only behavior.
- Do not declare field/hardware validation unless it is actually run.
