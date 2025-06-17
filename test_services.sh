#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to test an endpoint
test_endpoint() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}
    
    echo -n "Testing $name ($url)... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$response" == "$expected_status" ]; then
        echo -e "${GREEN}PASS${NC} (Status: $response)"
        return 0
    else
        echo -e "${RED}FAIL${NC} (Expected: $expected_status, Got: $response)"
        return 1
    fi
}

# Test direct endpoints
echo "=== Testing Direct Endpoints ==="
test_endpoint "Ollama API" "http://localhost:11435/api/tags" 200
# ONNX Runtime expects POST for inference, 405 for GET is expected
test_endpoint "ONNX Runtime" "http://localhost:8001/v1/" 405

# Test through Nginx
echo -e "\n=== Testing Through Nginx Gateway ==="
test_endpoint "Nginx -> Ollama" "http://localhost:30080/api/tags" 200
test_endpoint "Nginx -> ONNX Runtime" "http://localhost:30080/v1/" 405  # 405 is expected for GET on /v1/

# Test Nginx health check
test_endpoint "Nginx Health Check" "http://localhost:30080/health" 200

# Test Prometheus (should redirect to /graph)
echo -e "\n=== Testing Monitoring ==="
test_endpoint "Prometheus" "http://localhost:9090" 302
# Test Prometheus graph page directly
test_endpoint "Prometheus Graph" "http://localhost:9090/graph" 200

# Test Grafana (should redirect to login)
test_endpoint "Grafana" "http://localhost:3007" 302
# Test Grafana login page directly
test_endpoint "Grafana Login" "http://localhost:3007/login" 200
