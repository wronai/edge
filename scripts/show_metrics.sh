#!/bin/bash

echo "${YELLOW}Fetching ONNX Runtime metrics...${RESET}"

if ! docker-compose ps onnx-runtime | grep -q 'Up'; then 
    echo "${RED}✗ ONNX Runtime is not running${RESET}"
    exit 1
fi

# Container metrics
echo "${YELLOW}Container metrics:${RESET}"
docker stats --no-stream $(docker-compose ps -q onnx-runtime) 2>/dev/null || echo "${YELLOW}Container metrics not available${RESET}"

echo "\n${YELLOW}Process metrics:${RESET}"
docker-compose exec -T onnx-runtime sh -c "ps -o pid,user,pcpu,pmem,cmd -C onnxruntime_server" 2>/dev/null || echo "${YELLOW}Process metrics not available${RESET}"

echo "\n${YELLOW}Memory usage:${RESET}"
docker-compose exec -T onnx-runtime sh -c "free -h" 2>/dev/null || echo "${YELLOW}Memory info not available${RESET}"
