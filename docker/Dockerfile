FROM ubuntu:22.04

LABEL maintainer="RTMP Server"
LABEL description="RTMP Streaming Server with HLS/DASH support"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV NGINX_VERSION=1.25.3
ENV RTMP_MODULE_VERSION=master

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpcre3 \
    libpcre3-dev \
    zlib1g \
    zlib1g-dev \
    libssl-dev \
    libgd-dev \
    libgeoip-dev \
    wget \
    curl \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create nginx user
RUN useradd -r -M -s /sbin/nologin nginx

# Download nginx and rtmp module
RUN mkdir -p /tmp/build && cd /tmp/build && \
    wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -xzf nginx-${NGINX_VERSION}.tar.gz && \
    git clone https://github.com/arut/nginx-rtmp-module.git

# Compile nginx with rtmp module
RUN cd /tmp/build/nginx-${NGINX_VERSION} && \
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
    --with-http_stub_status_module \
    --add-module=/tmp/build/nginx-rtmp-module && \
    make && \
    make install && \
    rm -rf /tmp/build

# Clean up
RUN apt-get remove -y build-essential libpcre3-dev zlib1g-dev libssl-dev libgd-dev libgeoip-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create streaming directories
RUN mkdir -p /var/streaming/{hls,dash,vod,recordings,www} && \
    chown -R nginx:nginx /var/streaming && \
    chmod -R 755 /var/streaming

# Create log directory
RUN mkdir -p /var/log/nginx && \
    chown -R nginx:nginx /var/log/nginx

# Copy configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY config/stat.xsl /var/streaming/stat.xsl
COPY www/index.html /var/streaming/www/index.html

# Expose ports
EXPOSE 1935 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/stat || exit 1

# Run nginx
CMD ["nginx", "-g", "daemon off;"]
