# RTMP Server

A full-featured RTMP stream server for streaming to VRChat or the web. Built on nginx-rtmp module for reliability and performance.

## Features

- **RTMP Protocol Support**: Receive streams via RTMP protocol
- **HLS Streaming**: Convert RTMP streams to HLS for web playback
- **DASH Streaming**: Support for DASH protocol
- **Stream Management**: Automatic stream cleanup and management
- **Multi-bitrate Support**: Record and re-encode at multiple bitrates
- **Access Control**: Built-in authentication and IP whitelisting
- **Statistics Dashboard**: Monitor active streams and bandwidth usage
- **Docker Support**: Easy deployment via Docker
- **SSL/TLS Support**: Secure stream endpoints

## Quick Start (Docker)

### Prerequisites

- Docker and Docker Compose installed
- Ubuntu 20.04 LTS or later
- 2GB RAM minimum, 4GB+ recommended

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Midnight-NOW/rtmp-server.git
cd rtmp-server
```

2. Copy and configure environment:
```bash
cp .env.example .env
# Edit .env file with your settings
```

3. Start the server:
```bash
docker-compose up -d
```

4. Verify it's running:
```bash
curl http://localhost/stat
```

## Manual Installation (Ubuntu)

See [INSTALL.md](INSTALL.md) for step-by-step Ubuntu installation without Docker.

## Configuration

### Environment Variables

Edit `.env` file:

```bash
# Server settings
RTMP_PORT=1935
HTTP_PORT=80
HTTPS_PORT=443

# Stream settings
MAX_CONNECTIONS=100
MAX_STREAMS=50
STREAM_TIMEOUT=300

# HLS settings
HLS_ENABLED=true
HLS_FRAGMENT_DURATION=2
HLS_PLAYLIST_LENGTH=3

# Recording
RECORD_ENABLED=true
RECORD_PATH=/var/recordings

# SSL (optional)
SSL_ENABLED=false
SSL_CERT_PATH=/etc/nginx/certs/cert.pem
SSL_KEY_PATH=/etc/nginx/certs/key.pem

# Logging
LOG_LEVEL=info
```

## Streaming

### Publish Stream

**RTMP URL:**
```
rtmp://your-server-ip:1935/live/stream-key
```

**Example with FFmpeg:**
```bash
ffmpeg -f dshow -i video="screen-capture-recorder" -f dshow -i audio="Microphone" \
  -c:v libx264 -b:v 5000k -c:a aac -b:a 128k \
  -rtmp_transport tcp -f flv rtmp://your-server-ip:1935/live/mystream
```

**Example with OBS:**
1. Open OBS Settings → Stream
2. Service: Custom
3. Server: `rtmp://your-server-ip:1935/live`
4. Stream Key: `mystream`

### Watch Stream

**HLS URL (Web):**
```
http://your-server-ip/hls/stream-key.m3u8
```

**RTMP URL (RTMP Client):**
```
rtmp://your-server-ip:1935/live/stream-key
```

## Monitoring

### View Statistics
```bash
curl http://localhost/stat
```

### View Logs
```bash
# With Docker
docker-compose logs -f nginx-rtmp

# Without Docker
sudo tail -f /var/log/nginx/error.log
```

### Monitor in Real-time
```bash
docker stats rtmp-server_nginx-rtmp_1
```

## API Endpoints

### Statistics
```
GET /stat
```
Returns XML with stream statistics.

### Status
```
GET /status
```
Returns JSON with server status.

### Stream Info
```
GET /api/stream/{stream-key}
```
Returns JSON with stream information.

## Performance Tuning

### Increase Connection Limits

Edit `nginx.conf`:
```nginx
worker_processes auto;
worker_connections 10000;
```

### Enable Buffer

```nginx
rtmp {
    server {
        listen 1935;
        chunk_size 4096;
        
        application live {
            live on;
            record off;
            
            # Buffer settings
            max_streams 50;
            buflen 5s;
        }
    }
}
```

## Troubleshooting

### Stream won't connect
- Check firewall: `sudo ufw allow 1935/tcp`
- Verify nginx is running: `docker-compose ps`
- Check logs: `docker-compose logs nginx-rtmp`

### High latency
- Reduce chunk size in nginx.conf
- Reduce HLS segment duration
- Check network bandwidth

### Connection refused
- Ensure docker-compose is running: `docker-compose up -d`
- Check port conflicts: `sudo netstat -tulpn | grep 1935`

### Out of memory
- Increase swap or container memory limits
- Reduce max_connections or max_streams
- Enable recording to disk instead of memory

## Security

### Enable Authentication

Edit `nginx.conf`:
```nginx
application live {
    live on;
    allow publish 192.168.1.0/24;
    deny publish all;
}
```

### Use SSL/TLS

1. Generate certificates:
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout cert.key -out cert.pem
```

2. Update `.env`:
```bash
SSL_ENABLED=true
SSL_CERT_PATH=/etc/nginx/certs/cert.pem
SSL_KEY_PATH=/etc/nginx/certs/key.pem
```

3. Restart: `docker-compose restart`

## License

MIT License - See LICENSE file for details

## Support

For issues and questions, please open an issue on GitHub.
