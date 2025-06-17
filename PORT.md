# Declarative Edge AI DevOps Project

A comprehensive project designed for experienced DevOps professionals to showcase modern Infrastructure as Code, AI/LLM integration, and declarative automation skills through minimal imperative coding. This project can be implemented in 1-2 hours while demonstrating production-ready patterns valued by employers in 2025.

## Project overview: Multi-edge AI inference platform

The project demonstrates a **hybrid cloud-edge AI inference platform** that deploys and manages LLM models across multiple edge locations using pure declarative configurations. This architecture showcases both DevOps expertise and AI integration capabilities while minimizing custom code development.

## Getting started checklist

### Prerequisites
- [ ] Terraform installed (v1.6+)
- [ ] kubectl configured
- [ ] Git repository set up
- [ ] Edge hardware available (or cloud instances)
- [ ] Docker Hub or container registry access

### Quick start commands
```bash
# Infrastructure provisioning
terraform init && terraform plan && terraform apply

# GitOps setup
kubectl apply -f argocd/bootstrap/
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server

# Application deployment
kubectl apply -f argocd/applications/edge-ai-platform.yaml

# Monitoring verification
kubectl port-forward svc/grafana 3007:3000
```

This project successfully demonstrates Tom's expertise in DevOps, AI/LLM integration, and modern declarative practices while remaining achievable within the 1-2 hour timeframe. It showcases industry-relevant skills that employers value in 2025, emphasizing configuration management and automation over custom application development.


# 🚀 Immediate Fix Commands

## 📊 **Diagnosis Summary:**
- ✅ Docker is running
- ❌ No containers deployed (Terraform state empty)
- ❌ No services responding
- ⚠️ Some ports already in use (8080, 11434) - likely other services

## 🔧 **Quick Fix - Deploy with Docker Compose:**

```bash
# Run the fix command from debug script
./scripts/deploy.sh fix

# Deploy services
docker-compose up -d

# Wait for services to start
sleep 30

# Check status
docker-compose ps
```

## 🧪 **Test the deployment:**

```bash
# Test AI Gateway
curl http://localhost:30080/health

# Test Ollama (note: port 11435 due to conflict)
curl http://localhost:11435/api/tags

# Test ONNX Runtime
curl http://localhost:8001/v1/models

# Test Prometheus
curl http://localhost:9090/-/healthy

# Test Grafana
curl http://localhost:3000/api/health

# Test AI generation (after model downloads)
curl -X POST http://localhost:30080/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model":"llama3.2:1b","prompt":"Hello AI!"}'
```

## 📊 **Access URLs:**

- **🤖 AI Gateway**: http://localhost:30080
- **🧠 Ollama Direct**: http://localhost:11435 (changed port)
- **🔍 ONNX Runtime**: http://localhost:8001
- **📈 Prometheus**: http://localhost:9090
- **📊 Grafana**: http://localhost:3007 (admin/admin)

## 🎬 **For Demo/Interview:**

This Docker Compose deployment demonstrates:

1. **✅ Container Orchestration** - Multi-service architecture
2. **✅ AI Integration** - Ollama LLM + ONNX Runtime
3. **✅ Load Balancing** - Nginx gateway routing
4. **✅ Monitoring** - Prometheus + Grafana stack
5. **✅ Infrastructure as Code** - Docker Compose configuration
6. **✅ Service Discovery** - Container networking
7. **✅ Health Checks** - Service monitoring
8. **✅ Automation** - One-command deployment

**Message for recruiters:**
> "This demonstrates production-ready container orchestration. While I'm using Docker Compose for rapid deployment here, the same patterns apply to Kubernetes - as shown in my k8s/ manifests. The architecture showcases microservices, AI integration, and comprehensive monitoring."

## 🔧 **If ports are still conflicting:**

```bash
# Check what's using conflicting ports
lsof -i :8080
lsof -i :11435

# Alternative: Use different ports
# Edit docker-compose.yml to change port mappings:
# ollama: "11436:11434" 
# gateway: "30081:80"
```

