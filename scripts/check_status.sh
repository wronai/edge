#!/bin/bash

echo "${YELLOW}Checking ONNX Runtime service status...${RESET}"

# Check if container is running
if ! docker-compose ps onnx-runtime | grep -q 'Up'; then 
    echo "${RED}✗ ONNX Runtime container is not running${RESET}"
    echo "${YELLOW}Container status:${RESET}"
    docker-compose ps onnx-runtime
    echo "Run 'make up' to start the services"
    exit 1
fi

echo "${GREEN}✓ ONNX Runtime container is running${RESET}"

echo "${YELLOW}Checking health endpoint...${RESET}"
# Check health endpoint
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001)

if [ "$HEALTH_STATUS" = "200" ]; then
    echo "${GREEN}✓ Health check passed${RESET}"
    echo "${YELLOW}Detailed status:${RESET}"
    curl -s http://localhost:8001 || echo "${RED}✗ Failed to get detailed status${RESET}"
else
    echo "${RED}✗ Health check failed (HTTP $HEALTH_STATUS)${RESET}"
    echo "${YELLOW}Detailed status:${RESET}"
    curl -s http://localhost:8001 || echo "${RED}✗ Failed to get detailed status${RESET}"
    exit 1
fi

echo "${YELLOW}Checking model status...${RESET}"
# Check if any models are loaded
MODEL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/v1/models)

if [ "$MODEL_STATUS" = "200" ]; then
    echo "${GREEN}✓ Models endpoint is accessible${RESET}"
    echo "${YELLOW}Available models:${RESET}"
    curl -s http://localhost:8001/v1/models | jq .
else
    echo "${YELLOW}Models endpoint status: HTTP $MODEL_STATUS${RESET}"
    echo "${YELLOW}Available models:${RESET}"
    curl -s http://localhost:8001/v1/models | jq .
fi

echo "${YELLOW}Checking metrics endpoint...${RESET}"
# Check metrics endpoint
METRICS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/metrics)

if [ "$METRICS_STATUS" = "200" ]; then
    echo "${GREEN}✓ Metrics endpoint is accessible${RESET}"
else
    echo "${YELLOW}Metrics endpoint status: HTTP $METRICS_STATUS${RESET}"
fi
