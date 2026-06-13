# Manual Installation Guide for Ubuntu Server

This guide covers installing the RTMP server directly on Ubuntu without Docker.

## Prerequisites

- Ubuntu 20.04 LTS or later
- sudo access
- 2GB RAM minimum
- 10GB disk space minimum

## Step 1: Update System

```bash
sudo apt update
sudo apt upgrade -y
```

## Step 2: Install Dependencies

```bash
sudo apt install -y \
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
```

## Step 3: Create System User

```bash
sudo useradd -r -M -s /sbin/nologin nginx
```

## Step 4: Download and Compile Nginx with RTMP Module

### Download Nginx

```bash
cd /tmp
wget http://nginx.org/download/nginx-1.25.3.tar.gz
tar -xzf nginx-1.25.3.tar.gz
cd nginx-1.25.3
```

### Download RTMP Module

```bash
cd /tmp
git clone https://github.com/arut/nginx-rtmp-module.git
```

### Configure and Compile

```bash
cd /tmp/nginx-1.25.3

./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib64/nginx/modules \
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
sudo make install
```

## Step 5: Create Systemd Service

```bash
sudo tee /etc/systemd/system/nginx.service > /dev/null <<EOF
[Unit]
Description=Nginx HTTP Server
After=network.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
```

## Step 6: Enable and Start Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable nginx
sudo systemctl start nginx
```

## Step 7: Configure Nginx

```bash
sudo tee /etc/nginx/nginx.conf > /dev/null <<'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 10000;
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 20M;

    gzip on;
    gzip_disable "msie6";
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss;

    # HTTP Server for HLS
    server {
        listen 80;
        server_name _;

        location /hls {
            types {
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }
            alias /var/streaming/hls;
            add_header Cache-Control "max-age=3";
        }

        location /dash {
            types {
                application/dash+xml mpd;
                video/mp4 mp4;
            }
            alias /var/streaming/dash;
            add_header Cache-Control "max-age=3";
        }

        location /stat {
            rtmp_stat all;
            rtmp_stat_stylesheet /stat.xsl;
        }

        location /stat.xsl {
            alias /var/streaming/stat.xsl;
        }

        location /control {
            rtmp_control all;
        }

        location / {
            root /var/streaming/www;
            index index.html;
        }
    }
}

rtmp {
    server {
        listen 1935;
        chunk_size 4096;
        max_connections 1000;

        application live {
            live on;
            record off;
            
            # HLS
            hls on;
            hls_path /var/streaming/hls;
            hls_fragment 2;
            hls_playlist_length 3;
            hls_sync 100ms;
            
            # DASH
            dash on;
            dash_path /var/streaming/dash;
            dash_fragment 2s;
            dash_playlist_length 3;

            # Access control
            allow publish all;
            allow play all;
        }

        application vod {
            play /var/streaming/vod;
        }
    }
}
EOF
```

## Step 8: Create Directories

```bash
sudo mkdir -p /var/streaming/{hls,dash,vod,www}
sudo chown -R nginx:nginx /var/streaming
sudo chmod -R 755 /var/streaming
```

## Step 9: Configure Firewall

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 1935/tcp
sudo ufw enable
```

## Step 10: Verify Installation

```bash
# Check if nginx is running
sudo systemctl status nginx

# Check if listening on ports
sudo netstat -tulpn | grep nginx

# Test the stats endpoint
curl http://localhost/stat
```

## Post-Installation

### Create Web Dashboard

```bash
sudo tee /var/streaming/www/index.html > /dev/null <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>RTMP Server Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 5px; }
        h1 { color: #333; }
        .info-box { background: #e3f2fd; padding: 15px; margin: 10px 0; border-left: 4px solid #2196F3; }
        code { background: #f5f5f5; padding: 2px 6px; border-radius: 3px; }
        .stats { margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎬 RTMP Server Dashboard</h1>
        
        <div class="info-box">
            <strong>📺 Publish Stream:</strong><br>
            <code>rtmp://your-server-ip:1935/live/stream-key</code>
        </div>

        <div class="info-box">
            <strong>📡 Watch Stream (HLS):</strong><br>
            <code>http://your-server-ip/hls/stream-key.m3u8</code>
        </div>

        <div class="info-box">
            <strong>⚙️ Server Statistics:</strong><br>
            <a href="/stat">View Live Statistics</a>
        </div>

        <div class="info-box">
            <strong>✅ Server Status:</strong><br>
            <span id="status">Checking...</span>
        </div>

        <div class="stats">
            <h2>Quick Links</h2>
            <ul>
                <li><a href="/stat">Server Stats (XML)</a></li>
                <li><a href="/control">Stream Control</a></li>
                <li><a href="#">View Logs</a></li>
            </ul>
        </div>
    </div>

    <script>
        fetch('/stat')
            .then(r => r.text())
            .then(data => {
                document.getElementById('status').innerHTML = '✅ <strong>Online</strong>';
            })
            .catch(e => {
                document.getElementById('status').innerHTML = '❌ <strong>Offline</strong>';
            });
    </script>
</body>
</html>
EOF

sudo chown nginx:nginx /var/streaming/www/index.html
```

### Download Statistics Stylesheet

```bash
sudo curl -o /var/streaming/stat.xsl https://raw.githubusercontent.com/arut/nginx-rtmp-module/master/stat.xsl
sudo chown nginx:nginx /var/streaming/stat.xsl
```

## Verify Everything Works

```bash
# Check logs for any errors
sudo tail -f /var/log/nginx/error.log &

# In another terminal, stream test
ffmpeg -f lavfi -i testsrc=s=1280x720:d=300 -f lavfi -i sine=f=1000:d=300 \
    -c:v libx264 -b:v 5000k -c:a aac -b:a 128k \
    -rtmp_transport tcp -f flv rtmp://localhost:1935/live/test

# In yet another terminal, watch the stream
ffplay http://localhost/hls/test.m3u8
```

## Enable on Reboot

```bash
sudo systemctl enable nginx
```

## Common Issues

### Port Already in Use
```bash
sudo lsof -i :1935
```

### Permission Denied
```bash
sudo chown -R nginx:nginx /var/streaming
sudo chmod -R 755 /var/streaming
```

### Nginx Won't Start
```bash
sudo nginx -t  # Test configuration
sudo systemctl restart nginx
```

## Maintenance

### Restart Service
```bash
sudo systemctl restart nginx
```

### Reload Configuration
```bash
sudo systemctl reload nginx
```

### Monitor in Real-time
```bash
watch -n 1 'tail -20 /var/log/nginx/access.log'
```

Your RTMP server is now ready for production use!
