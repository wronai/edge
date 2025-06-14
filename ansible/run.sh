#!/bin/bash

#=============================================================================
# Edge AI DevOps Portfolio - Ansible Test Runner
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
        pip3 install ansible>=6.0.0 || error_exit "Failed to install Ansible"
    fi

    # Install required collections
    log_info "Installing Ansible collections..."
    ansible-galaxy collection install -r requirements.yml --force || error_exit "Failed to install collections"

    # Verify Python dependencies
    log_info "Installing Python dependencies..."
    pip3 install kubernetes pyyaml requests || log_warn "Some Python dependencies may be missing"

    log_info "✅ Ansible environment ready"
}

# Syntax check
check_syntax() {
    log_step "Checking Ansible playbook syntax..."

    ansible-playbook test.yml --syntax-check || error_exit "Syntax check failed"

    log_info "✅ Playbook syntax is valid"
}

# Dry run
dry_run() {
    log_step "Running Ansible dry-run (check mode)..."

    ansible-playbook test.yml --check --diff -v || error_exit "Dry run failed"

    log_info "✅ Dry run completed successfully"
}

# Full test execution
run_tests() {
    local test_mode="${1:-full}"

    log_step "Running Ansible infrastructure tests (mode: $test_mode)..."

    # Set extra variables based on test mode
    local extra_vars=""
    case "$test_mode" in
        "quick")
            extra_vars="-e test_timeout=60 -e max_retries=2"
            ;;
        "full")
            extra_vars="-e test_timeout=300 -e max_retries=5"
            ;;
        "debug")
            extra_vars="-e test_timeout=300 -e max_retries=5 -vvv"
            ;;
        *)
            log_warn "Unknown test mode: $test_mode, using default"
            ;;
    esac

    # Run the playbook
    ansible-playbook test.yml \
        -i inventory.yml \
        $extra_vars \
        --timeout=600 \
        || error_exit "Test execution failed"

    log_info "✅ All tests completed"
}

# Test specific components
test_component() {
    local component="$1"

    log_step "Testing specific component: $component..."

    case "$component" in
        "infrastructure")
            ansible-playbook test.yml -i inventory.yml --tags "infrastructure" || error_exit "Infrastructure tests failed"
            ;;
        "networking")
            ansible-playbook test.yml -i inventory.yml --tags "networking" || error_exit "Network tests failed"
            ;;
        "ai-services")
            ansible-playbook test.yml -i inventory.yml --tags "ai-services" || error_exit "AI services tests failed"
            ;;
        "monitoring")
            ansible-playbook test.yml -i inventory.yml --tags "monitoring" || error_exit "Monitoring tests failed"
            ;;
        *)
            error_exit "Unknown component: $component"
            ;;
    esac

    log_info "✅ Component tests completed"
}

# Generate reports
generate_reports() {
    log_step "Generating test reports..."

    # Run tests with JSON output for reporting
    ansible-playbook test.yml \
        -i inventory.yml \
        --timeout=600 \
        -e "report_format=json" \
        || log_warn "Report generation encountered issues"

    # Check if report was generated
    if [[ -f "$PROJECT_ROOT/test-report.txt" ]]; then
        log_info "Test report available at: $PROJECT_ROOT/test-report.txt"

        # Display summary
        log_info "Test Report Summary:"
        tail -20 "$PROJECT_ROOT/test-report.txt" || true
    fi

    log_info "✅ Reports generated"
}

# Validate infrastructure before testing
validate_infrastructure() {
    log_step "Validating infrastructure is ready for testing..."

    # Check if deployment exists
    if [[ ! -f "$PROJECT_ROOT/kubeconfig/kubeconfig.yaml" ]] && ! docker ps | grep -q "ollama\|onnx-runtime\|prometheus\|grafana"; then
        log_error "No infrastructure detected. Please deploy first:"
        log_error "  ./scripts/deploy.sh deploy"
        error_exit "Infrastructure not ready"
    fi

    # Basic connectivity test
    if curl -f -s http://localhost:30080/health >/dev/null 2>&1 || curl -f -s http://localhost:11435/api/tags >/dev/null 2>&1; then
        log_info "✅ Infrastructure is accessible"
    else
        log_warn "Infrastructure may not be fully ready, proceeding anyway..."
    fi
}

# Continuous testing mode
continuous_tests() {
    local interval="${1:-300}"  # Default 5 minutes

    log_step "Starting continuous testing mode (interval: ${interval}s)..."

    while true; do
        log_info "Running scheduled test cycle..."

        if run_tests "quick"; then
            log_info "✅ Scheduled tests passed"
        else
            log_error "❌ Scheduled tests failed"
        fi

        log_info "Next test cycle in ${interval} seconds..."
        sleep "$interval"
    done
}

# Performance testing
performance_tests() {
    log_step "Running performance and load tests..."

    # Run tests with performance monitoring
    ansible-playbook test.yml \
        -i inventory.yml \
        -e "enable_performance_tests=true" \
        -e "test_concurrent_requests=10" \
        -e "test_duration=60" \
        || error_exit "Performance tests failed"

    log_info "✅ Performance tests completed"
}

# Security testing
security_tests() {
    log_step "Running security validation tests..."

    # Run security-focused tests
    ansible-playbook test.yml \
        -i inventory.yml \
        -e "enable_security_tests=true" \
        || error_exit "Security tests failed"

    log_info "✅ Security tests completed"
}

# Main execution
main() {
    # Initialize logging
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "=== Ansible Infrastructure Tests - $(date) ===" > "$LOG_FILE"

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

        "quick")
            setup_ansible
            validate_infrastructure
            run_tests "quick"
            ;;

        "full"|"test")
            setup_ansible
            validate_infrastructure
            check_syntax
            run_tests "full"
            generate_reports
            ;;

        "debug")
            setup_ansible
            validate_infrastructure
            run_tests "debug"
            ;;

        "component")
            if [[ -z "${2:-}" ]]; then
                error_exit "Component name required. Use: infrastructure, networking, ai-services, monitoring"
            fi
            setup_ansible
            validate_infrastructure
            test_component "$2"
            ;;

        "performance"|"perf")
            setup_ansible
            validate_infrastructure
            performance_tests
            ;;

        "security"|"sec")
            setup_ansible
            validate_infrastructure
            security_tests
            ;;

        "continuous")
            setup_ansible
            validate_infrastructure
            continuous_tests "${2:-300}"
            ;;

        "report")
            setup_ansible
            validate_infrastructure
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
    quick       Run quick tests (reduced timeouts)
    full        Run complete test suite (default)
    debug       Run with verbose debugging output
    component   Test specific component (infrastructure|networking|ai-services|monitoring)
    performance Run performance and load tests
    security    Run security validation tests
    continuous  Run tests continuously [interval_seconds]
    report      Generate test reports
    help        Show this help message

EXAMPLES:
    $0                          # Full test suite
    $0 quick                    # Quick validation
    $0 component ai-services    # Test AI services only
    $0 continuous 600           # Run tests every 10 minutes
    $0 debug                    # Verbose debugging output

REQUIREMENTS:
    - Infrastructure deployed (./scripts/deploy.sh)
    - Python 3.6+
    - ansible >= 6.0.0
    - kubernetes python library

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

# Change to ansible directory
cd "$ANSIBLE_DIR" || error_exit "Cannot access ansible directory"

# Execute main function
main "$@"