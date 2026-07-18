# Server OS 3.4 — M5Cardputer keyboard combo enrollment plan

## Current state

- Firmware source exists: `firmware/devices/m5cardputer_client/m5cardputer_client.ino`.
- `platformio.ini` exists at `firmware/devices/m5cardputer_client/platformio.ini`; generated `src/m5cardputer_client.ino.cpp` exists, so the PlatformIO structure is present but should be re-verified before any flash.
- Cardputer is currently not flashable from this host: no serial COM port is visible; only USB/HID `VID_30FA` is visible.
- Do not touch hardware in this phase. Actual flashing requires the user to put the Cardputer into serial/bootloader mode so a COM port appears.

## Existing profile readiness summary

- T-Embed profile already declares `device_action_sequence_login: true`; combo input should use encoder turns plus button presses, but firmware implementation/hardware connection are not confirmed.
- T-Embed media remains conditional on real storage/transport; combo readiness is profile-level only until firmware calls `/devices/api/combos/*`.
- Flipper profile declares directional/OK-style action-login intent via `device_action_sequence_login`, but combo support is not confirmed because network/dev-board and FAP implementation are not validated.

## Keyboard-based combo enrollment flow

1. Boot firmware, connect Wi-Fi, call `/health`.
2. Perform full login with `POST /auth/login` using `client_kind=device`; hardware clients must not use guest sessions.
3. After a valid session is available, enter combo setup/verify screen before normal chat/blog actions.
4. Capture a sequence of at least 3 keyboard actions from Cardputer keys. Normalize each action into a stable string such as `key:enter`, `key:a`, `key:left`, `key:backspace`, not raw scan codes.
5. Map the captured keys to the combo API `actions` array, for example:
   ```json
   {"session_token":"...","device_id":"m5cardputer-client-l3","actions":["key:a","key:s","key:enter"]}
   ```
6. First-time enrollment: call `POST /devices/api/combos/set` with `session_token`, `device_id`, and `actions`.
7. Verification on later use: capture the sequence again and call `POST /devices/api/combos/verify`; only unlock local chat/blog actions when response contains `verified: true`.
8. Wrong combo: show a clear failure state, keep plaintext actions only in RAM, and after repeated failures require full login again.
9. Reset flow: if the user forgot the combo, force full login by login/password, then call `POST /devices/api/combos/reset`; after reset, prompt for a new 3+ action sequence and call `/set`.

## Exact code changes needed in `m5cardputer_client.ino`

1. Add UI state fields mirroring StickC combo UX: `combo_mode`, `combo_step`, dirty/redraw flag, and screen labels for `combo verify`, `combo enroll`, `combo reset`, `combo ok`, `combo fail`.
2. Add runtime state to `DeviceRuntime`: `combo_authenticated_`, `combo_needs_full_relogin_`, `combo_failure_count_`.
3. Gate `begin()`, `loop()`, and manual actions so `run_client_probes()` / `run_client_actions()` only run after `ensure_session()` and `ensure_combo_verified()`.
4. Implement `combo_actions_json(String* actions, int count)` and `combo_payload(String* actions, int count)`.
5. Implement HTTP helpers:
   - `post_combo_set()` -> `POST /devices/api/combos/set`
   - `post_combo_verify()` -> `POST /devices/api/combos/verify`
   - `post_combo_reset()` -> `POST /devices/api/combos/reset`
6. Implement `collect_combo_sequence()` using Cardputer keyboard events from M5Unified/Cardputer input APIs, with timeout, minimum length 3, maximum bounded length such as 8, normalization to stable `key:*` action strings, and no persistent plaintext storage.
7. Add an explicit enrollment shortcut after login, for example a menu item or held key chord, that calls `enroll_combo_now()`.
8. Add `require_full_relogin()` that clears `session_token_`, marks combo as not authenticated, and requires password login before reset.
9. Ensure all login payloads keep `LC_CLIENT_KIND` as `"device"`; this is required because hardware clients are not allowed to authenticate as guests.
10. Add serial logs for `combo_set`, `combo_verify`, `combo_reset`, counts only, never plaintext password values.

## Firmware profile updates required

Update `firmware/profiles/m5cardputer_client.json` and `firmware/profiles/m5cardputer_adv.json` capabilities to declare:

- `supports_device_action_combo: true`
- `supports_combo_verify: true`
- `supports_media_attachments: false` until storage/transport is proven
- `supports_media_download: false`
- `supports_voice_record: false`
- `supports_voice_playback: false`
- `supports_file_upload: false`
- `supports_edge_deployment: false`
- media/voice fields policy-gated by `docs/server-os-3.4-device-capability-policy.md`

`m5cardputer_adv.json` should mirror the Cardputer client capability set until a real hardware delta is verified.

## Verification plan

- Build-only first: from `firmware/devices/m5cardputer_client`, run `pio run` after adding code.
- Host/API validation: run the combo harness against the Raspberry Pi server with `LOCAL_CHAT_SERVER_URL`, `LOCAL_CHAT_DEVICE_LOGIN`, `LOCAL_CHAT_DEVICE_PASSWORD`, and `LOCAL_CHAT_DEVICE_ID` set.
- Hardware validation waits for a visible Cardputer serial COM port; user must enter serial/bootloader mode before `pio run -t upload`.

## Worker Result
Documented Cardputer keyboard combo enrollment, code/profile changes, hardware blocker, and T-Embed/Flipper readiness.
