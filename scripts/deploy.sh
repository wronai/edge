#!/bin/bash

#=============================================================================
# Edge AI DevOps Portfolio - Deployment Script
#
# Minimalna implementacja deployment'u dla portfolio Tom Sapletta
# Demonstruje IaC, Kubernetes, AI/LLM integration i monitoring
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
readonly NC='\033[0m' # No Color

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
    log_error "Deployment failed. Check $LOG_FILE for details."
    exit 1
}

# Cleanup on exit
cleanup_on_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script failed with exit code $exit_code"
        log_info "Run './scripts/deploy.sh cleanup' to clean up resources"
    fi
}
trap cleanup_on_exit EXIT

# Dependency checks
check_dependencies() {
    log_step "Checking system dependencies..."

    local missing_deps=()

    # Required tools
    local required_tools=("docker" "terraform" "kubectl" "curl" "jq")

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_deps+=("$tool")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error_exit "Missing required dependencies: ${missing_deps[*]}"
    fi

    # Check Docker is running
    if ! docker info >/dev/null 2>&1; then
        error_exit "Docker is not running. Please start Docker and try again."
    fi

    # Check available resources
    local available_memory
    available_memory=$(docker system info --format '{{.MemTotal}}' 2>/dev/null || echo "0")
    if [[ $available_memory -lt 4294967296 ]]; then  # 4GB in bytes
        log_warn "Available memory is less than 4GB. Performance may be degraded."
    fi

    log_info "✅ All dependencies satisfied"
}

# Infrastructure deployment with Terraform
deploy_infrastructure() {
    log_step "Deploying infrastructure with Terraform..."

    cd "$PROJECT_ROOT/terraform" || error_exit "Terraform directory not found"

    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init -upgrade || error_exit "Terraform initialization failed"

    # Validate configuration
    log_info "Validating Terraform configuration..."
    terraform validate || error_exit "Terraform validation failed"

    # Plan deployment
    log_info "Planning Terraform deployment..."
    terraform plan -out=tfplan -detailed-exitcode || {
        local exit_code=$?
        if [[ $exit_code -eq 2 ]]; then
            log_info "Changes detected, proceeding with apply..."
        else
            error_exit "Terraform planning failed"
        fi
    }

    # Apply infrastructure
    log_info "Applying Terraform configuration..."
    terraform apply tfplan || error_exit "Terraform apply failed"

    cd "$PROJECT_ROOT" || exit 1

    # Wait for K3s to be ready
    log_info "Waiting for K3s cluster to be ready..."
    local timeout=120
    local count=0

    while [[ $count -lt $timeout ]]; do
        if [[ -f "$KUBECONFIG_PATH" ]]; then
            log_info "Kubeconfig found, testing cluster connectivity..."
            export KUBECONFIG="$KUBECONFIG_PATH"

            if kubectl cluster-info --request-timeout=10s >/dev/null 2>&1; then
                log_info "✅ K3s cluster is ready"
                break
            fi
        fi

        log_debug "Waiting for cluster... ($count/$timeout)"
        sleep 2
        ((count+=2))
    done

    if [[ $count -ge $timeout ]]; then
        error_exit "Timeout waiting for K3s cluster to be ready"
    fi

    # Verify cluster status
    log_info "Cluster status:"
    kubectl get nodes -o wide || log_warn "Failed to get node status"

    log_info "✅ Infrastructure deployed successfully"
}

# Deploy AI platform workloads
deploy_ai_platform() {
    log_step "Deploying AI inference platform..."

    export KUBECONFIG="$KUBECONFIG_PATH"

    # Apply AI platform manifests
    log_info "Applying AI platform manifests..."
    kubectl apply -f "$PROJECT_ROOT/k8s/ai-platform.yaml" || error_exit "Failed to apply AI platform manifests"

    # Wait for namespace to be ready
    log_info "Waiting for ai-inference namespace..."
    kubectl wait --for=condition=Ready namespace/ai-inference --timeout=60s || log_warn "Namespace wait timeout"

    # Wait for deployments to be ready
    log_info "Waiting for AI services to be ready (this may take several minutes)..."

    # ONNX Runtime
    log_info "Waiting for ONNX Runtime deployment..."
    kubectl wait --for=condition=available --timeout=300s deployment/onnx-inference -n ai-inference || log_warn "ONNX deployment timeout"

    # AI Gateway
    log_info "Waiting for AI Gateway deployment..."
    kubectl wait --for=condition=available --timeout=180s deployment/ai-gateway -n ai-inference || log_warn "AI Gateway timeout"

    # Check Ollama separately (it takes longer)
    log_info "Checking Ollama LLM status..."
    kubectl wait --for=condition=available --timeout=600s deployment/ollama-llm -n ai-inference || log_warn "Ollama deployment timeout (continuing anyway)"

    # Verify pod status
    log_info "AI Platform pod status:"
    kubectl get pods -n ai-inference -o wide

    # Check service endpoints
    log_info "AI Platform services:"
    kubectl get svc -n ai-inference

    log_info "✅ AI platform deployed"
}

# Deploy monitoring stack
deploy_monitoring() {
    log_step "Deploying monitoring stack..."

    export KUBECONFIG="$KUBECONFIG_PATH"

    # Apply monitoring manifests
    log_info "Applying monitoring manifests..."
    kubectl apply -f "$PROJECT_ROOT/k8s/monitoring.yaml" || error_exit "Failed to apply monitoring manifests"

    # Wait for monitoring services
    log_info "Waiting for monitoring services..."

    # Prometheus
    log_info "Waiting for Prometheus deployment..."
    kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring || log_warn "Prometheus deployment timeout"

    # Grafana
    log_info "Waiting for Grafana deployment..."
    kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring || log_warn "Grafana deployment timeout"

    # Verify monitoring status
    log_info "Monitoring stack status:"
    kubectl get pods -n monitoring -o wide
    kubectl get svc -n monitoring

    log_info "✅ Monitoring stack deployed"
}

# Setup custom Ollama model
setup_ollama_model() {
    log_step "Setting up custom Ollama model..."

    export KUBECONFIG="$KUBECONFIG_PATH"

    # Wait for Ollama to be fully ready
    log_info "Ensuring Ollama is ready..."
    kubectl wait --for=condition=available --timeout=600s deployment/ollama-llm -n ai-inference || {
        log_warn "Ollama may not be fully ready, attempting model setup anyway..."
    }

    # Check if Ollama pod is running
    local ollama_pod
    ollama_pod=$(kubectl get pods -n ai-inference -l app=ollama-llm -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

    if [[ -z "$ollama_pod" ]]; then
        log_warn "Ollama pod not found, skipping custom model setup"
        return 0
    fi

    log_info "Found Ollama pod: $ollama_pod"

    # Copy Modelfile to pod
    log_info "Copying custom Modelfile to Ollama pod..."
    kubectl cp "$PROJECT_ROOT/configs/Modelfile" "ai-inference/$ollama_pod:/tmp/Modelfile" || log_warn "Failed to copy Modelfile"

    # Create custom model
    log_info "Creating edge-ai-assistant model..."
    kubectl exec -n ai-inference "$ollama_pod" -- sh -c "
        echo 'Creating custom edge-ai-assistant model...'
        ollama create edge-ai-assistant -f /tmp/Modelfile 2>/dev/null || echo 'Model creation failed or already exists'
        echo 'Available models:'
        ollama list
    " || log_warn "Custom model setup may need manual intervention"

    log_info "✅ Ollama model setup complete"
}

# Run comprehensive health checks
health_check() {
    log_step "Running health checks..."

    export KUBECONFIG="$KUBECONFIG_PATH"

    local health_status=0

    # Check cluster health
    log_info "Checking cluster health..."
    if ! kubectl cluster-info --request-timeout=10s >/dev/null 2>&1; then
        log_error "Cluster is not responding"
        ((health_status++))
    else
        log_info "✅ Cluster is healthy"
    fi

    # Check AI services
    log_info "Checking AI services..."
    local ai_services=("onnx-inference" "ollama-llm" "ai-gateway")

    for service in "${ai_services[@]}"; do
        local ready_replicas
        ready_replicas=$(kubectl get deployment "$service" -n ai-inference -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        local desired_replicas
        desired_replicas=$(kubectl get deployment "$service" -n ai-inference -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")

        if [[ "$ready_replicas" -eq "$desired_replicas" ]]; then
            log_info "✅ $service: $ready_replicas/$desired_replicas ready"
        else
            log_warn "❌ $service: $ready_replicas/$desired_replicas ready"
            ((health_status++))
        fi
    done

    # Check monitoring services
    log_info "Checking monitoring services..."
    local monitoring_services=("prometheus" "grafana")

    for service in "${monitoring_services[@]}"; do
        local ready_replicas
        ready_replicas=$(kubectl get deployment "$service" -n monitoring -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")

        if [[ "$ready_replicas" -gt 0 ]]; then
            log_info "✅ $service: ready"
        else
            log_warn "❌ $service: not ready"
            ((health_status++))
        fi
    done

    # Test external endpoints
    log_info "Testing external endpoints..."

    # AI Gateway
    if curl -f -s http://localhost:30080/health >/dev/null 2>&1; then
        log_info "✅ AI Gateway: responding"
    else
        log_warn "❌ AI Gateway: not responding"
        ((health_status++))
    fi

    # Prometheus
    if curl -f -s http://localhost:30090/-/healthy >/dev/null 2>&1; then
        log_info "✅ Prometheus: responding"
    else
        log_warn "❌ Prometheus: not responding"
        ((health_status++))
    fi

    # Grafana
    if curl -f -s http://localhost:30030/api/health >/dev/null 2>&1; then
        log_info "✅ Grafana: responding"
    else
        log_warn "❌ Grafana: not responding"
        ((health_status++))
    fi

    # Resource usage summary
    log_info "Resource usage summary:"
    kubectl top nodes 2>/dev/null || log_warn "Node metrics not available"
    kubectl top pods -A --sort-by=memory 2>/dev/null | head -10 || log_warn "Pod metrics not available"

    if [[ $health_status -eq 0 ]]; then
        log_info "✅ All health checks passed"
    else
        log_warn "❌ $health_status health check(s) failed"
    fi

    return $health_status
}

# AI functionality tests
test_ai_functionality() {
    log_step "Testing AI functionality..."

    # Test ONNX Runtime
    log_info "Testing ONNX Runtime..."
    if curl -f -s "http://localhost:30080/v1/models" >/dev/null 2>&1; then
        log_info "✅ ONNX Runtime: accessible"
    else
        log_warn "❌ ONNX Runtime: not accessible"
    fi

    # Test Ollama LLM
    log_info "Testing Ollama LLM..."
    local test_response
    test_response=$(curl -s -X POST "http://localhost:30080/api/generate" \
        -H "Content-Type: application/json" \
        -d '{"model": "llama3.2:1b", "prompt": "Hello", "stream": false}' \
        --max-time 30 2>/dev/null || echo "")

    if [[ -n "$test_response" ]] && echo "$test_response" | jq -e '.response' >/dev/null 2>&1; then
        log_info "✅ Ollama LLM: responding"
        local response_text
        response_text=$(echo "$test_response" | jq -r '.response' | head -c 50)
        log_debug "Sample response: $response_text..."
    else
        log_warn "❌ Ollama LLM: not responding properly"
    fi

    # Test custom model if available
    log_info "Testing custom edge-ai-assistant model..."
    local custom_response
    custom_response=$(curl -s -X POST "http://localhost:30080/api/generate" \
        -H "Content-Type: application/json" \
        -d '{"model": "edge-ai-assistant", "prompt": "What is edge computing?", "stream": false}' \
        --max-time 30 2>/dev/null || echo "")

    if [[ -n "$custom_response" ]] && echo "$custom_response" | jq -e '.response' >/dev/null 2>&1; then
        log_info "✅ Custom edge-ai-assistant model: working"
    else
        log_warn "❌ Custom edge-ai-assistant model: not available"
    fi
}

# Display access information
show_access_info() {
    log_step "📊 Access Information"

    cat << EOF

🤖 AI GATEWAY:
   URL: http://localhost:30080
   Health: http://localhost:30080/health

   API Endpoints:
   • ONNX Models: GET http://localhost:30080/v1/models
   • Ollama Chat: POST http://localhost:30080/api/generate

   Example Usage:
   curl http://localhost:30080/v1/models
   curl -X POST http://localhost:30080/api/generate \\
     -H "Content-Type: application/json" \\
     -d '{"model":"llama3.2:1b","prompt":"Hello AI!"}'

📈 MONITORING:
   • Prometheus: http://localhost:30090
   • Grafana: http://localhost:30030 (admin/admin)
   • AlertManager: http://localhost:30093

🔧 KUBERNETES:
   • Kubeconfig: $KUBECONFIG_PATH
   • Cluster: https://localhost:6443

   Quick Commands:
   export KUBECONFIG="$KUBECONFIG_PATH"
   kubectl get pods -A
   kubectl logs -f deployment/ollama-llm -n ai-inference

📁 PROJECT STRUCTURE:
   • Infrastructure: terraform/
   • Workloads: k8s/
   • Configs: configs/
   • Logs: $LOG_FILE

EOF

    log_info "🎉 Edge AI DevOps Portfolio deployed successfully!"
    log_info "Total deployment time: $(( $(date +%s) - ${DEPLOYMENT_START_TIME:-$(date +%s)} )) seconds"
}

# Cleanup function
cleanup() {
    log_step "🧹 Cleaning up resources..."

    export KUBECONFIG="$KUBECONFIG_PATH"

    # Delete Kubernetes resources
    log_info "Removing Kubernetes resources..."
    kubectl delete -f "$PROJECT_ROOT/k8s/monitoring.yaml" --ignore-not-found=true --timeout=60s || log_warn "Failed to delete monitoring resources"
    kubectl delete -f "$PROJECT_ROOT/k8s/ai-platform.yaml" --ignore-not-found=true --timeout=60s || log_warn "Failed to delete AI platform resources"

    # Destroy Terraform infrastructure
    log_info "Destroying Terraform infrastructure..."
    cd "$PROJECT_ROOT/terraform" || exit 1
    terraform destroy -auto-approve || log_warn "Terraform destroy encountered issues"
    cd "$PROJECT_ROOT" || exit 1

    # Clean up local files
    log_info "Cleaning up local files..."
    rm -rf "$PROJECT_ROOT/kubeconfig" "$PROJECT_ROOT/k3s-data" "$PROJECT_ROOT/registry-data" 2>/dev/null || true
    rm -f "$PROJECT_ROOT/terraform/tfplan" "$PROJECT_ROOT/terraform/.terraform.lock.hcl" 2>/dev/null || true

    log_info "✅ Cleanup complete"
}

# Quick demo function
run_demo() {
    log_step "🎬 Running AI Demo..."

    log_info "Testing AI Gateway endpoints..."

    # Test health endpoint
    echo "1. Health Check:"
    curl -s http://localhost:30080/health || echo "Health check failed"
    echo -e "\n"

    # Test ONNX models
    echo "2. ONNX Models:"
    curl -s http://localhost:30080/v1/models | jq . 2>/dev/null || echo "ONNX not available"
    echo -e "\n"

    # Test Ollama chat
    echo "3. Ollama Chat Test:"
    curl -s -X POST http://localhost:30080/api/generate \
        -H "Content-Type: application/json" \
        -d '{"model": "llama3.2:1b", "prompt": "Explain edge computing in one sentence.", "stream": false}' \
        --max-time 30 | jq -r '.response // "No response"' 2>/dev/null || echo "Ollama not available"
    echo -e "\n"

    # Test custom model
    echo "4. Custom Edge AI Assistant:"
    curl -s -X POST http://localhost:30080/api/generate \
        -H "Content-Type: application/json" \
        -d '{"model": "edge-ai-assistant", "prompt": "How do I monitor Kubernetes pods?", "stream": false}' \
        --max-time 30 | jq -r '.response // "Custom model not available"' 2>/dev/null || echo "Custom model not available"

    log_info "🎬 Demo complete"
}

# Main execution function
main() {
    # Initialize logging
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "=== Edge AI DevOps Portfolio Deployment - $(date) ===" > "$LOG_FILE"

    export DEPLOYMENT_START_TIME=$(date +%s)

    case "${1:-deploy}" in
        "deploy")
            log_info "🚀 Starting complete Edge AI DevOps platform deployment..."
            check_dependencies
            deploy_infrastructure
            deploy_ai_platform
            deploy_monitoring
            setup_ollama_model
            sleep 10  # Allow services to stabilize
            health_check || log_warn "Some health checks failed"
            show_access_info
            ;;

        "infrastructure"|"infra")
            log_info "🏗️ Deploying infrastructure only..."
            check_dependencies
            deploy_infrastructure
            ;;

        "ai"|"ai-platform")
            log_info "🤖 Deploying AI platform only..."
            deploy_ai_platform
            setup_ollama_model
            ;;

        "monitoring")
            log_info "📊 Deploying monitoring stack only..."
            deploy_monitoring
            ;;

        "health"|"check")
            health_check
            ;;

        "test")
            test_ai_functionality
            ;;

        "demo")
            run_demo
            ;;

        "cleanup"|"destroy"|"clean")
            cleanup
            ;;

        "info"|"status")
            show_access_info
            ;;

        "logs")
            log_info "Showing recent logs from $LOG_FILE"
            tail -f "$LOG_FILE"
            ;;

        "help"|"--help"|"-h")
            cat << EOF
Edge AI DevOps Portfolio - Deployment Script

USAGE:
    $0 [COMMAND]

COMMANDS:
    deploy       Deploy complete platform (default)
    infra        Deploy infrastructure only (Terraform + K3s)
    ai-platform  Deploy AI services only
    monitoring   Deploy monitoring stack only
    health       Run health checks
    test         Test AI functionality
    demo         Run interactive AI demo
    cleanup      Remove all resources
    info         Show access information
    logs         Show deployment logs
    help         Show this help message

EXAMPLES:
    $0                    # Full deployment
    $0 deploy             # Full deployment
    $0 health             # Check system health
    $0 test               # Test AI functionality
    $0 demo               # Interactive demo
    $0 cleanup            # Clean up everything

REQUIREMENTS:
    - Docker Desktop running
    - Terraform >= 1.6
    - kubectl >= 1.28
    - curl, jq
    - 4GB+ RAM available

DEPLOYMENT TIME: ~3-5 minutes
ACCESS URLS:
    - AI Gateway: http://localhost:30080
    - Grafana: http://localhost:30030 (admin/admin)
    - Prometheus: http://localhost:30090

EOF
            ;;

        *)
            log_error "Unknown command: $1"
            log_info "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"