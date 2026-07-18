# Bug Report — LC Server (RPi-Only, v1.00.00)

Дата: июль 2026
Назначение: для более мощной модели, которая выполнит дебаг после подключения RPi

---

## 1. Регистрация не работает

**Файлы:**
- `server/app/services/registration.py` — RegistrationService
- `server/app/api/auth.py:203` — endpoint `POST /auth/register`

**Признаки:**
- `RegistrationService.register_user()` требует `phone` и `device_id` как обязательные (мин. 1 символ, registration.py:49-52).
- RegistrationService проверяет `AccessMode` через таблицу `mode_state` — если в БД нет записи с `id=1`, возвращается `CLOSED` и регистрация запрещается (код 409, registration.py:54-61).
- Нет endpoint, который показывает пользователю, открыта ли регистрация.
- Фронтенд (login.js) не вызывает `/auth/register`.

---

## 2. Админ-панель: бан/разбан и действия с пользователями

**Файлы:**
- `server/app/api/admin/users.py` — endpoints
- `server/app/services/admin_users.py` — AdminUsersService
- `server/app/static/admin/users/users.js` — фронтенд

**Признаки:**
- Фронтенд требует session_token вручную (users.js:129), нет автоматической привязки к текущей сессии.
- `_resolve_admin_user_id()` (admin/users.py:62) пропускает MODERATOR, но `_require_active_admin()` в сервисе (admin_users.py:385) проверяет только ADMIN — расхождение.
- `ban_user()` не завершает активные сессии забаненного пользователя.
- `delete_user()` делает физическое удаление (`DELETE FROM users`, admin_users.py:369), а не soft-delete.
- `unban_user()` меняет статус на ACTIVE, но не чистит `user_restrictions`.
- `set_role()` запрещает установить ADMIN, но не запрещает снять последнюю роль ADMIN у самого себя.
- Нет endpoints для массовой очистки чата, сообщений или пользователей.
- В `users.js` нет confirm dialog перед опасными действиями, фокус сбрасывается после loadUsers().

---

## 3. Аватар не работает

**Файлы:**
- `server/app/api/account.py` — endpoints (account.py:236-291)
- `server/app/services/account.py` — AccountService
- `server/app/static/account/account.js` — фронтенд

**Признаки:**
- `POST /account/api/avatar` принимает `image_base64` (до 6MB). Фронтенд, скорее всего, не конвертирует файл в base64 или логика сломана.
- `GET /account/api/profile/avatar` возвращает `FileResponse` без проверки существования файла — возможна 500.
- `avatar_url` формируется с session_token в query string (account.py:180-183) — нестандартно.
- Нет валидации размера/типа изображения.
- В шаблоне `account/index.html` неизвестно, есть ли заглушка для аватара.

---

## 4. Support/Тикеты — непонятен lifecycle

**Файлы:**
- `server/app/services/support.py` — SupportService
- `server/app/api/support.py` — endpoints для пользователей
- `server/app/api/admin/content.py` — endpoints для админа
- `server/app/static/support/support.js` — фронтенд
- `server/app/static/admin/content/content.js` — фронтенд админа

**Признаки:**
- Нет автозакрытия тикета если пользователь не отвечает N дней.
- Нет уведомлений для админа о новых тикетах.
- При смене статуса админом пользователь не получает realtime-событие.
- `_attach_media_to_message()` (support.py:395) зависит от медиа-системы, которая не работает.
- Во фронтенде пользователя (`support.js`) нет отображения истории ответов в реальном времени.
- В админке нет подтверждения при закрытии тикета.
- Нет эскалации.

---

## 5. Прикрепление файлов — не работает и не чинится (убрать)

**Файлы:**
- `server/app/services/media.py` — MediaService
- `server/app/api/media.py` — endpoints
- `server/app/services/support.py` — вызовы `_attach_media_to_message()`
- `server/app/models/media.py` — модели
- `server/app/storage/` — storage layout
- Все фронтенды, где есть ссылки на attachments

**Признаки:**
- MediaService не имеет полной имплементации или сломана на уровне storage.
- Фронтенд нигде не предлагает UI для загрузки файлов.
- Endpoints не используются и не тестировались.
- В support.py вызовы `_attach_media_to_message()` упадут, если медиа-система не инициализирована.
- Требование: убрать прикрепление файлов из всех мест — код, фронтенд, модели. Не чинить.

---

## 6. Сеть: не поддерживает более одной AP и более одного uplink

**Файлы:**
- `server/app/services/network_service.py` — NetworkService

**Признаки:**
- `_restart_network_services()` пишет конфиг hostapd только для первого AP-интерфейса (network_service.py:201-209), хотя `get_ap_ifaces()` возвращает список.
- `dnsmasq` конфиг пишет все AP-интерфейсы, но `dhcp-range` один на всех (network_service.py:213-221).
- IP адрес `192.168.4.1/24` назначается на все AP-интерфейсы (network_service.py:231-233) — конфликт.
- `iptables` в `_apply_iptables_rules()` обрабатывает списки AP и uplink, но `ensure_uplink_routing()` (network_service.py:417) работает только с первым uplink.
- `connect_wifi()` (network_service.py:328) использует `wpa_cli` без сохранения в `wpa_supplicant.conf` — после ребута настройки пропадают.

---

## 7. Логи и счётчики подключений не работают

**Файлы:**
- `server/app/services/activity_log.py` — ActivityLogService
- `server/app/api/admin/network.py` — нет endpoint для просмотра логов
- `server/app/static/admin/` — нет UI для логов

**Признаки:**
- `ActivityLogService.get_logs()` и `stats()` существуют (activity_log.py:39-58), но нет API endpoint, который их отдаёт.
- `log()` вызывается при login и register, но не при logout, WebSocket connect/disconnect.
- Нет счётчика активных сессий/WebSocket-подключений.
- `stats()` считает данные, но они нигде не отображаются.
- В админ-панели нет раздела "Logs" или "Activity".

---

## 8. Переключение режимов (OPEN/CLOSED)

**Файлы:**
- `server/app/services/mode.py` — ModeService
- `server/app/api/admin/mode.py` — endpoints (mode.py:96-136)
- `server/app/static/admin/mode/mode.js` — фронтенд

**Признаки:**
- `admin/mode.py:125` вызывает `auth.revoke_all_sessions_except(admin_user_id)` — этого метода, скорее всего, нет в AuthService (ошибка маскируется `catch Exception: pass`).
- После переключения в CLOSED существующие WebSocket-соединения не закрываются.
- `safe_sequence` (admin/mode.py:63) — просто список строк, реальные шаги не выполняются.
- Нет confirm dialog на фронтенде перед переключением режима.
- Нет логирования события переключения режима.

---

## Архитектурные проблемы (общие)

1. **Нет единого middleware для проверки сессии** — каждый router дублирует код `_resolve_user_id()`, `_resolve_admin_user_id()`.
2. **Session token в query string** — небезопасно. Нужен заголовок Authorization.
3. **Нет WebSocket аутентификации** — WebSocket handler не проверяет session_token.
4. **`can_access_admin_features()`** — вызывается в admin/content.py:86 и admin/mode.py:49, но этого метода нет в модели User — будет `AttributeError`.
5. **Сессии не чистятся** — нет фоновой задачи для удаления просроченных сессий.
