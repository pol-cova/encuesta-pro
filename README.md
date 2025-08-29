# Encuesta Production

```bash
# 1. Clone repo
git clone https://github.com/pol-cova/encuesta-pro.git
cd encuesta-pro
# 2. Copy environment 
cp .env.example .env
# Edit .env with your passwords
# 3. Give permissions to the script
chmod +x deploy.sh
# 4. Deploy
./deploy.sh
```
## Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs (all services)
docker-compose logs

# View logs for specific service
docker-compose logs backend

# Check status
docker-compose ps

# Restart services
docker-compose restart
```

## Services

- Frontend: http://localhost:3000
- Backend: http://localhost:3001
- Nginx: http://localhost:80 (redirects to HTTPS)
- Nginx: https://localhost:443

## Monitoring Services

- Grafana: http://localhost:3002 (admin/admin)
- Prometheus: http://localhost:9090
- Loki: http://localhost:3100 (logs)
- Promtail: http://localhost:9080 (log shipping)

## Requirements

- Docker and Docker Compose
- Git
- OpenSSL (for SSL certificates)
