.PHONY: help

# Colors
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)

# Help Target
help: ## Show this help
	@echo '\nUsage: make ${YELLOW}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  ${YELLOW}%-20s${GREEN}%s${RESET}\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

# Docker Compose
up: ## Start all services in detached mode
	docker-compose up -d

down: ## Stop and remove all containers
	docker-compose down

stop: ## Stop all services without removing containers
	docker-compose stop

start: ## Start existing containers
	docker-compose start

restart: ## Restart all services
	docker-compose restart

clean: ## Remove all containers, networks, and volumes
	docker-compose down -v
	docker system prune -f
	docker volume prune -f

restart: ## Restart all services
	docker-compose restart

logs: ## View logs from all services
	docker-compose logs -f

# Service Management
ollama-logs: ## View Ollama service logs
	docker-compose logs -f ollama

onnx-logs: ## View ONNX Runtime service logs
	docker-compose logs -f onnx-runtime

nginx-logs: ## View Nginx gateway logs
	docker-compose logs -f nginx-gateway

prometheus-logs: ## View Prometheus logs
	docker-compose logs -f prometheus

grafana-logs: ## View Grafana logs
	docker-compose logs -f grafana

# Cleanup
clean: ## Remove all containers, networks, and volumes
	docker-compose down -v

docker-prune: ## Remove unused Docker resources
	docker system prune -a --volumes

# Development
venv: ## Create a Python virtual environment
	python3 -m venv venv

install-deps: ## Install Python dependencies
	pip install -r requirements.txt

# Monitoring
monitor: ## Open monitoring dashboards
	@echo "Grafana: http://localhost:3007"
	@echo "Prometheus: http://localhost:9090"

# Testing
test: ## Run tests
	@echo "Running tests..."
	# Add your test commands here

# Status
status: ## Show status of all services
	docker-compose ps

# Formatting
format: ## Format code using black and isort
	black .
	isort .

lint: ## Lint code using flake8
	flake8 .

# Add more targets as needed for your project
