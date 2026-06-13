#!/bin/bash

# View RTMP Server logs

if command -v docker-compose &> /dev/null; then
    docker-compose logs -f nginx-rtmp
else
    sudo tail -f /var/log/nginx/error.log
fi
