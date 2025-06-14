#!/bin/bash

#=============================================================================
# Edge AI DevOps - Ansible Test Runner (Fixed)
#
# Comprehensive test automation for infrastructure validation
# Author: Tom Sapletta - DevOps Engineer
#=============================================================================

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly ANSIBLE_DIR="$SCRIPT_DIR"
readonly LOG_FILE="$PROJECT_ROOT/ansible-test.log"

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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $(date '+%H:%M:%S') 🧪 $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log_error "$1"
    exit 1
}

# Setup function
setup_ansible() {
    log_step "Setting up Ansible environment..."

    cd "$ANSIBLE_DIR" || error_exit "Failed to change to ansible directory"

    # Check if ansible is installed
    if ! command -v ansible >/dev/null 2>&1; then
        log_info "Installing Ansible..."

        # Try different installation methods
        if command -v pip3 >/dev/null 2>&1; then
            pip3 install --user ansible>=6.0.0 || error_exit "Failed to install Ansible via pip3"
        elif command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y ansible || error_exit "Failed to install Ansible via apt"
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y ansible || error_exit "Failed to install Ansible via yum"
        else
            error_exit "Cannot install Ansible - no package manager found"
        fi
    fi

    # Verify Ansible version
    local ansible_version
    ansible_version=$(ansible --version | head -1)
    log_info "Using: $ansible_version"

    # Remove problematic vault password file if exists
    if [[ -f ".vault_pass" ]]; then
        log_warn "Removing problematic vault password file..."
        rm -f .vault_pass
    fi

    # Install required collections
    log_info "Installing Ansible collections..."
    if [[ -f "requirements.yml" ]]; then
        ansible-galaxy collection install -r requirements.yml --force || log_warn "Some collections may have failed to install"
    fi

    # Verify Python dependencies
    log_info "Checking Python dependencies..."
    python3 -c "import yaml, requests" 2>/dev/null || {
        log_info "Installing Python dependencies..."
        pip3 install --user pyyaml requests || log_warn "Some Python dependencies may be missing"
    }

    # Try to install kubernetes library
    python3 -c "import kubernetes" 2>/dev/null || {
        log_info "Installing Kubernetes Python library..."
        pip3 install --user kubernetes || log_warn "Kubernetes library installation failed - K8s tests may not work"
    }

    log_info "✅ Ansible environment ready"
}

# Syntax check with better error handling
check_syntax() {
    log_step "Checking Ansible playbook syntax..."

    # First check if playbook exists
    if [[ ! -f "test.yml" ]]; then
        error_exit "Playbook test.yml not found in current directory"
    fi

    # Check syntax with verbose output on failure
    if ansible-playbook test.yml --syntax-check; then
        log_info "✅ Playbook syntax is valid"
    else
        log_error "Syntax check failed. Running with verbose output for debugging..."
        ansible-playbook test.yml --syntax-check -vvv || error_exit "Syntax check failed"
    fi
}

# Dry run with error handling
dry_run() {
    log_step "Running Ansible dry-run (check mode)..."

    # Run with limited verbosity first
    if ansible-playbook test.yml --check --diff -i inventory.yml; then
        log_info "✅ Dry run completed successfully"
    else
        log_warn "Dry run encountered issues. This may be normal if infrastructure is not deployed."
        log_warn "Continuing with actual test run..."
    fi
}

# Test prerequisites
check_prerequisites() {
    log_step "Checking test prerequisites..."

    # Check if infrastructure is deployed
    local infra_ready=false

    # Check for Kubernetes
    if [[ -f "$PROJECT_ROOT/kubeconfig/kubeconfig.yaml" ]]; then
        log_info "Found Kubernetes configuration"
        infra_ready=true
    fi

    # Check for Docker Compose services
    if docker ps | grep -E "(ollama|onnx-runtime|prometheus|grafana)" >/dev/null 2>&1; then
        log_info "Found Docker Compose services running"
        infra_ready=true
    fi

    # Check for basic connectivity
    if curl -f -s http://localhost:30080/health >/dev/null 2>&1 || \
       curl -f -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        log_info "Found responsive AI services"
        infra_ready=true
    fi

    if ! $infra_ready; then
        log_warn "No infrastructure detected. Some tests may fail."
        log_info "To deploy infrastructure first, run: ../scripts/deploy.sh"

        read -p "Continue with tests anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    else
        log_info "✅ Infrastructure appears to be deployed"
    fi
}

# Full test execution with better error handling
run_tests() {
    local test_mode="${1:-full}"

    log_step "Running Ansible infrastructure tests (mode: $test_mode)..."

    # Set extra variables based on test mode
    local extra_vars=""
    local verbosity=""

    case "$test_mode" in
        "quick")
            extra_vars="-e test_timeout=60 -e max_retries=2"
            ;;
        "full")
            extra_vars="-e test_timeout=300 -e max_retries=5"
            ;;
        "debug")
            extra_vars="-e test_timeout=300 -e max_retries=5"
            verbosity="-vvv"
            ;;
        *)
            log_warn "Unknown test mode: $test_mode, using default"
            ;;
    esac

    # Run the playbook with error handling
    log_info "Starting test execution..."
    if ansible-playbook test.yml \
        -i inventory.yml \
        $extra_vars \
        $verbosity \
        --timeout=600; then

        log_info "✅ All tests completed successfully"
        return 0
    else
        local exit_code=$?
        log_error "Test execution failed with exit code: $exit_code"

        # Provide helpful debugging information
        log_info "Debugging information:"
        log_info "- Check log file: $LOG_FILE"
        log_info "- Verify infrastructure is deployed: ../scripts/deploy.sh"
        log_info "- Try with debug mode: $0 debug"

        return $exit_code
    fi
}

# Test specific components with tags
test_component() {
    local component="$1"

    log_step "Testing specific component: $component..."

    # Map component names to appropriate tests
    local test_command=""
    case "$component" in
        "infrastructure"|"infra")
            # Run basic infrastructure tests
            test_command="ansible-playbook test.yml -i inventory.yml --limit localhost -e 'test_focus=infrastructure'"
            ;;
        "networking"|"network")
            # Run network connectivity tests
            test_command="ansible-playbook test.yml -i inventory.yml --limit localhost -e 'test_focus=networking'"
            ;;
        "ai-services"|"ai")
            # Run AI service tests
            test_command="ansible-playbook test.yml -i inventory.yml --limit localhost -e 'test_focus=ai_services'"
            ;;
        "monitoring"|"monitor")
            # Run monitoring tests
            test_command="ansible-playbook test.yml -i inventory.yml --limit localhost -e 'test_focus=monitoring'"
            ;;
        *)
            error_exit "Unknown component: $component. Available: infrastructure, networking, ai-services, monitoring"
            ;;
    esac

    log_info "Running: $test_command"
    if eval "$test_command"; then
        log_info "✅ Component tests completed successfully"
    else
        error_exit "Component tests failed"
    fi
}

# Generate reports
generate_reports() {
    log_step "Generating test reports..."

    # Run tests with focus on reporting
    if ansible-playbook test.yml \
        -i inventory.yml \
        --timeout=600 \
        -e "generate_report=true"; then

        # Check if report was generated
        if [[ -f "$PROJECT_ROOT/test-report.txt" ]]; then
            log_info "✅ Test report generated: $PROJECT_ROOT/test-report.txt"

            # Display summary
            log_info "Test Report Summary:"
            echo "----------------------------------------"
            tail -20 "$PROJECT_ROOT/test-report.txt" || true
            echo "----------------------------------------"
        else
            log_warn "Test report file not found, but tests completed"
        fi
    else
        log_error "Report generation failed"
    fi
}

# Simple connectivity test
quick_connectivity_test() {
    log_step "Running quick connectivity test..."

    local services_ok=0
    local services_total=0

    # Test common endpoints
    local endpoints=(
        "http://localhost:30080/health:AI Gateway"
        "http://localhost:30090/-/healthy:Prometheus"
        "http://localhost:30030/api/health:Grafana"
        "http://localhost:11434/api/tags:Ollama Direct"
        "http://localhost:8001/v1/models:ONNX Direct"
    )

    for endpoint in "${endpoints[@]}"; do
        local url="${endpoint%:*}"
        local name="${endpoint#*:}"

        ((services_total++))

        if curl -f -s --max-time 10 "$url" >/dev/null 2>&1; then
            log_info "✅ $name: OK"
            ((services_ok++))
        else
            log_warn "❌ $name: FAILED"
        fi
    done

    log_info "Quick test result: $services_ok/$services_total services responding"

    if [[ $services_ok -eq 0 ]]; then
        log_error "No services are responding. Infrastructure may not be deployed."
        return 1
    else
        log_info "✅ Quick connectivity test completed"
        return 0
    fi
}

# Main execution with improved error handling
main() {
    # Initialize logging
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "=== Ansible Infrastructure Tests - $(date) ===" > "$LOG_FILE"

    # Change to ansible directory
    if ! cd "$ANSIBLE_DIR" 2>/dev/null; then
        error_exit "Cannot access ansible directory: $ANSIBLE_DIR"
    fi

    case "${1:-full}" in
        "setup")
            setup_ansible
            ;;

        "syntax"|"check")
            setup_ansible
            check_syntax
            ;;

        "dry-run"|"dryrun")
            setup_ansible
            check_syntax
            dry_run
            ;;

        "quick-test"|"ping")
            quick_connectivity_test
            ;;

        "quick")
            setup_ansible
            check_prerequisites
            run_tests "quick"
            ;;

        "full"|"test")
            setup_ansible
            check_prerequisites
            check_syntax
            run_tests "full"
            generate_reports
            ;;

        "debug")
            setup_ansible
            check_prerequisites
            run_tests "debug"
            ;;

        "component")
            if [[ -z "${2:-}" ]]; then
                error_exit "Component name required. Use: infrastructure, networking, ai-services, monitoring"
            fi
            setup_ansible
            test_component "$2"
            ;;

        "report")
            setup_ansible
            generate_reports
            ;;

        "help"|"--help"|"-h")
            cat << EOF
Ansible Test Runner for Edge AI DevOps Portfolio

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    setup       Setup Ansible environment and dependencies
    syntax      Check playbook syntax only
    dry-run     Run in check mode (no changes)
    quick-test  Quick connectivity test (no Ansible)
    quick       Run quick validation tests
    full        Run complete test suite (default)
    debug       Run with verbose debugging output
    component   Test specific component (infrastructure|networking|ai-services|monitoring)
    report      Generate test reports
    help        Show this help message

EXAMPLES:
    $0                          # Full test suite
    $0 setup                    # Setup environment only
    $0 quick-test               # Fast connectivity check
    $0 quick                    # Quick validation
    $0 component ai-services    # Test AI services only
    $0 debug                    # Verbose debugging output

REQUIREMENTS:
    - Infrastructure deployed (../scripts/deploy.sh)
    - Python 3.6+
    - ansible >= 6.0.0

TROUBLESHOOTING:
    $0 setup                    # Fix environment issues
    $0 quick-test               # Test basic connectivity
    $0 syntax                   # Check playbook syntax

OUTPUT:
    - Console output with real-time results
    - Log file: $LOG_FILE
    - Test report: $PROJECT_ROOT/test-report.txt

EOF
            ;;

        *)
            log_error "Unknown command: $1"
            log_info "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"