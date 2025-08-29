# Encuesta Production Setup

```bash
# 1. Clone this repo
git clone https://github.com/pol-cova/encuesta-pro.git
cd encuesta-pro

# 2. Copy environment file and edit
cp env.example .env
# Edit .env with your passwords

# 3. Deploy everything (one command!)
./deploy.sh
```

## Management Commands

```bash
# Start services
./manage.sh start

# Stop services
./manage.sh stop

# Restart services
./manage.sh restart

# View logs (all services)
./manage.sh logs

# View logs for specific service
./manage.sh logs backend

# Check status
./manage.sh status

# Create backups
./manage.sh backup

# Clean everything
./manage.sh clean

# Show help
./manage.sh help
```

## Services

- Frontend: http://localhost:3000
- Backend: http://localhost:3001
- Nginx: http://localhost:80 (redirects to HTTPS)
- Nginx: https://localhost:443

## Monitoring Services

- Grafana: http://localhost:3002 (admin/admin)
- Prometheus: http://localhost:9090
- Loki: http://localhost:3100

## Deployment

### Local Development
```bash
./deploy.sh
```

### Production Server
```bash
git clone https://github.com/pol-cova/encuesta-pro.git
cd encuesta-pro
cp env.example .env
# Edit .env with production values
./deploy.sh
```

## Requirements

- Docker and Docker Compose
- Git
- OpenSSL (for SSL certificates)

## Monitoring commands

```bash
# Check monitoring services
docker-compose -f docker-compose.prod.yaml ps prometheus grafana loki

# View Prometheus logs
docker-compose -f docker-compose.prod.yaml logs prometheus

# View Grafana logs
docker-compose -f docker-compose.prod.yaml logs grafana

# View Loki logs
docker-compose -f docker-compose.prod.yaml logs loki
```

# Last update: 28/08/2025