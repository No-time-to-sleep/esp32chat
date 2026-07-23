#!/bin/bash
# RPi2 Client setup — получает интернет от RPi1 через eth0
set -e

echo "=== RPi2 Client ==="

# 1. Выключить hostapd (AP)
sudo systemctl stop hostapd 2>/dev/null || true
sudo systemctl disable hostapd 2>/dev/null || true

# 2. Выключить WiFi (wlan0)
sudo ip link set wlan0 down 2>/dev/null || true

# 3. Настроить eth0 — получать IP от RPi1
sudo ip link set eth0 up
sudo dhclient eth0 2>/dev/null || sudo dhcpcd eth0 2>/dev/null || \
  sudo ip addr add 192.168.2.2/24 dev eth0

# 4. Шлюз по умолчанию → RPi1
sudo ip route add default via 192.168.2.1 2>/dev/null || true

# 5. Проверить соединение
echo "=== Проверка ==="
ping -c 2 -W 3 192.168.2.1 2>/dev/null && echo "RPi1 доступен" || echo "RPi1 не отвечает"
ping -c 2 -W 3 8.8.8.8 2>/dev/null && echo "Интернет есть" || echo "Интернета нет"

echo "RPi2: 192.168.2.2 (eth0)"
echo "LC сервер: http://192.168.2.2:18080"
