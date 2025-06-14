#!/bin/bash

#=============================================================================
# Edge AI DevOps - Fixed Deployment Script
#
# Poprawiona wersja z troubleshootingiem dla K3s cluster issues
#=============================================================================

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly KUBECONFIG_PATH="$PROJECT_ROOT/kubeconfig/kubeconfig.yaml"
readonly LOG_FILE="$PROJECT_ROOT/deployment.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%H:%M:%S') $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%H:%M:%S') $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%H:%M:%S') $1" | tee -a "$LOG_FILE"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $(date '+%H:%M:%S') $1" | tee -a "$LOG_FILE"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $(date '+%H:%M:%S') 🚀 $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log_error "$1"
    show_troubleshooting
    exit 1
}

# Troubleshooting helper
show_troubleshooting() {
    cat << 'EOF'

🔧 TROUBLESHOOTING GUIDE:

1. Check Docker is running:
   docker ps

2. Check available resources:
   docker system df
   free -h

3. Clean up Docker system:
   docker system prune -f
   docker volume prune -f

4. Check container logs:
   docker logs k3s-server

5. Manual K3s debugging:
   docker exec -it k3s-server k3s kubectl get nodes
   docker exec -it k3s-server k3s check-config

6. Alternative deployment:
   ./scripts/deploy-fixed.sh kind     # Use KIND instead of K3s
   ./scripts/deploy-fixed.sh local    # Local docker-compose version

EOF
}

# Dependency checks with detailed diagnostics
check_dependencies() {
    log_step "Checking system dependencies and resources..."

    # Check required tools
    local missing_deps=()
    local required_tools=("docker" "terraform" "kubectl" "curl" "jq")

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_deps+=("$tool")
        else
            local version
            version=$(command -v "$tool" && $tool --version 2>/dev/null | head -1 || echo "unknown")
            log_debug "$tool: $version"
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error_exit "Missing required dependencies: ${missing_deps[*]}"
    fi

    # Check Docker status
    if ! docker info >/dev/null 2>&1; then
        error_exit "Docker is not running. Please start Docker and try again."
    fi

    # Detailed Docker diagnostics
    log_info "Docker system info:"
    docker system df

    # Check available resources
    local available_memory total_memory
    available_memory=$(docker system info --format '{{.MemTotal}}' 2>/dev/null || echo "0")
    total_memory=$((available_memory / 1024 / 1024 / 1024))

    log_info "Available memory: ${total_memory}GB"

    if [[ $total_memory -lt 4 ]]; then
        log_warn "Available memory is less than 4GB. Performance may be degraded."
        log_warn "Consider closing other applications or using 'kind' deployment mode."
    fi

    # Check for port conflicts
    local ports=(6443 8080 8443 30080 30090 30030)
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            log_warn "Port $port is already in use. This may cause conflicts."
        fi
    done

    log_info "✅ Dependencies check complete"
}

# Improved K3s deployment with better error handling
deploy_k3s_infrastructure() {
    log_step "Deploying K3s infrastructure with enhanced diagnostics..."

    cd "$PROJECT_ROOT/terraform" || error_exit "Terraform directory not found"

    # Clean up any existing resources first
    log_info "Cleaning up any existing K3s containers..."
    docker rm -f k3s-server 2>/dev/null || true
    docker network rm edge-ai-net 2>/dev/null || true

    # Initialize and apply Terraform
    log_info "Initializing Terraform..."
    terraform init -upgrade || error_exit "Terraform initialization failed"

    log_info "Validating Terraform configuration..."
    terraform validate || error_exit "Terraform validation failed"

    log_info "Planning Terraform deployment..."
    terraform plan -out=tfplan || error_exit "Terraform planning failed"

    log_info "Applying Terraform configuration..."
    terraform apply tfplan || error_exit "Terraform apply failed"

    cd "$PROJECT_ROOT" || exit 1

    # Enhanced K3s readiness check
    log_info "Waiting for K3s cluster to be ready..."
    wait_for_k3s_cluster

    log_info "✅ K3s infrastructure deployed successfully"
}

# Robust K3s cluster readiness check
wait_for_k3s_cluster() {
    local timeout=180  # Increased timeout
    local count=0
    local container_ready=false
    local kubeconfig_ready=false
    local api_ready=false

    while [[ $count -lt $timeout ]]; do
        # Check 1: Container is running
        if ! $container_ready && docker ps --filter "name=k3s-server" --filter "status=running" | grep -q k3s-server; then
            log_info "✅ K3s container is running"
            container_ready=true
        fi

        # Check 2: Kubeconfig file exists and has content
        if ! $kubeconfig_ready && [[ -f "$KUBECONFIG_PATH" ]] && [[ -s "$KUBECONFIG_PATH" ]]; then
            log_info "✅ Kubeconfig file is available"

            # Fix kubeconfig server URL
            sed -i 's|server: https://.*:6443|server: https://localhost:6443|g' "$KUBECONFIG_PATH" 2>/dev/null || true
            export KUBECONFIG="$KUBECONFIG_PATH"
            kubeconfig_ready=true
        fi

        # Check 3: API server is responding
        if $container_ready && $kubeconfig_ready && ! $api_ready; then
            if kubectl cluster-info --request-timeout=5s >/dev/null 2>&1; then
                log_info "✅ Kubernetes API server is responding"
                api_ready=true
                break
            fi
        fi

        # Show progress every 10 seconds
        if [[ $((count % 10)) -eq 0 ]]; then
            log_debug "Waiting for cluster... ($count/$timeout)"
            log_debug "Container: $container_ready, Kubeconfig: $kubeconfig_ready, API: $api_ready"

            # Show container logs for debugging
            if [[ $count -gt 30 ]] && $container_ready; then
                log_debug "Recent K3s container logs:"
                docker logs --tail 5 k3s-server 2>/dev/null || true
            fi
        fi

        sleep 2
        ((count+=2))
    done

    if [[ $count -ge $timeout ]]; then
        log_error "Timeout waiting for K3s cluster to be ready"
        log_error "Final status - Container: $container_ready, Kubeconfig: $kubeconfig_ready, API: $api_ready"

        # Detailed troubleshooting
        log_error "Container status:"
        docker ps -a --filter "name=k3s-server" || true

        log_error "Container logs (last 20 lines):"
        docker logs --tail 20 k3s-server || true

        log_error "Network status:"
        docker network ls | grep edge-ai || true

        error_exit "K3s cluster failed to start properly"
    fi

    # Final verification
    log_info "Verifying cluster functionality..."
    kubectl get nodes -o wide || error_exit "Failed to get cluster nodes"
    kubectl get pods -A || log_warn "Failed to get system pods"

    log_info "Cluster is ready and functional"
}

# Alternative deployment using KIND (Kubernetes in Docker)
deploy_kind_infrastructure() {
    log_step "Deploying KIND (Kubernetes in Docker) infrastructure..."

    # Check if KIND is available
    if ! command -v kind >/dev/null 2>&1; then
        log_info "Installing KIND..."
        # Download KIND
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind || mv ./kind ~/.local/bin/kind
    fi

    # Create KIND cluster configuration
    cat << EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
  - containerPort: 30090
    hostPort: 30090
    protocol: TCP
  - containerPort: 30030
    hostPort: 30030
    protocol: TCP
EOF

    # Create cluster
    log_info "Creating KIND cluster..."
    kind create cluster --name edge-ai --config kind-config.yaml

    # Set kubeconfig
    kind get kubeconfig --name edge-ai > "$KUBECONFIG_PATH"
    export KUBECONFIG="$KUBECONFIG_PATH"

    # Verify cluster
    kubectl cluster-info
    kubectl get nodes

    log_info "✅ KIND infrastructure deployed successfully"
}

# Simplified local Docker Compose deployment
deploy_local_infrastructure() {
    log_step "Deploying local Docker Compose infrastructure..."

    # Create docker-compose.yml for local development
    cat << 'EOF' > docker-compose.yml
version: '3.8'
services:
  ollama:
    image: ollama/ollama:latest
    ports:
      - "11435:11434"
    volumes:
      - ollama_data:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0:11435
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11435/api/tags"]
      interval: 30s
      timeout: 10s
      retries: 5

  onnx-runtime:
    image: mcr.microsoft.com/onnxruntime/server:latest
    ports:
      - "8001:8001"
    environment:
      - ONNX_MODEL_PATH=/models
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/v1/models"]
      interval: 30s
      timeout: 10s
      retries: 5

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./configs/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3007:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana

volumes:
  ollama_data:
  grafana_data:
EOF

    # Create basic Prometheus config
    mkdir -p configs
    cat << 'EOF' > configs/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'ollama'
    static_configs:
      - targets: ['ollama:11435']

  - job_name: 'onnx-runtime'
    static_configs:
      - targets: ['onnx-runtime:8001']
EOF

    # Deploy services
    log_info "Starting Docker Compose services..."
    docker-compose up -d

    # Wait for services
    log_info "Waiting for services to be ready..."
    sleep 30

    # Create fake kubeconfig for script compatibility
    mkdir -p kubeconfig
    echo "# Local Docker Compose deployment - no kubeconfig needed" > "$KUBECONFIG_PATH"

    log_info "✅ Local infrastructure deployed"
    log_info "Services available at:"
    log_info "  - Ollama: http://localhost:11435"
    log_info "  - ONNX Runtime: http://localhost:8001"
    log_info "  - Prometheus: http://localhost:9090"
    log_info "  - Grafana: http://localhost:3007 (admin/admin)"
}

# Enhanced deployment with mode selection
deploy_infrastructure() {
    local deployment_mode="${1:-k3s}"

    case "$deployment_mode" in
        "k3s")
            deploy_k3s_infrastructure
            ;;
        "kind")
            deploy_kind_infrastructure
            ;;
        "local"|"compose")
            deploy_local_infrastructure
            return 0  # Skip Kubernetes deployment for local mode
            ;;
        *)
            error_exit "Unknown deployment mode: $deployment_mode. Use: k3s, kind, or local"
            ;;
    esac
}

# Robust AI platform deployment with retries
deploy_ai_platform() {
    log_step "Deploying AI inference platform..."

    export KUBECONFIG="$KUBECONFIG_PATH"

    # Apply with retries
    local max_retries=3
    local retry=0

    while [[ $retry -lt $max_retries ]]; do
        if kubectl apply -f "$PROJECT_ROOT/k8s/ai-platform.yaml"; then
            break
        else
            ((retry++))
            log_warn "Retry $retry/$max_retries for AI platform deployment..."
            sleep 10
        fi
    done

    if [[ $retry -eq $max_retries ]]; then
        error_exit "Failed to deploy AI platform after $max_retries retries"
    fi

    # Wait for deployments with extended timeout
    log_info "Waiting for AI services (this may take 5-10 minutes for first-time model downloads)..."

    # Wait for namespace
    kubectl wait --for=condition=Ready namespace/ai-inference --timeout=60s || log_warn "Namespace wait timeout"

    # Wait for deployments individually with different timeouts
    log_info "Waiting for ONNX Runtime..."
    kubectl wait --for=condition=available --timeout=300s deployment/onnx-inference -n ai-inference || log_warn "ONNX timeout"

    log_info "Waiting for AI Gateway..."
    kubectl wait --for=condition=available --timeout=180s deployment/ai-gateway -n ai-inference || log_warn "Gateway timeout"

    log_info "Waiting for Ollama (this takes longest due to model download)..."
    kubectl wait --for=condition=available --timeout=900s deployment/ollama-llm -n ai-inference || log_warn "Ollama timeout - continuing anyway"

    # Show status regardless of timeouts
    log_info "AI Platform status:"
    kubectl get pods -n ai-inference -o wide
    kubectl get svc -n ai-inference

    log_info "✅ AI platform deployment complete (some services may still be initializing)"
}

# Enhanced monitoring deployment
deploy_monitoring() {
    log_step "Deploying monitoring stack..."

    export KUBECONFIG="$KUBECONFIG_PATH"

    kubectl apply -f "$PROJECT_ROOT/k8s/monitoring.yaml" || error_exit "Failed to apply monitoring manifests"

    log_info "Waiting for monitoring services..."
    kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring || log_warn "Prometheus timeout"
    kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring || log_warn "Grafana timeout"

    log_info "Monitoring stack status:"
    kubectl get pods -n monitoring -o wide
    kubectl get svc -n monitoring

    log_info "✅ Monitoring stack deployed"
}

# Main execution with mode support
main() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "=== Edge AI DevOps Deployment - $(date) ===" > "$LOG_FILE"

    local deployment_mode="k3s"
    local command="${1:-deploy}"

    # Parse arguments
    if [[ $# -gt 1 ]]; then
        deployment_mode="$2"
    fi

    case "$command" in
        "deploy")
            log_info "🚀 Starting Edge AI platform deployment (mode: $deployment_mode)..."
            check_dependencies
            deploy_infrastructure "$deployment_mode"

            if [[ "$deployment_mode" != "local" ]]; then
                deploy_ai_platform
                deploy_monitoring
            fi

            log_info "🎉 Deployment complete!"
            log_info "Check the services and run health checks as needed."
            ;;

        "k3s"|"kind"|"local")
            main deploy "$command"
            ;;

        "troubleshoot"|"debug")
            log_info "🔧 Running troubleshooting diagnostics..."
            check_dependencies

            # Docker diagnostics
            log_info "Docker containers:"
            docker ps -a

            log_info "Docker logs for k3s-server:"
            docker logs k3s-server 2>/dev/null || log_warn "No k3s-server container found"

            # Kubernetes diagnostics if available
            if [[ -f "$KUBECONFIG_PATH" ]]; then
                export KUBECONFIG="$KUBECONFIG_PATH"
                log_info "Kubernetes cluster info:"
                kubectl cluster-info || log_warn "Cluster not accessible"
                kubectl get nodes || log_warn "No nodes found"
                kubectl get pods -A || log_warn "No pods found"
            fi
            ;;

        "cleanup")
            log_info "🧹 Cleaning up all resources..."

            # Stop docker-compose if exists
            [[ -f docker-compose.yml ]] && docker-compose down -v 2>/dev/null || true

            # Cleanup KIND cluster
            kind delete cluster --name edge-ai 2>/dev/null || true

            # Cleanup K3s via Terraform
            if [[ -d "$PROJECT_ROOT/terraform" ]]; then
                cd "$PROJECT_ROOT/terraform"
                terraform destroy -auto-approve || log_warn "Terraform destroy issues"
                cd "$PROJECT_ROOT"
            fi

            # Cleanup files
            rm -rf kubeconfig k3s-data registry-data docker-compose.yml kind-config.yaml configs/prometheus.yml
            rm -f terraform/tfplan terraform/.terraform.lock.hcl

            log_info "✅ Cleanup complete"
            ;;

        "help"|"--help"|"-h")
            cat << EOF
Edge AI DevOps - Enhanced Deployment Script

USAGE:
    $0 [COMMAND] [MODE]

COMMANDS:
    deploy      Deploy complete platform (default)
    k3s         Deploy using K3s in Docker (default mode)
    kind        Deploy using KIND (Kubernetes in Docker)
    local       Deploy using Docker Compose (no Kubernetes)
    troubleshoot Run diagnostics and troubleshooting
    cleanup     Remove all resources
    help        Show this help

DEPLOYMENT MODES:
    k3s         K3s cluster in Docker container (default)
    kind        KIND cluster (alternative if K3s fails)
    local       Docker Compose only (fastest, limited features)

EXAMPLES:
    $0                     # Deploy with K3s
    $0 deploy k3s          # Deploy with K3s (explicit)
    $0 deploy kind         # Deploy with KIND
    $0 deploy local        # Deploy with Docker Compose
    $0 troubleshoot        # Run diagnostics
    $0 cleanup             # Clean everything

TROUBLESHOOTING:
If K3s deployment fails, try:
    $0 cleanup && $0 deploy kind    # Use KIND instead
    $0 cleanup && $0 deploy local   # Use Docker Compose

EOF
            ;;

        *)
            log_error "Unknown command: $command"
            log_info "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

main "$@"