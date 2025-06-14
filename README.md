# Edge AI DevOps 

> **Minimalistic Infrastructure as Code demonstration showcasing DevOps expertise with AI/LLM integration for edge computing environments.**

**Project by Tom Sapletta** - DevOps Engineer & AI Specialist  
*Demonstrating declarative automation, container orchestration, and modern AI deployment patterns.*

[![Deploy Status](https://img.shields.io/badge/Deploy-Ready-brightgreen)](./scripts/deploy.sh)
[![Infrastructure](https://img.shields.io/badge/IaC-Terraform-blue)](./terraform/)
[![Container](https://img.shields.io/badge/Container-Kubernetes-blue)](./k8s/)
[![AI](https://img.shields.io/badge/AI-ONNX%20%2B%20Ollama-orange)](./configs/)
[![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus%20%2B%20Grafana-red)](./k8s/monitoring.yaml)

## 🚀 Quick Start (2 minutes to live demo)

### Prerequisites
- **Docker Desktop** (running)
- **Terraform** >= 1.6
- **kubectl** >= 1.28
- **8GB RAM** minimum

### One-Command Deployment

```bash
# Clone and deploy
git clone https://github.com/DevOpsTerminal/python-podman-traefik.git edge-ai
cd edge-ai

# Make script executable and deploy everything
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

**🎯 Result**: Complete edge AI platform with monitoring in ~3-5 minutes

### Instant Access

- **🤖 AI Gateway**: http://localhost:30080
- **📊 Grafana**: http://localhost:30030 (admin/admin)
- **📈 Prometheus**: http://localhost:30090

```bash
edge-ai-portfolio/
├── terraform/main.tf          # Infrastruktura (K3s + Docker)
├── k8s/ai-platform.yaml       # AI workloady (ONNX + Ollama)
├── k8s/monitoring.yaml         # Monitoring (Prometheus + Grafana)
├── configs/Modelfile           # Custom LLM konfiguracja
├── scripts/deploy.sh           # Automatyzacja (jeden skrypt)
└── README.md                   # Kompletna dokumentacja
```

## 🏗️ Architecture Overview

```mermaid
graph TB
    U[User] --> G[AI Gateway :30080]
    G --> O[ONNX Runtime]
    G --> L[Ollama LLM]
    
    P[Prometheus :30090] --> O
    P --> L
    P --> G
    
    GR[Grafana :30030] --> P
    
    subgraph "K3s Cluster"
        O
        L
        G
        P
        GR
    end
    
    subgraph "Infrastructure"
        T[Terraform] --> K[K3s]
        K --> O
        K --> L
    end
```

### Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Infrastructure** | Terraform + Docker | IaC provisioning |
| **Orchestration** | K3s (Lightweight Kubernetes) | Container management |
| **AI Inference** | ONNX Runtime + Ollama | Model serving |
| **Load Balancing** | Nginx Gateway | Traffic routing |
| **Monitoring** | Prometheus + Grafana | Observability |
| **Automation** | Bash + YAML | Deployment scripts |

## 🤖 AI Capabilities Demo

### Test ONNX Runtime
```bash
# List available models
curl http://localhost:30080/v1/models

# Model inference (when models are loaded)
curl -X POST http://localhost:30080/v1/models/example/predict \
  -H "Content-Type: application/json" \
  -d '{"data": [[1,2,3,4]]}'
```

### Test Ollama LLM
```bash
# Simple chat
curl -X POST http://localhost:30080/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2:1b",
    "prompt": "Explain edge computing",
    "stream": false
  }'

# Custom edge AI assistant
curl -X POST http://localhost:30080/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "edge-ai-assistant",
    "prompt": "How do I monitor Kubernetes pods?",
    "stream": false
  }'
```

### Interactive Demo
```bash
# Run comprehensive AI functionality test
./scripts/deploy.sh demo

# Test individual components
./scripts/deploy.sh test
```

## 📊 Monitoring & Observability

### Grafana Dashboard
- **URL**: http://localhost:30030
- **Login**: admin/admin
- **Features**:
  - Real-time AI inference metrics
  - Resource utilization monitoring
  - Request latency distribution
  - Error rate tracking
  - Pod health status

### Prometheus Metrics
- **URL**: http://localhost:30090
- **Key Metrics**:
  - `http_requests_total` - Request counters
  - `http_request_duration_seconds` - Latency histograms
  - `container_memory_usage_bytes` - Memory consumption
  - `container_cpu_usage_seconds_total` - CPU utilization

### Health Monitoring
```bash
# Comprehensive health check
./scripts/deploy.sh health

# Check specific components
kubectl get pods -A
kubectl top nodes
kubectl top pods -A
```

## 🛠️ Operations & Maintenance

### Common Operations

```bash
# Check deployment status
./scripts/deploy.sh info

# View live logs
kubectl logs -f deployment/ollama-llm -n ai-inference
kubectl logs -f deployment/onnx-inference -n ai-inference

# Scale AI services
kubectl scale deployment onnx-inference --replicas=3 -n ai-inference

# Update configurations
kubectl apply -f k8s/ai-platform.yaml
```

### Troubleshooting

#### Common Issues and Solutions

**1. Disk Space Issues**
If the deployment fails with eviction errors or the cluster won't start:

```bash
# Check disk space
df -h

# Clean up Docker system
docker system prune -a -f --volumes

# Remove unused containers, networks, and images
docker container prune -f
docker image prune -a -f
docker network prune -f
docker volume prune -f

# Clean up old logs and temporary files
sudo journalctl --vacuum-time=3d
sudo find /var/log -type f -name "*.gz" -delete
sudo find /var/log -type f -name "*.1" -delete
```

**2. Debugging K3s Cluster**
```bash
# Check K3s server logs
docker logs k3s-server

# Check cluster status
docker exec k3s-server kubectl get nodes
docker exec k3s-server kubectl get pods -A
```

**3. Port Conflicts**
If you see port binding errors, check and free up required ports (80, 443, 6443, 30030, 30090, 30080):
```bash
# Check port usage
sudo lsof -i :8080  # Replace with your port number
```

**4. Debugging Pods**
```bash
# Debug pod issues
kubectl describe pod <pod-name> -n ai-inference

# Check resource usage
kubectl top pods -n ai-inference --sort-by=memory

# View events
kubectl get events -n ai-inference --sort-by='.lastTimestamp'

# Restart services
kubectl rollout restart deployment/ollama-llm -n ai-inference
```

**5. Reset Everything**
If you need to start fresh:
```bash
# Clean up all resources
./scripts/deploy.sh cleanup

# Remove all Docker resources
docker system prune -a --volumes --force

# Remove K3s data
sudo rm -rf terraform/kubeconfig/*
sudo rm -rf terraform/k3s-data/*
sudo rm -rf terraform/registry-data/*
```

### Cleanup

```bash
# Complete cleanup
./scripts/deploy.sh cleanup

# Partial cleanup (keep infrastructure)
kubectl delete -f k8s/monitoring.yaml
kubectl delete -f k8s/ai-platform.yaml
```

## 📁 Project Structure

```
edge-ai-portfolio/
├── terraform/
│   └── main.tf                 # Complete infrastructure as code
├── k8s/
│   ├── ai-platform.yaml       # AI workloads (ONNX + Ollama + Gateway)
│   └── monitoring.yaml         # Observability stack (Prometheus + Grafana)
├── configs/
│   └── Modelfile              # Custom LLM configuration
├── scripts/
│   └── deploy.sh              # Automation script (8 commands)
└── README.md                  # This documentation
```

**Total Files**: 6 core files + documentation = **Minimal complexity, maximum demonstration**

## 🎯 Skills Demonstrated

### DevOps Excellence
- ✅ **Infrastructure as Code** - Pure Terraform configuration
- ✅ **Container Orchestration** - Kubernetes/K3s with proper manifests
- ✅ **Declarative Automation** - YAML-driven deployments
- ✅ **Monitoring & Observability** - Production-ready metrics
- ✅ **Security Best Practices** - RBAC, network policies, resource limits
- ✅ **Scalability Patterns** - HPA, resource management
- ✅ **GitOps Ready** - Declarative configuration management

### AI/ML Integration
- ✅ **Model Serving** - ONNX Runtime for optimized inference
- ✅ **LLM Deployment** - Ollama with custom model configuration
- ✅ **Edge Computing** - Resource-constrained deployment patterns
- ✅ **Load Balancing** - Intelligent traffic routing for AI services
- ✅ **Performance Monitoring** - AI-specific metrics and alerting

### Modern Patterns
- ✅ **Microservices Architecture** - Service mesh ready
- ✅ **Cloud Native** - CNCF-aligned tools and patterns
- ✅ **Edge Computing** - Lightweight, distributed deployments
- ✅ **Observability** - Three pillars (metrics, logs, traces)
- ✅ **Automation** - Zero-touch deployment and operations

## 🔧 Customization & Extensions

### Add Custom Models

```bash
# Add new ONNX model
kubectl create configmap my-model --from-file=model.onnx -n ai-inference
# Update deployment to mount the model

# Create custom Ollama model
kubectl exec -n ai-inference deployment/ollama-llm -- \
  ollama create my-custom-model -f /path/to/Modelfile
```

### Scale for Production

```bash
# Multi-node cluster
# Update terraform/main.tf to add worker nodes

# Persistent storage
# Add PVC configurations for model storage

# External load balancer
# Configure LoadBalancer service type

# TLS termination
# Add cert-manager and ingress controller
```

### Advanced Monitoring

```bash
# Add custom metrics
# Extend Prometheus configuration

# Custom dashboards
# Add Grafana dashboard JSON files

# Alerting rules
# Configure AlertManager for notifications
```

## 📈 Performance & Benchmarks

### Resource Usage (Default Configuration)
- **Total Memory**: ~4GB (K3s + AI services + monitoring)
- **CPU Usage**: ~2 cores (under load)
- **Storage**: ~2GB (container images + models)
- **Network**: Minimal (edge-optimized)

### Performance Metrics
- **Deployment Time**: 3-5 minutes (cold start)
- **AI Response Time**: <2s (LLM inference)
- **Monitoring Latency**: <100ms (metrics collection)
- **Scaling Time**: <30s (pod autoscaling)

### Optimization Opportunities
- **Model Quantization**: 4x memory reduction with ONNX INT8
- **Caching**: Redis for frequently accessed inference results
- **Batching**: Group inference requests for better throughput
- **GPU Acceleration**: CUDA/ROCm support for faster inference

## 🌟 Why This Portfolio Project Stands Out

### For Hiring Managers
- **Practical Skills**: Real-world DevOps patterns, not toy examples
- **Modern Stack**: Current best practices and CNCF-aligned tools
- **AI Integration**: Demonstrates understanding of ML deployment challenges
- **Production Ready**: Monitoring, scaling, security considerations
- **Time Efficient**: Complete demo in under 5 minutes

### For Technical Teams
- **Minimal Complexity**: 6 core files, maximum clarity
- **Declarative Approach**: Infrastructure and workloads as code
- **Extensible Architecture**: Easy to add features and scale
- **Edge Optimized**: Real-world resource constraints considered
- **Documentation**: Clear instructions and troubleshooting guides

### For Business Value
- **Fast Deployment**: Rapid prototyping and development cycles
- **Cost Effective**: Efficient resource utilization
- **Scalable Design**: Grows from demo to production
- **Risk Mitigation**: Proven patterns and reliable automation
- **Innovation Ready**: Foundation for AI/ML initiatives

## 🤝 About the Author

**Tom Sapletta** - DevOps Engineer & AI Integration Specialist

- 🔧 **15+ years** enterprise DevOps experience
- 🤖 **AI/LLM deployment** expertise with edge computing focus
- 🏗️ **Infrastructure as Code** advocate and practitioner
- 📊 **Monitoring & Observability** specialist
- 🚀 **Kubernetes & Cloud Native** architect

**Current Focus**: Telemonit - Edge AI power supply systems with integrated LLM capabilities

---

*This portfolio project demonstrates practical DevOps skills through minimal, production-ready code that showcases Infrastructure as Code, AI integration, and modern container orchestration patterns. Perfect for demonstrating technical competency to potential employers in the DevOps and AI engineering space.*

## 📄 License

This project is open source and available under the [Apache License](LICENSE).

---

**🎯 Ready to deploy? Run `./scripts/deploy.sh` and see it in action!**