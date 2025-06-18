.PHONY: help test clean format lint

# Colors
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
RED    := $(shell tput -Txterm setaf 1)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)

# Help Target
help: ## Show this help
	@echo '\n${YELLOW}Edge AI Platform${RESET}\n'
	@echo 'Usage: make ${YELLOW}<target>${RESET}\n'
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  ${YELLOW}%-20s${GREEN}%s${RESET}\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

# ===== Docker Compose =====
up: ## Start all services in detached mode
	@echo "${GREEN}Starting all services...${RESET}"
	docker-compose up -d

build: ## Build all services
	@echo "${GREEN}Building services...${RESET}"
	docker-compose build --no-cache

down: ## Stop and remove all containers
	@echo "${YELLOW}Stopping and removing containers...${RESET}"
	docker-compose down

stop: ## Stop all services without removing containers
	@echo "${YELLOW}Stopping services...${RESET}"
	docker-compose stop

start: ## Start existing containers
	@echo "${GREEN}Starting services...${RESET}"
	docker-compose start

restart: ## Restart all services
	@echo "${YELLOW}Restarting services...${RESET}"
	docker-compose restart

# ===== Cleanup =====
clean: ## Remove all containers, networks, and volumes
	@echo "${RED}Cleaning up...${RESET}"
	docker-compose down -v
	docker system prune -f
	docker volume prune -f

prune: ## Remove all unused Docker resources
	@echo "${RED}Pruning Docker system...${RESET}"
	docker system prune -a --volumes

# ===== Logs =====
logs: ## View logs from all services
	docker-compose logs -f

## Service-specific logs
ollama-logs: ## View Ollama service logs
	docker-compose logs -f ollama

onnx-logs: ## View ONNX Runtime service logs
	docker-compose logs -f onnx-runtime

gateway-logs: ## View Nginx gateway logs
	docker-compose logs -f nginx-gateway

prometheus-logs: ## View Prometheus logs
	docker-compose logs -f prometheus

grafana-logs: ## View Grafana logs
	docker-compose logs -f grafana

# ===== Development =====
venv: ## Create a Python virtual environment
	@echo "${GREEN}Creating virtual environment...${RESET}"
	python3 -m venv venv

install-deps: ## Install Python dependencies
	@echo "${GREEN}Installing dependencies...${RESET}"
	pip install -r requirements.txt

# ===== ONNX Runtime =====
# ONNX Runtime API Helpers
MODEL_NAME ?= complex-cnn-model
MODEL_VERSION ?= 1

.PHONY: onnx-status onnx-metrics onnx-models onnx-load onnx-test onnx-benchmark onnx-convert

# ONNX Runtime status and metrics
onnx-status: ## Check if ONNX Runtime service is running
	@scripts/check_status.sh

onnx-metrics: ## Show ONNX Runtime metrics
	@scripts/show_metrics.sh

# Model management
onnx-models: ## List available ONNX models in the models directory
	@echo "${YELLOW}Available ONNX models:${RESET}"
	@if [ -d "models" ]; then \
		find models -name "*.onnx" | sed 's/^/  /'; \
	else \
		echo "  No models directory found"; \
	fi

onnx-load: ## Load an ONNX model (usage: make onnx-load MODEL=model_name PATH=path/to/model.onnx)
	@if [ -z "$(MODEL)" ] || [ -z "$(PATH)" ]; then \
		echo "${RED}Error: MODEL and PATH must be specified${RESET}"; \
		echo "Usage: make onnx-load MODEL=model_name PATH=path/to/model.onnx"; \
		exit 1; \
	fi
	@echo "${YELLOW}Loading model $(MODEL) from $(PATH)...${RESET}"
	@mkdir -p models
	@cp "$(PATH)" "models/$(MODEL).onnx"
	@echo "${GREEN}✓ Model $(MODEL) loaded${RESET}"

onnx-test: ## Test ONNX Runtime with a sample request
	@echo "${YELLOW}Testing ONNX Runtime inference...${RESET}"
	@if [ ! -d "models" ] || [ -z "$$(ls -A models/)" ]; then \
		echo "${YELLOW}No models found. Try 'make onnx-load' first.${RESET}"; \
		exit 0; \
	fi
	@echo "${YELLOW}Available models:${RESET}"
	@find models -name "*.onnx" | sed 's/^/  /'
	@echo "\n${YELLOW}Example test commands:${RESET}"
	@echo "1. Basic test with curl (V1 API):"
	@echo '  curl -X POST http://localhost:8001/v1/$(MODEL_NAME)/versions/$(MODEL_VERSION):predict \'
	@echo '    -H "Content-Type: application/json" \'
	@echo '    -d '\''{"instances": [{"data": [1.0, 2.0, 3.0, 4.0]}]}'
	@echo "\n2. Test with Python (requires requests):"
	@echo '  ```python'
	@echo '  import requests'
	@echo '  import json'
	@echo '  '
	@echo '  # V1 API (recommended)'
	@echo '  response = requests.post('
	@echo '      "http://localhost:8001/v1/$(MODEL_NAME)/versions/$(MODEL_VERSION):predict",'
	@echo '      json={"instances": [{"data": [1.0, 2.0, 3.0, 4.0]}]}'
	@echo '  )'
	@echo '  print(json.dumps(response.json(), indent=2))'
	@echo '  ```'
	@echo "\n3. Check model status:"
	@echo '  curl http://localhost:8001/v1/$(MODEL_NAME)/versions/$(MODEL_VERSION)'
	@echo "\n4. Get model metadata:"
	@echo '  curl http://localhost:8001/v1/$(MODEL_NAME)/versions/$(MODEL_VERSION)/metadata'

onnx-benchmark: ## Run a simple benchmark test (requires model to be loaded)
	@echo "${YELLOW}Running ONNX Runtime benchmark...${RESET}"
	@if [ ! -d "models" ] || [ -z "$$(ls -A models/)" ]; then \
		echo "${YELLOW}No models found. Try 'make onnx-load' first.${RESET}"; \
		exit 1; \
	fi
	@echo "${YELLOW}Benchmarking with 100 inference requests...${RESET}"
	@echo "${YELLOW}Model: $$(find models -name "*.onnx" | head -n 1)${RESET}"
	@echo "${YELLOW}Using model: ${MODEL_NAME}, version: ${MODEL_VERSION}${RESET}"
	@echo "${YELLOW}Results:${RESET}"
	@docker-compose exec -T onnx-runtime python3 -c "\
	import time
	import requests
	import statistics
	import json
	
	times = []
	success = 0
	try:
	    # First check if model is ready
	    status_response = requests.get(
	        f'http://localhost:8001/v1/{'$(MODEL_NAME)'}/versions/{'$(MODEL_VERSION)'}'
	    )
	    if status_response.status_code != 200:
	        print('Model is not ready:', status_response.text)
	        exit(1)
	        
	    # Run benchmark
	    for i in range(100):
	        try:
	            start = time.time()
	            response = requests.post(
	                f'http://localhost:8001/v1/{'$(MODEL_NAME)'}/versions/{'$(MODEL_VERSION)'}:predict',
	                json={"instances": [{"data": [1.0, 2.0, 3.0, 4.0]}]},
	                timeout=5
	            )
	            if response.status_code == 200:
	                times.append((time.time() - start) * 1000)  # Convert to ms
	                success += 1
	            else:
	                print(f'Request failed ({response.status_code}):', response.text)
	        except Exception as e:
	            print(f'Request error: {str(e)}')
	            continue
	    
	    # Print results
	    if times:
	        print(f'\nSuccess rate: {success}/100 ({success}%)')
	        print(f'Average latency: {statistics.mean(times):.2f}ms')
	        print(f'Min latency: {min(times):.2f}ms')
	        print(f'Max latency: {max(times):.2f}ms')
	        print(f'P50 latency: {statistics.median(times):.2f}ms')
	        print(f'P95 latency: {sorted(times)[int(len(times)*0.95)]:.2f}ms')
	    else:
	        print('No successful requests to measure')
	        
	except Exception as e:
	    print(f'Error during benchmark: {str(e)}')
	    exit(1)
	" || echo "${RED}Benchmark failed${RESET}"

# Helper targets for common ONNX operations
onnx-model-status: ## Check model status
	@echo "${YELLOW}Checking status of model ${MODEL_NAME}, version ${MODEL_VERSION}...${RESET}"
	@curl -s http://localhost:8001/v1/${MODEL_NAME}/versions/${MODEL_VERSION} | jq . 2>/dev/null || echo "${RED}Failed to get model status${RESET}"

onnx-model-metadata: ## Get model metadata
	@echo "${YELLOW}Getting metadata for model ${MODEL_NAME}, version ${MODEL_VERSION}...${RESET}"
	@curl -s http://localhost:8001/v1/${MODEL_NAME}/versions/${MODEL_VERSION}/metadata | jq . 2>/dev/null || echo "${RED}Failed to get model metadata${RESET}"

onnx-predict: ## Make a prediction with the default model
	@echo "${YELLOW}Making prediction with model ${MODEL_NAME}, version ${MODEL_VERSION}...${RESET}"
	@curl -X POST http://localhost:8001/v1/${MODEL_NAME}/versions/${MODEL_VERSION}:predict \
	  -H "Content-Type: application/json" \
	  -d '{"instances": [{"data": [1.0, 2.0, 3.0, 4.0]}]}' \
	  2>/dev/null | jq . || echo "${RED}Prediction failed${RESET}"

onnx-convert: ## Convert a model to ONNX format
	@echo "${YELLOW}Converting $(MODEL_TYPE) model to ONNX...${RESET}"
	@mkdir -p models
	@docker run --rm -v $(PWD):/workspace python:3.9-slim bash -c '
	    pip install $(if [ "$(MODEL_TYPE)" = "pytorch" ]; then echo "torch torchvision"; else echo "tensorflow"; fi) onnx && 
	    python3 scripts/convert_model.py'
	@cp model.onnx models/$(MODEL).onnx
	@echo "${GREEN}✓ Model $(MODEL) converted and saved${RESET}"
		echo "${GREEN}✓ Model converted successfully: models/converted_model.onnx${RESET}"; \
	else \
		echo "${RED}✗ Model conversion failed${RESET}"; \
	fi

# ===== Testing =====
test: ## Run tests
	@echo "${GREEN}Running tests...${RESET}"
	@echo "${YELLOW}Checking service status...${RESET}"
	@if ! docker-compose ps | grep -q "Up"; then \
		echo "${RED}Error: Services are not running. Run 'make up' first.${RESET}"; \
		exit 1; \
	fi
	@echo "${GREEN}✓ Services are running${RESET}"
	@echo "${YELLOW}Testing API endpoints...${RESET}"
	@echo "${YELLOW}Testing Ollama API...${RESET}"
	@if ! curl -s http://localhost:11435/api/tags >/dev/null; then \
		echo "${RED}✗ Ollama API is not responding${RESET}"; \
		exit 1; \
	else \
		echo "${GREEN}✓ Ollama API is responding${RESET}"; \
	fi
	@echo "${YELLOW}Testing ONNX Runtime...${RESET}"
	@if ! curl -s http://localhost:8001/v1/ >/dev/null; then \
		echo "${RED}✗ ONNX Runtime is not responding${RESET}"; \
		exit 1; \
	else \
		echo "${GREEN}✓ ONNX Runtime is responding${RESET}"; \
	fi
	@echo "${YELLOW}Testing Nginx Gateway...${RESET}"
	@if ! curl -s http://localhost:30080/health >/dev/null; then \
		echo "${RED}✗ Nginx Gateway is not responding${RESET}"; \
		exit 1; \
	else \
		echo "${GREEN}✓ Nginx Gateway is responding${RESET}"; \
	fi
	@echo "${GREEN}✓ All tests passed!${RESET}"
		echo "${YELLOW}⚠ ONNX Runtime is not ready (may still be starting)${RESET}"; \
	else \
		echo "${GREEN}✓ ONNX Runtime is responding${RESET}"; \
	fi
	@echo "${GREEN}✓ All tests passed!${RESET}"

# ===== Monitoring =====
monitor: ## Show monitoring URLs
	@echo "\n${YELLOW}=== Monitoring URLs ===${RESET}"
	@echo "Grafana:     http://localhost:3007 (admin/admin)"
	@echo "Prometheus:  http://localhost:9090"
	@echo "Ollama:      http://localhost:11435"
	@echo "ONNX:        http://localhost:8001"

# ===== Status =====
status: ## Show status of all services
	@echo "${YELLOW}=== Service Status ===${RESET}"
	@docker-compose ps
	@echo "\n${YELLOW}=== Resource Usage ===${RESET}"
	@docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | head -n 1
	@docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | grep -v "CONTAINER"

# ===== Code Quality =====
format: ## Format code using black and isort
	@echo "${GREEN}Formatting code...${RESET}"
	black .
	isort .

lint: ## Lint code using flake8 and shellcheck
	@echo "${GREEN}Linting code...${RESET}"
	flake8 .
	find . -name '*.sh' -exec shellcheck {} \;

# ===== Kubernetes =====
kind-create: ## Create a local Kubernetes cluster using Kind
	@echo "${GREEN}Creating Kind cluster...${RESET}"
	kind create cluster --name edge-ai --config kind-config.yaml
	@echo "${YELLOW}Installing Calico CNI...${RESET}"
	kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

kind-delete: ## Delete the Kind cluster
	@echo "${RED}Deleting Kind cluster...${RESET}"
	kind delete cluster --name edge-ai

# ===== Utils =====
check-ports: ## Check if required ports are available
	@echo "${YELLOW}Checking required ports...${RESET}"
	@for port in 30080 11435 8001 3007 9090; do \
		if lsof -i :$$port >/dev/null; then \
			echo "${RED}✗ Port $$port is in use${RESET}"; \
		else \
			echo "${GREEN}✓ Port $$port is available${RESET}"; \
		fi; \
	done
