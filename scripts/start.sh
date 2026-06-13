#!/bin/bash

# Start RTMP Server

echo "Starting RTMP Server..."

if command -v docker-compose &> /dev/null; then
    docker-compose up -d
    echo "RTMP Server started with Docker Compose"
    docker-compose ps
else
    echo "Docker Compose not found. Starting with systemd..."
    sudo systemctl start nginx
    sudo systemctl status nginx
fi

echo ""
echo "Server is running!"
echo "Access statistics at: http://localhost/stat"
echo "Stream at: rtmp://localhost:1935/live/"
