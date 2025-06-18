#!/bin/bash

echo "${YELLOW}Checking ONNX Runtime service status...${RESET}"

if docker-compose ps onnx-runtime | grep -q 'Up'; then 
    echo "${GREEN}✓ ONNX Runtime is running${RESET}"
    echo "${YELLOW}Health check:${RESET}"
    curl -s http://localhost:8001/ || echo "${RED}✗ Health check failed${RESET}"
else 
    echo "${RED}✗ ONNX Runtime is not running${RESET}"
    echo "Run 'make up' to start the services"
    exit 1
fi
