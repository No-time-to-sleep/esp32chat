#!/bin/bash
# Deploy and start LC server on RPi 5
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SERVER_DIR="$HOME/lc-server"

if [ ! -d "$SERVER_DIR" ]; then
    echo -e "${RED}ERROR: $SERVER_DIR not found. Copy server files first.${NC}"
    echo "Run: scp -r server/ pi@192.168.4.1:~/lc-server"
    exit 1
fi

echo -e "${GREEN}[1/3] Setting up Python venv...${NC}"
cd "$SERVER_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -e .

echo -e "${GREEN}[2/3] Seeding test users...${NC}"
if [ -f scripts/seed_test_users.py ]; then
    python scripts/seed_test_users.py
else
    echo -e "${YELLOW}seed_test_users.py not found, skipping.${NC}"
fi

echo -e "${GREEN}[3/3] Installing systemd services...${NC}"
sudo tee /etc/systemd/system/local-chat-server.service > /dev/null <<EOF
[Unit]
Description=LC Chat Server
After=network.target

[Service]
Type=simple
User=gamecat
WorkingDirectory=$SERVER_DIR
Environment=PYTHONUNBUFFERED=1
ExecStart=$SERVER_DIR/venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 18080
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/local-chat-proxy.service > /dev/null <<EOF
[Unit]
Description=LC Chat Transparent HTTP Proxy
After=network.target local-chat-server.service
Wants=local-chat-server.service

[Service]
Type=simple
User=root
WorkingDirectory=$SERVER_DIR
Environment=LC_SERVER_URL=http://192.168.4.1:18080
ExecStart=$SERVER_DIR/venv/bin/python $SERVER_DIR/app/services/http_proxy.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable local-chat-server local-chat-proxy
sudo systemctl restart local-chat-server local-chat-proxy
echo -e "${GREEN}Server and proxy started!${NC}"

echo ""
echo -e "${GREEN}--- Server Ready ---${NC}"
echo "URL:  http://192.168.4.1:18080"
echo "Docs: http://192.168.4.1:18080/docs"
echo "Test: curl http://192.168.4.1:18080/health"
echo "Proxy: systemctl status local-chat-proxy --no-pager"
