#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[OK] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[WARN] $1${NC}"; }
print_error() { echo -e "${RED}[ERROR] $1${NC}"; }
print_info() { echo -e "${BLUE}[INFO] $1${NC}"; }

# Check if docker-compose file exists
if [ ! -f "docker-compose.prod.yaml" ]; then
    print_error "docker-compose.prod.yaml not found. Please run ./deploy.sh first."
    exit 1
fi

# Function to show usage
show_usage() {
    echo "Encuesta Production Management"
    echo "================================"
    echo ""
    echo "Usage: ./manage.sh [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     - Start all services"
    echo "  stop      - Stop all services"
    echo "  restart   - Restart all services"
    echo "  logs      - View logs (all or specific service)"
    echo "  status    - Check service status"
    echo "  clean     - Remove everything (volumes, containers, images)"
    echo "  backup    - Create database backups"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./manage.sh start"
    echo "  ./manage.sh logs backend"
    echo "  ./manage.sh status"
    echo ""
}

# Function to start services
start_services() {
    print_info "Starting production services..."
    
    if [ ! -f ".env.prod" ]; then
        print_error ".env.prod not found. Please run ./deploy.sh first."
        exit 1
    fi
    
    export $(cat .env.prod | xargs)
    docker-compose -f docker-compose.prod.yaml up -d
    
    print_status "Services started successfully!"
    echo ""
    echo "Services:"
    echo "  Frontend: http://localhost:3000"
    echo "  Backend:  http://localhost:3001"
    echo "  Nginx:    http://localhost:80 (redirects to HTTPS)"
    echo "  Nginx:    https://localhost:443"
    echo ""
    echo "Monitoring:"
    echo "  Grafana:    http://localhost:3002 (admin/admin)"
    echo "  Prometheus: http://localhost:9090"
    echo "  Loki:       http://localhost:3100"
}

# Function to stop services
stop_services() {
    print_info "Stopping all services..."
    docker-compose -f docker-compose.prod.yaml down
    print_status "Services stopped successfully!"
}

# Function to restart services
restart_services() {
    print_info "Restarting services..."
    docker-compose -f docker-compose.prod.yaml restart
    print_status "Services restarted successfully!"
}

# Function to show logs
show_logs() {
    if [ -z "$1" ]; then
        print_info "Showing logs for all services..."
        docker-compose -f docker-compose.prod.yaml logs -f
    else
        print_info "Showing logs for service: $1"
        docker-compose -f docker-compose.prod.yaml logs -f "$1"
    fi
}

# Function to show status
show_status() {
    print_info "Service Status:"
    echo ""
    docker-compose -f docker-compose.prod.yaml ps
    echo ""
    echo "🐳 Container Health:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Function to clean everything
clean_everything() {
    print_warning "This will remove ALL containers, volumes, and images!"
    echo "Are you sure? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_info "Cleaning up everything..."
        docker-compose -f docker-compose.prod.yaml down -v
        docker system prune -af
        docker volume prune -f
        print_status "Cleanup complete!"
    else
        print_info "Cleanup cancelled."
    fi
}

# Function to create backups
create_backups() {
    print_info "Creating database backups..."
    
    mkdir -p postgres/backups redis/backups
    
    if docker-compose -f docker-compose.prod.yaml ps postgres | grep -q "Up"; then
        print_info "Creating PostgreSQL backup..."
        docker-compose -f docker-compose.prod.yaml exec -T postgres pg_dump -U $DB_USER $DB_NAME > "postgres/backups/postgres_backup_$(date +%Y%m%d_%H%M%S).sql"
        print_status "PostgreSQL backup created"
    else
        print_warning "PostgreSQL is not running"
    fi
    
    if docker-compose -f docker-compose.prod.yaml ps redis | grep -q "Up"; then
        print_info "Creating Redis backup..."
        docker-compose -f docker-compose.prod.yaml exec -T redis redis-cli --rdb "/tmp/redis_backup.rdb"
        docker cp $(docker-compose -f docker-compose.prod.yaml ps -q redis):/tmp/redis_backup.rdb "redis/backups/redis_backup_$(date +%Y%m%d_%H%M%S).rdb"
        print_status "Redis backup created"
    else
        print_warning "Redis is not running"
    fi
}

# Main script logic
case "${1:-help}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    logs)
        show_logs "$2"
        ;;
    status)
        show_status
        ;;
    clean)
        clean_everything
        ;;
    backup)
        create_backups
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac
