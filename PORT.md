# Declarative Edge AI DevOps Portfolio Project

A comprehensive portfolio project designed for experienced DevOps professionals to showcase modern Infrastructure as Code, AI/LLM integration, and declarative automation skills through minimal imperative coding. This project can be implemented in 1-2 hours while demonstrating production-ready patterns valued by employers in 2025.

## Project overview: Multi-edge AI inference platform

The project demonstrates a **hybrid cloud-edge AI inference platform** that deploys and manages LLM models across multiple edge locations using pure declarative configurations. This architecture showcases both DevOps expertise and AI integration capabilities while minimizing custom code development.

### Core value proposition

**For Tom's background**, this project perfectly aligns with his 15+ years DevOps experience and LLM expertise by demonstrating:
- Advanced Infrastructure as Code patterns using modern tools
- AI/LLM deployment without heavy custom coding  
- Edge computing orchestration skills
- Declarative automation and configuration management
- Production-ready monitoring and observability

The project emphasizes **configuration over coding**, leveraging YAML, Docker Compose, Kubernetes manifests, and Terraform modules rather than custom scripts.

## Architecture and technology stack

### Infrastructure layer (Terraform)
- **Multi-cloud edge deployment** using Terraform modules
- **K3s cluster provisioning** on edge nodes (Raspberry Pi 4 or Intel NUC)
- **Network and security configuration** via Infrastructure as Code
- **Storage and monitoring setup** through declarative manifests

### Container orchestration (Kubernetes + GitOps)
- **K3s lightweight Kubernetes** for resource-constrained edge environments
- **ArgoCD GitOps** for declarative application deployment
- **YAML-based configurations** for all workload definitions
- **Progressive deployment** patterns (canary, blue-green)

### AI model serving (ONNX Runtime + Ollama)
- **ONNX Runtime** for lightweight model inference
- **Ollama** for LLM serving with Modelfile configurations
- **Container-based deployment** using pre-built images
- **Horizontal pod autoscaling** via Kubernetes manifests

### Monitoring and observability
- **Prometheus Operator** with ServiceMonitor CRDs
- **Grafana-as-Code** with dashboard provisioning
- **OpenTelemetry** for distributed tracing
- **Declarative alerting** using PrometheusRule configurations

## Project implementation guide

### Phase 1: Infrastructure foundation (30 minutes)

**Terraform edge infrastructure:**
```hcl
# main.tf
module "edge_k3s_cluster" {
  source = "./modules/k3s-cluster"
  
  edge_nodes = {
    node-1 = { ip = "192.168.1.10", location = "factory-floor" }
    node-2 = { ip = "192.168.1.11", location = "warehouse" }
    node-3 = { ip = "192.168.1.12", location = "office" }
  }
  
  cluster_config = {
    kubernetes_version = "v1.28.4+k3s2"
    disable_components = ["traefik", "servicelb"]
    enable_components  = ["metrics-server"]
  }
}

module "monitoring_stack" {
  source = "./modules/prometheus-grafana"
  depends_on = [module.edge_k3s_cluster]
}
```

**Key benefits**: Zero bash scripts, pure declarative infrastructure, automated cluster bootstrapping, repeatable across environments.

### Phase 2: GitOps deployment pipeline (30 minutes)

**ArgoCD application definition:**
```yaml
# argocd/applications/edge-ai-platform.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: edge-ai-inference
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/tomsapletta/edge-ai-devops
    path: manifests/production
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: ai-inference
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - CreateNamespace=true
```

**ONNX model serving deployment:**
```yaml
# manifests/onnx-inference-service.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: onnx-inference-server
  labels:
    app: onnx-inference
spec:
  replicas: 2
  selector:
    matchLabels:
      app: onnx-inference
  template:
    spec:
      containers:
      - name: onnx-server
        image: mcr.microsoft.com/onnxruntime/server:latest
        ports:
        - containerPort: 8001
          name: http
        - containerPort: 8002  
          name: grpc
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        volumeMounts:
        - name: model-storage
          mountPath: /models
      volumes:
      - name: model-storage
        configMap:
          name: model-config
---
apiVersion: v1
kind: Service
metadata:
  name: onnx-inference-svc
  labels:
    app: onnx-inference
spec:
  selector:
    app: onnx-inference
  ports:
  - name: http
    port: 8001
    targetPort: 8001
  - name: grpc
    port: 8002
    targetPort: 8002
```

### Phase 3: LLM integration with Ollama (20 minutes)

**Ollama LLM deployment:**
```yaml
# manifests/ollama-llm-service.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ollama-llm-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ollama-llm
  template:
    spec:
      containers:
      - name: ollama
        image: ollama/ollama:latest
        ports:
        - containerPort: 11435
        env:
        - name: OLLAMA_HOST
          value: "0.0.0.0"
        resources:
          limits:
            memory: "4Gi"
            cpu: "2000m"
        volumeMounts:
        - name: ollama-data
          mountPath: /root/.ollama
      volumes:
      - name: ollama-data
        emptyDir: {}
      initContainers:
      - name: model-loader
        image: ollama/ollama:latest
        command: ["ollama", "pull", "llama3.2:1b"]
        env:
        - name: OLLAMA_HOST
          value: "http://localhost:11435"
```

**Custom Modelfile configuration:**
```dockerfile
# configs/Modelfile.ai-assistant
FROM llama3.2:1b
PARAMETER temperature 0.7
PARAMETER stop "<|im_end|>"
SYSTEM """You are an AI assistant for industrial edge computing environments. 
Provide concise, accurate responses about system status, troubleshooting, and optimization."""
```

### Phase 4: Monitoring and observability (20 minutes)

**Prometheus monitoring configuration:**
```yaml
# monitoring/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ai-inference-metrics
spec:
  selector:
    matchLabels:
      app: onnx-inference
  endpoints:
  - port: http
    interval: 30s
    path: /metrics
---
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: ai-model-alerts
spec:
  groups:
  - name: ai-inference.rules
    rules:
    - alert: HighInferenceLatency
      expr: histogram_quantile(0.95, rate(inference_duration_seconds_bucket[5m])) > 0.5
      for: 2m
      labels:
        severity: warning
      annotations:
        summary: "AI model inference latency is high"
```

**Grafana dashboard provisioning:**
```yaml
# monitoring/grafana-dashboard.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ai-inference-dashboard
  labels:
    grafana_dashboard: "1"
data:
  dashboard.json: |
    {
      "dashboard": {
        "title": "Edge AI Inference Platform",
        "panels": [
          {
            "title": "Inference Requests/sec",
            "targets": [
              {"expr": "rate(inference_requests_total[5m])"}
            ]
          },
          {
            "title": "Model Accuracy",
            "targets": [
              {"expr": "model_accuracy_score"}
            ]
          }
        ]
      }
    }
```

## Modern DevOps patterns demonstrated

### Infrastructure as Code excellence
- **Multi-environment support** through Terraform workspaces
- **Module reusability** across different edge deployments  
- **State management** with remote backends and locking
- **Resource lifecycle management** with proper dependencies

### GitOps and declarative deployment
- **Configuration drift prevention** through continuous reconciliation
- **Automated rollback capabilities** via ArgoCD health checks
- **Progressive deployment strategies** without custom scripting
- **Multi-cluster management** across edge locations

### Container orchestration mastery  
- **Kubernetes operators** for AI/ML workload management
- **Resource optimization** through requests/limits and HPA
- **Service mesh integration** options (Istio/Linkerd)
- **Storage orchestration** for model artifacts and data

### Observability and monitoring
- **Three pillars coverage**: metrics, logs, traces through OpenTelemetry
- **SLI/SLO implementation** via Prometheus recording rules
- **Automated alerting** with intelligent noise reduction
- **Dashboard as Code** for consistent monitoring across environments

## Implementation timeline and effort

### 1-hour minimum viable project
- Basic Terraform + K3s setup on single node
- ONNX Runtime deployment with sample model
- Basic Prometheus monitoring
- ArgoCD GitOps configuration

### 2-hour full demonstration
- Multi-node edge cluster with proper networking
- Ollama LLM integration with custom models
- Complete monitoring stack with Grafana dashboards
- CI/CD pipeline with automated testing

### Extension opportunities (additional time)
- **Service mesh integration** for advanced traffic management
- **Feature store implementation** using Feast
- **Model A/B testing** infrastructure
- **Compliance scanning** with Falco and OPA Gatekeeper

## Portfolio presentation strategy

### GitHub repository structure
```
edge-ai-devops-portfolio/
├── terraform/
│   ├── modules/           # Reusable infrastructure components
│   ├── environments/      # Environment-specific configurations
│   └── main.tf           # Root configuration
├── manifests/
│   ├── base/             # Base Kubernetes configurations
│   ├── overlays/         # Environment-specific overlays
│   └── argocd/           # GitOps application definitions
├── monitoring/
│   ├── prometheus/       # Monitoring rules and config
│   ├── grafana/         # Dashboard provisioning
│   └── alerts/          # Alerting configurations
├── models/
│   ├── onnx/            # ONNX model definitions
│   ├── ollama/          # Modelfile configurations
│   └── benchmarks/      # Performance testing
├── docs/
│   ├── architecture.md  # System design documentation
│   ├── runbooks/        # Operational procedures
│   └── decisions/       # Architecture decision records
└── scripts/
    ├── bootstrap.sh     # One-time setup automation
    └── validate.sh      # Health check utilities
```

### Key demonstration points
1. **Architecture walkthrough**: Show cloud-native design principles
2. **Live deployment**: Demonstrate GitOps workflow in action  
3. **Monitoring showcase**: Real-time dashboards and alerting
4. **Scalability discussion**: How the platform handles growth
5. **Operational procedures**: Day-2 operations and maintenance

## Business value and employer appeal

### Skills demonstrated
- **Modern IaC practices** using latest Terraform patterns
- **Kubernetes expertise** with lightweight distributions for edge
- **AI/ML integration** without heavy custom development
- **GitOps proficiency** for reliable deployment automation
- **Observability implementation** following industry best practices

### Industry relevance for 2025
- **Edge AI computing** is experiencing massive growth
- **Declarative automation** is becoming the standard approach
- **MLOps capabilities** are in high demand across industries
- **Infrastructure as Code** skills are essential for senior roles
- **Kubernetes expertise** remains highly valued

### Competitive differentiation
This project stands out by combining **edge computing**, **AI/LLM deployment**, and **advanced DevOps practices** in a single demonstrable portfolio piece. It shows practical experience with cutting-edge technologies while emphasizing the declarative, configuration-driven approaches that modern organizations prefer.

The focus on **minimal imperative code** demonstrates architectural maturity and understanding of sustainable, maintainable infrastructure practices that scale across teams and environments.

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

This portfolio project successfully demonstrates Tom's expertise in DevOps, AI/LLM integration, and modern declarative practices while remaining achievable within the 1-2 hour timeframe. It showcases industry-relevant skills that employers value in 2025, emphasizing configuration management and automation over custom application development.



