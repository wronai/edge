#!/bin/bash

#=============================================================================
# Edge AI DevOps Portfolio - Debug and Fix Script
#
# Diagnose and fix deployment issues
#=============================================================================

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%H:%M:%S') $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%H:%M:%S') $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%H:%M:%S') $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $(date '+%H:%M:%S') 🔍 $1"
}

# Comprehensive diagnosis
run_diagnosis() {
    log_step "Running comprehensive system diagnosis..."

    echo "=================================================="
    echo "🔍 EDGE AI DEVOPS PORTFOLIO - SYSTEM DIAGNOSIS"
    echo "=================================================="
    echo

    # 1. Docker Status
    log_step "Checking Docker status..."
    if docker info >/dev/null 2>&1; then
        log_info "✅ Docker is running"
        echo "Docker version:"
        docker version --format 'Client: {{.Client.Version}}, Server: {{.Server.Version}}'
        echo
        echo "Docker system info:"
        docker system df
    else
        log_error "❌ Docker is not running or accessible"
        return 1
    fi

    # 2. Check containers
    log_step "Checking Docker containers..."
    echo "All containers:"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
    echo

    # Look for any K3s or related containers
    if docker ps -a | grep -E "(k3s|rancher)" >/dev/null; then
        log_info "Found K3s-related containers:"
        docker ps -a | grep -E "(k3s|rancher)"
    else
        log_warn "❌ No K3s containers found"
    fi

    # 3. Check networks
    log_step "Checking Docker networks..."
    echo "Docker networks:"
    docker network ls
    echo

    if docker network ls | grep "edge-ai" >/dev/null; then
        log_info "✅ Edge AI network exists"
        docker network inspect edge-ai-net 2>/dev/null || log_warn "Edge AI network details not available"
    else
        log_warn "❌ Edge AI network not found"
    fi

    # 4. Check volumes
    log_step "Checking Docker volumes..."
    echo "Docker volumes:"
    docker volume ls
    echo

    # 5. Terraform state
    log_step "Checking Terraform state..."
    if [[ -d "terraform" ]]; then
        cd terraform
        if [[ -f "terraform.tfstate" ]]; then
            log_info "✅ Terraform state file exists"
            echo "Terraform state summary:"
            terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[]?.address // "No resources"' 2>/dev/null || echo "Cannot parse state"
        else
            log_warn "❌ No Terraform state file found"
        fi

        if terraform validate >/dev/null 2>&1; then
            log_info "✅ Terraform configuration is valid"
        else
            log_warn "❌ Terraform configuration has issues"
        fi
        cd ..
    else
        log_error "❌ Terraform directory not found"
    fi

    # 6. Check ports
    log_step "Checking port availability..."
    local ports=(6443 8080 8443 30080 30090 30030 11434 11435 8001 8007 9090 3000 3007)
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep ":$port " >/dev/null; then
            echo "Port $port: ✅ IN USE"
        else
            echo "Port $port: ⚪ AVAILABLE"
        fi
    done
    echo

    # 7. Check kubeconfig
    log_step "Checking Kubernetes configuration..."
    if [[ -f "kubeconfig/kubeconfig.yaml" ]]; then
        log_info "✅ Kubeconfig file exists"
        echo "Kubeconfig content preview:"
        head -10 kubeconfig/kubeconfig.yaml || true
    else
        log_warn "❌ Kubeconfig file not found"
    fi

    # 8. Test basic connectivity
    log_step "Testing service connectivity..."
    local endpoints=(
        "http://localhost:30080/health:AI Gateway"
        "http://localhost:30090/-/healthy:Prometheus"
        "http://localhost:30030/api/health:Grafana"
        "http://localhost:11435/api/tags:Ollama Direct"
        "http://localhost:8001/v1/models:ONNX Direct"
    )

    for endpoint in "${endpoints[@]}"; do
        local url="${endpoint%:*}"
        local name="${endpoint#*:}"

        if curl -f -s --max-time 5 "$url" >/dev/null 2>&1; then
            echo "$name: ✅ RESPONDING"
        else
            echo "$name: ❌ NOT RESPONDING"
        fi
    done

    echo
    log_step "Diagnosis complete!"
}

# Quick fix for K3s issue
fix_k3s_deployment() {
    log_step "Attempting to fix K3s deployment..."

    # Clean up any partial state
    log_info "Cleaning up existing resources..."
    docker stop k3s-server 2>/dev/null || true
    docker rm k3s-server 2>/dev/null || true
    docker network rm edge-ai-net 2>/dev/null || true

    # Clean up Terraform state if corrupted
    if [[ -d "terraform" ]]; then
        cd terraform
        if [[ -f "terraform.tfstate" ]]; then
            log_info "Backing up Terraform state..."
            cp terraform.tfstate terraform.tfstate.backup.$(date +%s)
        fi

        # Try to clean up Terraform resources
        log_info "Cleaning Terraform state..."
        terraform destroy -auto-approve 2>/dev/null || log_warn "Terraform destroy had issues"
        cd ..
    fi

    # Clean local files
    rm -rf kubeconfig k3s-data registry-data 2>/dev/null || true

    log_info "✅ Cleanup complete"
}

# Deploy with Docker Compose as fallback
deploy_docker_compose_fallback() {
    log_step "Deploying with Docker Compose fallback..."

    cat > docker-compose.yml << 'EOF'

services:
  ollama:
    image: ollama/ollama:latest
    container_name: edge-ai-ollama
    ports:
      - "11435:11434"
    volumes:
      - ollama_data:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0:11435
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11435/api/tags"]
      interval: 30s
      timeout: 10s
      retries: 5

  onnx-runtime:
    image: mcr.microsoft.com/onnxruntime/server:latest
    container_name: edge-ai-onnx
    ports:
      - "8001:8001"
    environment:
      - ONNX_MODEL_PATH=/models
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/v1/models"]
      interval: 30s
      timeout: 10s
      retries: 5

  prometheus:
    image: prom/prometheus:latest
    container_name: edge-ai-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./configs/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=15d'
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: edge-ai-grafana
    ports:
      - "3007:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
    restart: unless-stopped

  nginx-gateway:
    image: nginx:alpine
    container_name: edge-ai-gateway
    ports:
      - "30080:80"
    volumes:
      - ./configs/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - ollama
      - onnx-runtime
    restart: unless-stopped

volumes:
  ollama_data:
  grafana_data:
EOF

    # Create configs directory
    mkdir -p configs

    # Create Prometheus config
    cat > configs/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'ollama'
    static_configs:
      - targets: ['ollama:11435']
    metrics_path: /metrics
    scrape_interval: 30s

  - job_name: 'onnx-runtime'
    static_configs:
      - targets: ['onnx-runtime:8001']
    metrics_path: /metrics
    scrape_interval: 30s

  - job_name: 'nginx-gateway'
    static_configs:
      - targets: ['nginx-gateway:80']
    metrics_path: /nginx_status
    scrape_interval: 30s
EOF

    # Create Nginx config
    cat > configs/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream ollama_backend {
        server ollama:11435;
    }

    upstream onnx_backend {
        server onnx-runtime:8001;
    }

    server {
        listen 80;

        location /health {
            return 200 'AI Gateway OK\n';
            add_header Content-Type text/plain;
        }

        location /api/ {
            proxy_pass http://ollama_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_timeout 60s;
        }

        location /v1/ {
            proxy_pass http://onnx_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_timeout 60s;
        }

        location / {
            return 200 'Edge AI Gateway - Available endpoints: /health, /api/, /v1/\n';
            add_header Content-Type text/plain;
        }
    }
}
EOF

    # Deploy services
    log_info "Starting Docker Compose services..."
    docker-compose up -d

    # Wait for services
    log_info "Waiting for services to start..."
    sleep 30

    # Check service health
    log_info "Checking service health..."
    docker-compose ps

    log_info "✅ Docker Compose deployment complete!"

    # Create fake kubeconfig for compatibility
    mkdir -p kubeconfig
    echo "# Docker Compose mode - no kubeconfig needed" > kubeconfig/kubeconfig.yaml
}

# Test services after deployment
test_services() {
    log_step "Testing deployed services..."

    local all_good=true

    # Test endpoints
    log_info "Testing service endpoints..."

    if curl -f -s http://localhost:30080/health >/dev/null 2>&1; then
        log_info "✅ AI Gateway: OK"
    else
        log_error "❌ AI Gateway: FAILED"
        all_good=false
    fi

    if curl -f -s http://localhost:11435/api/tags >/dev/null 2>&1; then
        log_info "✅ Ollama: OK"
    else
        log_warn "⚠️ Ollama: Not ready (may still be starting)"
    fi

    if curl -f -s http://localhost:8001/v1/models >/dev/null 2>&1; then
        log_info "✅ ONNX Runtime: OK"
    else
        log_warn "⚠️ ONNX Runtime: Not ready"
    fi

    if curl -f -s http://localhost:9090/-/healthy >/dev/null 2>&1; then
        log_info "✅ Prometheus: OK"
    else
        log_warn "⚠️ Prometheus: Not ready"
    fi

    if curl -f -s http://localhost:3007/api/health >/dev/null 2>&1; then
        log_info "✅ Grafana: OK"
    else
        log_warn "⚠️ Grafana: Not ready"
    fi

    # Test AI functionality
    log_info "Testing AI functionality..."
    local ai_response
    ai_response=$(curl -s -X POST http://localhost:11435/api/generate \
        -H "Content-Type: application/json" \
        -d '{"model": "llama3.2:1b", "prompt": "Hello", "stream": false}' \
        --max-time 30 2>/dev/null || echo "")

    if [[ -n "$ai_response" ]] && echo "$ai_response" | jq -e '.response' >/dev/null 2>&1; then
        log_info "✅ AI Generation: OK"
        local preview
        preview=$(echo "$ai_response" | jq -r '.response' | head -c 50)
        log_info "Sample response: $preview..."
    else
        log_warn "⚠️ AI Generation: Model may still be downloading"
    fi

    if $all_good; then
        log_info "🎉 All core services are working!"
    else
        log_warn "⚠️ Some services need more time to start"
    fi
}

# Show access information
show_access_info() {
    log_step "📊 Service Access Information"

    cat << EOF

🎯 EDGE AI DEVOPS PORTFOLIO - SERVICE ACCESS

🤖 AI Services:
   • AI Gateway: http://localhost:30080
     - Health: http://localhost:30080/health
     - Ollama API: http://localhost:30080/api/
     - ONNX API: http://localhost:30080/v1/

   • Ollama Direct: http://localhost:11435
   • ONNX Runtime Direct: http://localhost:8001

📊 Monitoring:
   • Prometheus: http://localhost:9090
   • Grafana: http://localhost:3007 (admin/admin)

🔧 Management:
   • Docker Compose: docker-compose ps
   • Service Logs: docker-compose logs [service]
   • Restart: docker-compose restart [service]

📝 Quick Tests:
   curl http://localhost:30080/health
   curl http://localhost:11435/api/tags
   curl -X POST http://localhost:11435/api/generate \\
     -H "Content-Type: application/json" \\
     -d '{"model":"llama3.2:1b","prompt":"Hello AI!"}'

EOF
}

# Main execution
main() {
    case "${1:-diagnose}" in
        "diagnose"|"debug")
            run_diagnosis
            ;;

        "fix")
            run_diagnosis
            fix_k3s_deployment
            deploy_docker_compose_fallback
            test_services
            show_access_info
            ;;

        "deploy-compose"|"compose")
            deploy_docker_compose_fallback
            test_services
            show_access_info
            ;;

        "test")
            test_services
            ;;

        "info"|"status")
            show_access_info
            ;;

        "clean")
            fix_k3s_deployment
            docker-compose down -v 2>/dev/null || true
            rm -f docker-compose.yml configs/prometheus.yml configs/nginx.conf
            log_info "✅ Cleanup complete"
            ;;

        "help"|"--help"|"-h")
            cat << EOF
Debug and Fix Script for Edge AI DevOps Portfolio

USAGE:
    $0 [COMMAND]

COMMANDS:
    diagnose    Run comprehensive system diagnosis (default)
    fix         Fix issues and deploy with Docker Compose
    compose     Deploy with Docker Compose only
    test        Test currently deployed services
    info        Show service access information
    clean       Clean up all resources
    help        Show this help

EXAMPLES:
    $0                  # Run diagnosis
    $0 fix              # Fix issues and redeploy
    $0 compose          # Deploy with Docker Compose
    $0 test             # Test services

EOF
            ;;

        *)
            log_error "Unknown command: $1"
            log_info "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

main "$@"