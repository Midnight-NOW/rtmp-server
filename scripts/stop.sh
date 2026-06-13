#!/bin/bash

# Stop RTMP Server

echo "Stopping RTMP Server..."

if command -v docker-compose &> /dev/null; then
    docker-compose down
    echo "RTMP Server stopped"
else
    echo "Stopping with systemd..."
    sudo systemctl stop nginx
    echo "RTMP Server stopped"
fi
