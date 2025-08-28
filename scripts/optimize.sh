#!/bin/bash

echo "Optimizing system for production..."

# Create data directories
mkdir -p data/{postgres,redis,prometheus,grafana,loki}
mkdir -p logs/nginx
mkdir -p postgres/{backups,init}
mkdir -p redis/backups
mkdir -p nginx/ssl

# Set proper permissions
chmod 755 data/
chmod 755 logs/
chmod 755 postgres/
chmod 755 redis/
chmod 755 nginx/

echo "Data directories created successfully"

# Create postgres initialization script
cat > postgres/init/01-init.sql << 'EOF'
-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create monitoring user
CREATE USER monitoring WITH PASSWORD 'monitoring_password';
GRANT pg_monitor TO monitoring;

-- Enable monitoring
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET track_activities = on;
ALTER SYSTEM SET track_counts = on;
ALTER SYSTEM SET track_io_timing = on;
ALTER SYSTEM SET track_functions = all;
EOF

# Create redis backup script
cat > redis/backups/backup.sh << 'EOF'
#!/bin/bash
# Redis backup script
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="redis_backup_$DATE.rdb"

# Create backup
redis-cli --rdb "$BACKUP_FILE"

# Move to backup directory
mv "$BACKUP_FILE" "$BACKUP_DIR/"

# Keep only last 7 backups
find "$BACKUP_DIR" -name "redis_backup_*.rdb" -mtime +7 -delete

echo "Redis backup completed: $BACKUP_FILE"
EOF

chmod +x redis/backups/backup.sh

# Create postgres backup script
cat > postgres/backups/backup.sh << 'EOF'
#!/bin/bash
# PostgreSQL backup script
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="postgres_backup_$DATE.sql"

# Create backup
pg_dump -U $POSTGRES_USER $POSTGRES_DB > "$BACKUP_FILE"

# Compress backup
gzip "$BACKUP_FILE"

# Move to backup directory
mv "$BACKUP_FILE.gz" "$BACKUP_DIR/"

# Keep only last 7 backups
find "$BACKUP_DIR" -name "postgres_backup_*.sql.gz" -mtime +7 -delete

echo "PostgreSQL backup completed: $BACKUP_FILE.gz"
EOF

chmod +x postgres/backups/backup.sh

# Create nginx SSL directory structure
mkdir -p nginx/ssl/{certs,private}

# Create self-signed certificate for development
if [ ! -f "nginx/ssl/certs/nginx-selfsigned.crt" ]; then
    echo "Creating self-signed SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout nginx/ssl/private/nginx-selfsigned.key \
        -out nginx/ssl/certs/nginx-selfsigned.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
fi

echo "SSL certificates created"

# Create nginx configuration with SSL
cat > nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;

    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 10M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

    # Upstream servers
    upstream backend_servers {
        server backend:3001 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    upstream frontend_servers {
        server frontend:3000 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    # HTTP server (redirect to HTTPS)
    server {
        listen 80;
        server_name localhost;
        return 301 https://$server_name$request_uri;
    }

    # HTTPS server
    server {
        listen 443 ssl http2;
        server_name localhost;

        # SSL configuration
        ssl_certificate /etc/nginx/ssl/certs/nginx-selfsigned.crt;
        ssl_certificate_key /etc/nginx/ssl/private/nginx-selfsigned.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";

        # Frontend routes
        location / {
            proxy_pass http://frontend_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_connect_timeout 30s;
            proxy_send_timeout 30s;
            proxy_read_timeout 30s;
        }

        # API routes with rate limiting
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://backend_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_connect_timeout 30s;
            proxy_send_timeout 30s;
            proxy_read_timeout 30s;
        }

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF

echo "Nginx configuration optimized with SSL"

# Create system optimization script
cat > scripts/system-optimize.sh << 'EOF'
#!/bin/bash

echo "Applying system optimizations..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Increase file descriptor limits
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# Optimize kernel parameters
cat >> /etc/sysctl.conf << 'SYSCTL'
# Memory management
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=5

# Network optimization
net.core.somaxconn=65535
net.core.netdev_max_backlog=5000
net.ipv4.tcp_max_syn_backlog=65535
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_keepalive_time=1200
net.ipv4.tcp_max_tw_buckets=2000000

# File system optimization
fs.file-max=2097152
fs.inotify.max_user_watches=524288
SYSCTL

# Apply changes
sysctl -p

echo "System optimizations applied successfully"
echo "Please reboot for all changes to take effect"
EOF

chmod +x scripts/system-optimize.sh

echo "System optimization complete!"
echo ""
echo "Next steps:"
echo "1. Run 'sudo ./scripts/system-optimize.sh' for system-level optimizations"
echo "2. Deploy services with './deploy.sh'"
echo "3. Monitor performance with Grafana dashboards"
