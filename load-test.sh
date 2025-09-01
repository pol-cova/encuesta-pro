#!/bin/bash

echo "🚀 Load Testing Script for Development Decisions"
echo "==============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FRONTEND_URL="http://localhost:3000"
BACKEND_URL="http://localhost:3001"
DURATION=60  # seconds
CONCURRENT_USERS=10
REQUESTS_PER_SECOND=5

# Function to run load test
run_load_test() {
    local service=$1
    local url=$2
    local description=$3
    
    echo -e "\n${BLUE}Testing $description${NC}"
    echo "URL: $url"
    echo "Duration: ${DURATION}s"
    echo "Concurrent Users: $CONCURRENT_USERS"
    echo "Requests/sec: $REQUESTS_PER_SECOND"
    echo ""
    
    # Check if service is responding
    echo -n "Health check... "
    if curl -s -f "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${RED}✗ FAILED${NC}"
        return 1
    fi
    
    # Run load test with curl (simple version)
    echo "Running load test..."
    local start_time=$(date +%s)
    local end_time=$((start_time + DURATION))
    local request_count=0
    local success_count=0
    local error_count=0
    
    while [ $(date +%s) -lt $end_time ]; do
        for i in $(seq 1 $CONCURRENT_USERS); do
            {
                local response=$(curl -s -w "%{http_code}" -o /dev/null "$url" 2>/dev/null)
                if [ "$response" = "200" ] || [ "$response" = "404" ]; then
                    ((success_count++))
                else
                    ((error_count++))
                fi
                ((request_count++))
            } &
        done
        sleep 1
        echo -n "."
    done
    wait
    
    local total_time=$(($(date +%s) - start_time))
    local rps=$((request_count / total_time))
    
    echo ""
    echo -e "${GREEN}Load Test Results for $description:${NC}"
    echo "  Total Requests: $request_count"
    echo "  Successful: $success_count"
    echo "  Errors: $error_count"
    echo "  Requests/sec: $rps"
    echo "  Success Rate: $(( (success_count * 100) / request_count ))%"
}

# Function to monitor system resources
monitor_resources() {
    echo -e "\n${BLUE}System Resource Monitoring${NC}"
    echo "=========================="
    
    # Check if node-exporter is available
    if curl -s http://localhost:9100/metrics > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Node Exporter available${NC}"
        
        # Get current CPU usage
        local cpu_usage=$(curl -s http://localhost:9100/metrics | grep 'node_cpu_seconds_total{mode="idle"}' | head -1 | cut -d' ' -f2)
        echo "CPU Usage: $cpu_usage"
        
        # Get memory usage
        local mem_total=$(curl -s http://localhost:9100/metrics | grep 'node_memory_MemTotal_bytes' | cut -d' ' -f2)
        local mem_available=$(curl -s http://localhost:9100/metrics | grep 'node_memory_MemAvailable_bytes' | cut -d' ' -f2)
        if [ -n "$mem_total" ] && [ -n "$mem_available" ]; then
            local mem_used=$((mem_total - mem_available))
            local mem_percent=$(( (mem_used * 100) / mem_total ))
            echo "Memory Usage: ${mem_percent}%"
        fi
    else
        echo -e "${YELLOW}⚠ Node Exporter not available${NC}"
    fi
    
    # Check if cAdvisor is available
    if curl -s http://localhost:8080/metrics > /dev/null 2>&1; then
        echo -e "${GREEN}✓ cAdvisor available${NC}"
        
        # Get container count
        local container_count=$(curl -s http://localhost:8080/metrics | grep 'container_last_seen' | wc -l)
        echo "Active Containers: $container_count"
    else
        echo -e "${YELLOW}⚠ cAdvisor not available${NC}"
    fi
}

# Function to check Prometheus metrics
check_prometheus_metrics() {
    echo -e "\n${BLUE}Prometheus Metrics Check${NC}"
    echo "========================"
    
    if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Prometheus is healthy${NC}"
        
        # Check system metrics
        local node_metrics=$(curl -s "http://localhost:9090/api/v1/query?query=up{job=\"node-exporter\"}" | jq '.data.result | length' 2>/dev/null)
        if [ "$node_metrics" -gt 0 ]; then
            echo -e "${GREEN}✓ System metrics available${NC}"
        else
            echo -e "${YELLOW}⚠ System metrics not available${NC}"
        fi
        
        # Check container metrics
        local container_metrics=$(curl -s "http://localhost:9090/api/v1/query?query=up{job=\"cadvisor\"}" | jq '.data.result | length' 2>/dev/null)
        if [ "$container_metrics" -gt 0 ]; then
            echo -e "${GREEN}✓ Container metrics available${NC}"
        else
            echo -e "${YELLOW}⚠ Container metrics not available${NC}"
        fi
    else
        echo -e "${RED}✗ Prometheus not available${NC}"
    fi
}

# Main execution
echo "Starting load test and system monitoring..."
echo ""

# Check prerequisites
echo -e "${BLUE}Prerequisites Check${NC}"
echo "==================="
monitor_resources
check_prometheus_metrics

# Run load tests
echo -e "\n${BLUE}Load Testing${NC}"
echo "============"

run_load_test "frontend" "$FRONTEND_URL" "Frontend Service"
run_load_test "backend" "$BACKEND_URL" "Backend Service"

# Final resource check
echo -e "\n${BLUE}Post-Load Test Resource Check${NC}"
echo "=============================="
monitor_resources

echo -e "\n${GREEN}Load Testing Complete!${NC}"
echo ""
echo "📊 View detailed metrics in Grafana:"
echo "   http://localhost:3002 (admin/admin)"
echo ""
echo "🔍 Prometheus queries for development decisions:"
echo "   • CPU Usage: rate(node_cpu_seconds_total[5m])"
echo "   • Memory Usage: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100"
echo "   • Container CPU: rate(container_cpu_usage_seconds_total[5m])"
echo "   • Container Memory: container_memory_usage_bytes"
echo "   • HTTP Request Rate: rate(prometheus_http_requests_total[5m])"
echo ""
echo "💡 Development Decision Tips:"
echo "   • High CPU (>80%): Consider optimizing algorithms or scaling horizontally"
echo "   • High Memory (>80%): Check for memory leaks or increase resources"
echo "   • High Error Rate (>5%): Review error logs and fix issues"
echo "   • Low Throughput: Optimize database queries or add caching"
