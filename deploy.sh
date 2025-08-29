#!/bin/bash

echo "🚀 Encuesta Production Deployment"
echo "================================="

# Check Docker
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi
echo "✅ Docker is running"

# Clone repos if needed
if [ ! -d "frontend" ]; then
    echo "📥 Cloning frontend..."
    git clone https://github.com/erickvalles/frontend_encuestas.git frontend
fi

if [ ! -d "backend" ]; then
    echo "📥 Cloning backend..."
    git clone https://github.com/erickvalles/backend-encuesta.git backend
fi

# Setup environment
if [ ! -f ".env" ]; then
    echo "⚙️  Creating .env from env.example..."
    cp env.example .env
    echo "📝 Please edit .env with your passwords, then press Enter..."
    read
fi

# Create SSL cert if needed
if [ ! -f "nginx/ssl/certs/nginx-selfsigned.crt" ]; then
    echo "🔐 Creating SSL certificate..."
    mkdir -p nginx/ssl/{certs,private}
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout nginx/ssl/private/nginx-selfsigned.key \
        -out nginx/ssl/certs/nginx-selfsigned.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
fi

# Start everything
echo "🚀 Starting services..."
docker-compose up -d --build

echo "⏳ Waiting for services to start..."
sleep 15

echo "✅ Deployment complete!"
echo ""
echo "🌐 Services:"
echo "  Frontend: http://localhost:3000"
echo "  Backend:  http://localhost:3001"
echo "  Nginx:    http://localhost:80 → https://localhost:443"
echo ""
echo "📊 Monitoring:"
echo "  Grafana:    http://localhost:3002 (admin/admin)"
echo "  Prometheus: http://localhost:9090"
echo "  Loki:       http://localhost:3100 (logs)"
echo "  Promtail:   http://localhost:9080 (log shipping)"
echo ""
echo "🔍 Logging Features:"
echo "  • Centralized logs from all services"
echo "  • Structured logging with JSON parsing"
echo "  • Log correlation with metrics"
echo "  • 31-day log retention"
echo "  • Error tracking and debugging"
echo ""
echo "🔧 Management:"
echo "  docker-compose up -d    # Start"
echo "  docker-compose down     # Stop"
echo "  docker-compose logs     # View logs"
echo ""
echo "📝 View logs in Grafana:"
echo "  • Go to http://localhost:3002"
echo "  • Use Loki datasource to query logs"
echo "  • Filter by service, level, or time"
