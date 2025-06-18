# 🐳 Minikube

## **Setup Minikube:**

```bash
# 1. Install Minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
sudo mv minikube /usr/local/bin/

# 2. Start Minikube with enough resources
minikube start --cpus=4 --memory=8192 --driver=docker

# 3. Enable addons
minikube addons enable ingress
minikube addons enable metrics-server

# 4. Deploy applications
kubectl apply -f k8s/ai-platform.yaml
kubectl apply -f k8s/monitoring.yaml

# 5. Access services via port forwarding
kubectl port-forward -n ai-inference svc/ai-gateway-svc 30080:80 &
kubectl port-forward -n monitoring svc/prometheus-svc 30090:9090 &
kubectl port-forward -n monitoring svc/grafana-svc 30030:3000 &

# 6. Test services
curl http://localhost:30080/health
```

---

## 🖥️ **Option 4: Docker Desktop Kubernetes**

### **Enable Docker Desktop Kubernetes:**
```bash
# 1. Enable Kubernetes in Docker Desktop
# Go to Docker Desktop → Settings → Kubernetes → Enable Kubernetes

# 2. Verify cluster
kubectl cluster-info
kubectl get nodes

# 3. Deploy applications
kubectl apply -f k8s/ai-platform.yaml
kubectl apply -f k8s/monitoring.yaml

# 4. Services will be available at localhost with NodePort
curl http://localhost:30080/health
```

---

## 🧪 **Deployment Verification Script**

Create this verification script:

```bash
# Create verify-k8s.sh
cat > verify-k8s.sh << 'EOF'
#!/bin/bash

echo "🔍 Kubernetes Cluster Verification"

# Check cluster
echo "1. Cluster Info:"
kubectl cluster-info

# Check nodes
echo "2. Nodes:"
kubectl get nodes -o wide

# Check namespaces
echo "3. Namespaces:"
kubectl get namespaces

# Check AI platform
echo "4. AI Platform (ai-inference namespace):"
kubectl get all -n ai-inference

# Check monitoring
echo "5. Monitoring (monitoring namespace):"
kubectl get all -n monitoring

# Check pod status
echo "6. Pod Status:"
kubectl get pods -A -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName"

# Test endpoints
echo "7. Endpoint Tests:"
curl -f http://localhost:30080/health && echo "✅ AI Gateway OK" || echo "❌ AI Gateway Failed"
curl -f http://localhost:30090/-/healthy && echo "✅ Prometheus OK" || echo "❌ Prometheus Failed"
curl -f http://localhost:30030/api/health && echo "✅ Grafana OK" || echo "❌ Grafana Failed"

echo "🎉 Verification complete!"
EOF

chmod +x verify-k8s.sh
./verify-k8s.sh
```

---

## 🎯 **Recommended Approach for Demo:**

### **For maximum reliability:**
```bash
# 1. Use KIND (most reliable)
kind create cluster --name wronai_edge --config kind-config.yaml

# 2. Deploy everything
kubectl apply -f k8s/ai-platform.yaml
kubectl apply -f k8s/monitoring.yaml

# 3. Verify deployment
./verify-k8s.sh

# 4. Access services
echo "🚀 URLs:"
echo "• AI Gateway: http://localhost:30080"
echo "• Grafana: http://localhost:30030 (admin/admin)"
echo "• Prometheus: http://localhost:30090"
```

### **For interview demo:**
1. **Show Kubernetes manifests** - `cat k8s/ai-platform.yaml`
2. **Demonstrate deployment** - `kubectl apply -f k8s/`
3. **Show running services** - `kubectl get pods -A`
4. **Test functionality** - `curl http://localhost:30080/health`
5. **Show monitoring** - Open Grafana dashboard

## 🔧 **Troubleshooting:**

### **If KIND fails:**
```bash
# Check Docker resources
docker system df
docker system prune -f

# Restart KIND cluster
kind delete cluster --name wronai_edge
kind create cluster --name wronai_edge --config kind-config.yaml
```

### **If services don't start:**
```bash
# Check pod logs
kubectl logs -n ai-inference deployment/ollama-llm
kubectl logs -n ai-inference deployment/onnx-inference

# Check events
kubectl get events -A --sort-by='.lastTimestamp'

# Scale down resource requirements if needed
kubectl patch deployment ollama-llm -n ai-inference -p '{"spec":{"template":{"spec":{"containers":[{"name":"ollama","resources":{"requests":{"memory":"512Mi","cpu":"250m"}}}]}}}}'
```

