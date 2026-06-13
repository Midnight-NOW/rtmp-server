#!/bin/bash

# RTMP Server Setup Script for Ubuntu
# Run this script with: bash scripts/setup.sh

set -e

echo "==============================================="
echo "     RTMP Server Setup for Ubuntu"
echo "==============================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
   echo "Please run this script as root (use sudo)"
   exit 1
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1: Update System${NC}"
apt-get update
apt-get upgrade -y

echo -e "${YELLOW}Step 2: Install Dependencies${NC}"
apt-get install -y \
    build-essential \
    libpcre3 libpcre3-dev \
    zlib1g zlib1g-dev \
    libssl-dev \
    libgd-dev \
    libgeoip-dev \
    wget \
    curl \
    git \
    ffmpeg \
    htop

echo -e "${YELLOW}Step 3: Create nginx user${NC}"
useradd -r -M -s /sbin/nologin nginx || true

echo -e "${YELLOW}Step 4: Download nginx and RTMP module${NC}"
cd /tmp
wget -q http://nginx.org/download/nginx-1.25.3.tar.gz
tar -xzf nginx-1.25.3.tar.gz
cd nginx-1.25.3

echo -e "${YELLOW}Step 5: Clone RTMP module${NC}"
cd /tmp
git clone https://github.com/arut/nginx-rtmp-module.git

echo -e "${YELLOW}Step 6: Compile nginx with RTMP${NC}"
cd /tmp/nginx-1.25.3

./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --with-http_gzip_static_module \
    --with-http_v2_module \
    --with-http_ssl_module \
    --with-http_realip_module \
    --add-module=/tmp/nginx-rtmp-module

make
make install

echo -e "${YELLOW}Step 7: Create systemd service${NC}"
cat > /etc/systemd/system/nginx.service << 'EOF'
[Unit]
Description=Nginx HTTP Server
After=network.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

echo -e "${YELLOW}Step 8: Create streaming directories${NC}"
mkdir -p /var/streaming/{hls,dash,vod,recordings,www}
chown -R nginx:nginx /var/streaming
chmod -R 755 /var/streaming

echo -e "${YELLOW}Step 9: Configure Firewall${NC}"
ufw allow 22/tcp || true
ufw allow 80/tcp || true
ufw allow 443/tcp || true
ufw allow 1935/tcp || true

echo -e "${YELLOW}Step 10: Start nginx service${NC}"
systemctl daemon-reload
systemctl enable nginx
systemctl start nginx

echo ""
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}     RTMP Server Installation Complete!${NC}"
echo -e "${GREEN}===============================================${NC}"
echo ""
echo "Server Status: $(systemctl is-active nginx)"
echo "Listening on:"
echo "  - RTMP: Port 1935"
echo "  - HTTP: Port 80"
echo ""
echo "Next steps:"
echo "1. Update nginx.conf with your settings"
echo "2. Restart nginx: sudo systemctl restart nginx"
echo "3. Check stats: curl http://localhost/stat"
echo ""
echo "For more information, see README.md"
echo ""
