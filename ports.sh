#!/bin/bash

echo "Testing Encuesta Deployment on Mac"
echo "===================================="

# Check if Docker Desktop is running
if ! docker info > /dev/null 2>&1; then
    echo "Docker Desktop is not running!"
    echo "Please start Docker Desktop first, then run this script again."
    exit 1
fi
echo "Docker Desktop is running"

# Check if ports are available
echo "Checking if ports are available..."

check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "Port $port is already in use"
        return 1
    else
        echo "Port $port is available"
        return 0
    fi
}

check_port 3000 || exit 1
check_port 3001 || exit 1
check_port 80 || exit 1
check_port 443 || exit 1
check_port 5432 || exit 1
check_port 6379 || exit 1
check_port 9090 || exit 1
check_port 3002 || exit 1
check_port 3100 || exit 1
check_port 9080 || exit 1
check_port 9100 || exit 1
check_port 8080 || exit 1

echo ""
echo "All ports are available! Ready to deploy."
echo ""
echo "Next steps:"
echo "1. Run: ./deploy.sh"
echo "2. Wait for services to start (about 2-3 minutes)"
echo "3. Test the services:"
echo "   - Frontend: http://localhost:3000"
echo "   - Backend:  http://localhost:3001"
echo "   - Nginx:    http://localhost:80 → https://localhost:443"
echo "   - Grafana:  http://localhost:3002 (admin/admin)"
echo "   - Prometheus: http://localhost:9090"
echo "   - Loki:     http://localhost:3100 (logs)"
echo "   - Promtail: http://localhost:9080 (log shipping)"
echo "   - Node Exporter: http://localhost:9100 (system metrics)"
echo "   - cAdvisor: http://localhost:8080 (container metrics)"
echo ""
echo "New Monitoring Features:"
echo "   • System resource monitoring (CPU, Memory, Disk)"
echo "   • Container resource monitoring"
echo "   • Centralized logs from all services"
echo "   • Structured logging with JSON parsing"
echo "   • Log correlation with metrics in Grafana"
echo "   • 31-day log retention"
echo "   • Error tracking and debugging"
echo "   • Load testing capabilities"
echo ""
echo "To stop everything: docker-compose down"
echo "To view logs: docker-compose logs"
