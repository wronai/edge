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
	@if ! curl -s http://localhost:8001/v1/health | grep -q '"status":"SERVING"'; then \
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
