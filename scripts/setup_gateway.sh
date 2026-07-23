#!/bin/bash
# RPi1 Gateway setup — пробрасывает интернет и порт 18080 на RPi2
set -e

echo "=== RPi1 Gateway ==="

# 1. Поднять eth0 и дать IP
sudo ip addr add 192.168.2.1/24 dev eth0 2>/dev/null || true
sudo ip link set eth0 up

# 2. Включить IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/99-forward.conf > /dev/null

# 3. NAT — раздаём интернет с wlan0 на eth0
sudo iptables -t nat -C POSTROUTING -o wlan0 -j MASQUERADE 2>/dev/null || \
  sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE

# 4. Проброс порта 18080 → RPi2
sudo iptables -t nat -C PREROUTING -p tcp --dport 18080 -j DNAT --to 192.168.2.2:18080 2>/dev/null || \
  sudo iptables -t nat -A PREROUTING -p tcp --dport 18080 -j DNAT --to 192.168.2.2:18080

# 5. Разрешить форвардинг
sudo iptables -C FORWARD -i wlan0 -o eth0 -j ACCEPT 2>/dev/null || \
  sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

sudo iptables -C FORWARD -i eth0 -o wlan0 -j ACCEPT 2>/dev/null || \
  sudo iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT

# 6. Сохранить
sudo netfilter-persistent save 2>/dev/null || sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null

echo "Готово!"
echo "RPi1: 192.168.2.1 (eth0)"
echo "Проброс: порт 18080 → RPi2"
