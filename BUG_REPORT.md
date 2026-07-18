# Bug Report — LC Server (RPi-Only, v1.00.00)

Дата: июль 2026, проверено на реальном деплое (EvilPi5, 10.42.0.2)

---

## Реальные баги (подтверждены)

### 1. Таблица activity_log не создавалась
- **Файл:** `app/services/activity_log.py:16` — метод `_init_table()` нигде не вызывался
- **Симптом:** `GET /chat/api/admin/activity` падал с 500 (no such table: activity_log)
- **Статус:** ✅ ИСПРАВЛЕНО — добавлен `self._init_table(conn)` в `_connect()`

### 2. degraded_mode был включён
- **Таблица:** `ops_runtime_state` — `degraded_mode=1`, `reason='esp32 maintenance dry-run'`
- **Влияние:** `/health` возвращал `degraded_mode: true`
- **Статус:** ✅ ИСПРАВЛЕНО — выключен через `POST /ops/api/degraded-mode {"enabled":false}`

---

## Проблемы UX (функционально API работает)

### 3. Два админ-интерфейса — путаница
- **SPA `#/admin`** (в `app.js` `renderAdmin()`) — встроенная админка с вкладками: Users, Support, Blog, Mode, Cleanup, Activity. Использует `STATE.token` автоматически. **РАБОТАЕТ.**
- **Отдельные HTML-страницы** (`/admin/users/panel`, `/admin/mode/panel`, `/admin/content/panel`) — требуют ручного ввода session token. Это дублирующий интерфейс, который пользователь, скорее всего, и пробовал.
- **Сеть `/admin/network`** — третий вариант, читает `localStorage.getItem('lc_session_token')`.
- **Файлы:** `app.js` (renderAdmin), `static/admin/users/users.js`, `static/admin/mode/mode.js`, `static/admin/content/content.js`

**Рекомендация:** оставить только SPA-админку (`#/admin`), отдельные HTML-страницы убрать или редиректить.

### 4. Support/Support — сессионный токен вручную
- **Файл:** `static/support/support.js:2` — `sessionTokenInput` требует ручного ввода
- **Симптом:** страница `/support` не интегрирована с SPA-авторизацией
- **Примечание:** SPA имеет свою поддержку через `#/support`, которая использует `STATE.token`

### 5. Account — отдельная страница без авто-токена
- **Файл:** `static/account/account.js`
- **Симптом:** требует ручного ввода session token

---

## Работает (вопреки изначальным жалобам)

| Функция | API | Фронтенд |
|---------|-----|----------|
| Регистрация | ✅ `POST /auth/register` | ✅ `app.js` `doRegister()` — форма, логин+пароль+телефон, device_id='web' |
| Логин | ✅ | ✅ |
| Бан/разбан | ✅ `POST /admin/users/{id}/ban`, `/unban` | ✅ в SPA `#/admin` |
| Удаление пользователей | ✅ `DELETE /admin/users/{id}` | ✅ |
| Чистка чата | ✅ `POST /chat/api/admin/full-reset`, `delete-all-chats`, `delete-all-users`, `clear-global`, `clear-blog`, `clear-support` | ✅ вкладка Cleanup |
| Аватар | ✅ `POST /account/api/avatar`, `GET .../avatar` | ✅ |
| Support тикеты | ✅ create, reply, статусы (open/in_progress/resolved/closed) | ✅ вкладка Support |
| Переключение режима | ✅ `POST /admin/mode/set` (open/closed) | ✅ вкладка Mode |
| WiFi AP | ✅ hostapd active, ssid=local-chat, ch1 | ✅ `/admin/network` |
| Прокси (captive portal) | ✅ порт 3128, редирект 302 | ✅ |
| DNS/DHCP | ✅ dnsmasq на :53 | — |
| Media/файлы | ✅ `POST /media/api/attachments` | ❌ нет UI |
| Логи активности | ✅ `GET /chat/api/admin/activity` (после фикса) | ✅ вкладка Activity |

---

## Осталось по желанию пользователя

### Убрать прикрепление файлов из всех мест
- **Файлы:** `app/services/media.py`, `app/api/media.py`, `app/models/media.py`, вызовы `_attach_media_to_message()` в `app/services/support.py`
- **Причина:** не работает UI, пользователь не хочет чинить
- Медиа-загрузка через API работает, но фронтенд не имеет интерфейса для этого

---

## Сеть: что есть и чего нет

- **1 AP:** wlan0, ssid=local-chat — работает
- **1 Uplink:** не настроен (eth0 down, usb0 в gadget mode)
- **Код для multi-AP/uplink есть** в `network_service.py` (`get_ap_ifaces()`, `get_uplink_ifaces()`), но `_restart_network_services()` пишет hostapd.conf только для первого интерфейса
- **wpa_supplicant:** `connect_wifi()` через `wpa_cli`, без сохранения в `wpa_supplicant.conf`
- **iptables:** правила применяются корректно для одного AP
