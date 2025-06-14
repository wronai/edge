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



