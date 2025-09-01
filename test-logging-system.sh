#!/bin/bash

echo "🔍 Testing Complete Logging System"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check service health
check_service() {
    local name=$1
    local url=$2
    local endpoint=$3
    
    echo -n "Checking $name... "
    if curl -s -f "$url$endpoint" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        return 1
    fi
}

# Function to count logs in Loki
count_logs() {
    local query=$1
    local description=$2
    
    echo -n "Checking $description... "
    local count=$(curl -s -G "http://localhost:3100/loki/api/v1/query" --data-urlencode "query=$query" | jq '.data.result | length' 2>/dev/null)
    
    if [ "$count" -gt 0 ]; then
        echo -e "${GREEN}✓ $count entries found${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ No entries found${NC}"
        return 1
    fi
}

echo ""
echo -e "${BLUE}1. Service Health Checks${NC}"
echo "=========================="
check_service "Loki" "http://localhost:3100" "/ready"
check_service "Promtail" "http://localhost:9080" "/ready"
check_service "Prometheus" "http://localhost:9090" "/-/healthy"
check_service "Grafana" "http://localhost:3002" "/api/health"

echo ""
echo -e "${BLUE}2. Log Collection Tests${NC}"
echo "========================"
count_logs '{container=~".+"}' "Container logs"
count_logs '{job=~".+"}' "Job logs"

echo ""
echo -e "${BLUE}3. Generating Test Logs${NC}"
echo "========================"
echo -n "Making requests to services... "
curl -s http://localhost:3000 > /dev/null 2>&1
curl -s http://localhost:3001 > /dev/null 2>&1
echo -e "${GREEN}✓ Done${NC}"

echo ""
echo -e "${BLUE}4. Final Log Count${NC}"
echo "=================="
sleep 3
count_logs '{container=~".+"}' "Total container logs"

echo ""
echo -e "${BLUE}5. Access Information${NC}"
echo "====================="
echo "🌐 Grafana Dashboard: http://localhost:3002"
echo "   Login: admin/admin"
echo "   Go to: Explore → Select Loki"
echo "   Try queries:"
echo "   • {container=~\"frontend.*\"} - Frontend logs"
echo "   • {container=~\"backend.*\"} - Backend logs"
echo "   • {job=~\"docker\"} - All Docker logs"
echo ""
echo "📊 Prometheus: http://localhost:9090"
echo "📝 Loki API: http://localhost:3100"
echo "🚀 Promtail: http://localhost:9080"

echo ""
echo -e "${GREEN}✅ Logging System Test Complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Open Grafana at http://localhost:3002"
echo "2. Login with admin/admin"
echo "3. Go to Explore and select Loki datasource"
echo "4. Try the suggested queries above"
