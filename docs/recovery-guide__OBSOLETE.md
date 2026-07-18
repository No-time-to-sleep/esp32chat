# Server OS 3.4 — Recovery Guide и Таблица Рисков

## Команды для восстановления работы

### 1. Полный перезапуск сервера
```bash
sudo systemctl restart hostapd
sudo systemctl restart local-chat-server
sudo systemctl restart local-chat-proxy
```

### 2. Если captive portal не работает
```bash
# Сбросить iptables
sudo iptables -t nat -F PREROUTING
sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 80 -j REDIRECT --to-port 3128
# Сохранить правила
sudo tee /etc/iptables/rules.v4 << EOF
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A PREROUTING -i wlan0 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 3128
COMMIT
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
EOF
sudo systemctl restart netfilter-persistent
```

### 3. Если Wi-Fi сеть пропала
```bash
sudo systemctl restart hostapd
sudo systemctl restart dnsmasq
# Проверить статус
systemctl status hostapd dnsmasq
# Проверить SSID
grep ssid /etc/hostapd/hostapd.conf
```

### 4. Если база данных повреждена
```bash
cd /home/gamecat/lc-server
cp data/sqlite/local_chat.db data/sqlite/local_chat.db.bak
sqlite3 data/sqlite/local_chat.db "PRAGMA integrity_check;"
python -c "from app.db.migrate import main; main()"
```

### 5. Если сервер не стартует
```bash
# Смотреть логи
sudo journalctl -u local-chat-server -n 50 --no-pager
# Проверить Python
cd /home/gamecat/lc-server && python -m compileall app
# Перезапустить
sudo systemctl restart local-chat-server
```

### 6. Полный сброс сервера (без потери данных)
```bash
sudo systemctl stop local-chat-server local-chat-proxy hostapd dnsmasq
sudo iptables -t nat -F PREROUTING
sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 80 -j REDIRECT --to-port 3128
sudo systemctl start dnsmasq hostapd local-chat-proxy local-chat-server
```

### 7. Сменить канал Wi-Fi (если глушит роутер)
```bash
sudo systemctl stop hostapd
sudo sed -i 's/^channel=.*/channel=1/' /etc/hostapd/hostapd.conf
sudo iw dev wlan0 set txpower fixed 1000
sudo systemctl start hostapd
```

## Таблица Рисков

| Риск | Вероятность | Влияние | Профилактика | Восстановление |
|---|---|---|---|---|
| Сбой питания RPi | Высокая | Полный останов | Повербанк с защитой | systemd auto-start, команда 1 |
| Повреждение БД | Средняя | Потеря данных | Регулярные бэкапы: `cp local_chat.db local_chat.db.bak` | Команда 4 |
| iptables сбросились | Высокая | Captive portal не работает | Сохранены в `/etc/iptables/rules.v4`, `netfilter-persistent` enabled | Команда 2 |
| hostapd упал | Средняя | Wi-Fi пропал | Auto-restart: `Restart=always` в systemd | Команда 3 |
| Прокси упал | Средняя | Не работает перенаправление | Auto-restart | Команда 1 |
| Диск заполнен | Низкая | Отказ сервера | Ротация логов: `/etc/logrotate.d/local-chat-server` | `journalctl --vacuum-size=100M` |
| Перегрев RPi | Средняя | Троттлинг CPU | Радиатор/вентилятор, `vcgencmd measure_temp` | Перезагрузка |
| DNS перестал работать | Низкая | Нет резолва имён | dnsmasq auto-restart | Команда 3 |
| Сетевой интерфейс потерял IP | Средняя | Нет доступа | Постоянный IP в `/etc/dhcpcd.conf` или NM | `sudo nmcli con up "Wired connection 1"` |
| Пользователь забыл пароль | Высокая | Нет входа | Запомнить admin / 7428 | Сброс через БД: см. команду ниже |

## Сброс пароля админа
```bash
cd /home/gamecat/lc-server
python3 -c "
import sqlite3, hashlib, secrets
pwd = input('New password: ')
salt = secrets.token_hex(16)
h = hashlib.pbkdf2_hmac('sha256', pwd.encode(), salt.encode(), 210000).hex()
c = sqlite3.connect('data/sqlite/local_chat.db')
c.execute('UPDATE users SET password_hash=? WHERE id=2', (f'pbkdf2_sha256\$210000\${salt}\${h}',))
c.commit(); c.close()
print('Done')
"
```

## Быстрая диагностика
```bash
echo "=== UPTIME ===" && uptime
echo "=== TEMP ===" && vcgencmd measure_temp
echo "=== DISK ===" && df -h / | tail -1
echo "=== SERVICES ===" && systemctl is-active local-chat-server local-chat-proxy hostapd dnsmasq
echo "=== IPTABLES ===" && sudo iptables -t nat -L PREROUTING -n | grep -E "3128|18080"
echo "=== SSID ===" && grep ssid /etc/hostapd/hostapd.conf
echo "=== PORTAL ===" && curl -s --max-time 3 -H "Host: test.local" http://127.0.0.1:3128/ | head -c 100
```
