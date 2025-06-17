# 🚀 Kubernetes Deployment Guide

### **Setup KIND:**
```bash
# 1. Install KIND
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Verify installation
kind version
```

### **Deploy with KIND:**
```bash
# 2. Create cluster
kind create cluster --name edge-ai --config kind-config.yaml

# 3. Verify cluster
kubectl cluster-info --context kind-edge-ai
kubectl get nodes

# 4. Deploy AI platform
kubectl apply -f k8s/ai-platform.yaml

# 5. Deploy monitoring
kubectl apply -f k8s/monitoring.yaml

# 6. Wait for deployments
kubectl wait --for=condition=available --timeout=300s deployment --all -n ai-inference
kubectl wait --for=condition=available --timeout=300s deployment --all -n monitoring

# 7. Check status
kubectl get pods -A
```

### **Access services:**
```bash
# Test endpoints
curl http://localhost:30080/health     # AI Gateway
curl http://localhost:30090/-/healthy  # Prometheus
curl http://localhost:30030/api/health # Grafana

# Open in browser
open http://localhost:30030  # Grafana (admin/admin)
open http://localhost:30090  # Prometheus
```

---

## 🔧 **Option 2: K3s Deployment**

### **Enhanced K3s with Docker:**
```bash
# 1. Clean previous attempts
docker stop k3s-server 2>/dev/null || true
docker rm k3s-server 2>/dev/null || true
docker network rm edge-ai-net 2>/dev/null || true

# 2. Create network first
docker network create --subnet=172.20.0.0/16 edge-ai-net

# 3. Run K3s with better configuration
docker run -d \
  --name k3s-server \
  --privileged \
  --restart unless-stopped \
  --net edge-ai-net \
  --ip 172.20.0.10 \
  -p 6443:6443 \
  -p 30080:30080 \
  -p 30090:30090 \
  -p 30030:30030 \
  -v $(pwd)/kubeconfig:/output \
  -v k3s-data:/var/lib/rancher/k3s \
  -e K3S_KUBECONFIG_OUTPUT=/output/kubeconfig.yaml \
  -e K3S_KUBECONFIG_MODE=666 \
  rancher/k3s:v1.28.4-k3s2 server \
  --disable=traefik \
  --disable=servicelb \
  --write-kubeconfig-mode=666 \
  --node-external-ip=127.0.0.1

# 4. Wait for cluster
sleep 60

# 5. Fix kubeconfig
sed -i 's|https://.*:6443|https://localhost:6443|g' kubeconfig/kubeconfig.yaml

# 6. Test cluster
export KUBECONFIG=$(pwd)/kubeconfig/kubeconfig.yaml
kubectl get nodes

# 7. Deploy workloads
kubectl apply -f k8s/ai-platform.yaml
kubectl apply -f k8s/monitoring.yaml
```




# 🔧 Fix kubectl permissions

## 🚨 **Immediate Fix:**

```bash
# 1. Fix permissions on kubectl config directory
sudo chown -R $USER:$USER ~/.kube 2>/dev/null || true
mkdir -p ~/.kube
chmod 755 ~/.kube
touch ~/.kube/config
chmod 644 ~/.kube/config

# 2. Clean up the problematic cluster (if exists)
kind delete cluster --name edge-ai 2>/dev/null || true

# 3. Create cluster again
kind create cluster --name edge-ai --config kind-config.yaml

# 4. Set kubeconfig to local file (bypass ~/.kube)
mkdir -p kubeconfig
kind get kubeconfig --name edge-ai > kubeconfig/kubeconfig.yaml
export KUBECONFIG="$(pwd)/kubeconfig/kubeconfig.yaml"

# 5. Test cluster
kubectl cluster-info
kubectl get nodes
```

## 🚀 **Alternative: Use local kubeconfig only**

```bash
# 1. Delete cluster if it exists
kind delete cluster --name edge-ai 2>/dev/null || true

# 2. Create cluster with explicit kubeconfig
mkdir -p kubeconfig
kind create cluster --name edge-ai --config kind-config.yaml --kubeconfig kubeconfig/kubeconfig.yaml

# 3. Use local kubeconfig
export KUBECONFIG="$(pwd)/kubeconfig/kubeconfig.yaml"

# 4. Verify
kubectl cluster-info
kubectl get nodes
```

## ⚡ **Quick Complete Setup:**

```bash
# All-in-one command to fix and deploy:
sudo chown -R $USER:$USER ~/.kube 2>/dev/null || true && \
mkdir -p ~/.kube kubeconfig && \
chmod 755 ~/.kube && \
touch ~/.kube/config && \
chmod 644 ~/.kube/config && \
kind delete cluster --name edge-ai 2>/dev/null || true && \
kind create cluster --name edge-ai --config kind-config.yaml && \
kind get kubeconfig --name edge-ai > kubeconfig/kubeconfig.yaml && \
export KUBECONFIG="$(pwd)/kubeconfig/kubeconfig.yaml" && \
kubectl cluster-info
```

## 🧪 **Deploy Portfolio Applications:**

```bash
# After successful cluster creation:
export KUBECONFIG="$(pwd)/kubeconfig/kubeconfig.yaml"

# Deploy AI platform
kubectl apply -f k8s/ai-platform.yaml

# Deploy monitoring
kubectl apply -f k8s/monitoring.yaml

# Check status
kubectl get pods -A

# Wait for deployments
kubectl wait --for=condition=available --timeout=300s deployment --all -n ai-inference
kubectl wait --for=condition=available --timeout=300s deployment --all -n monitoring

# Test endpoints
curl http://localhost:30080/health
```

## 🔍 **If Still Having Issues:**

```bash
# Check current permissions
ls -la ~/.kube/

# Check if cluster was created despite error
kind get clusters

# Check cluster status
docker ps | grep kindest

# If cluster exists, just get kubeconfig
kind get kubeconfig --name edge-ai > kubeconfig/kubeconfig.yaml
export KUBECONFIG="$(pwd)/kubeconfig/kubeconfig.yaml"
kubectl get nodes
```

## 📊 **Expected Success Output:**

```bash
Creating cluster "edge-ai" ...
 ✓ Ensuring node image (kindest/node:v1.27.3) 🖼 
 ✓ Preparing nodes 📦  
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
Set kubectl context to "kind-edge-ai"
You can now use your cluster with:

kubectl cluster-info --context kind-edge-ai

NAME                     STATUS   ROLES           AGE   VERSION
edge-ai-control-plane   Ready    control-plane   30s   v1.27.3
```




## Fix the NotReady Node Status

Since this is a kind cluster, you need to install a CNI plugin. Here are the most common options:

### Option 1: Install Calico (Recommended)
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
```

### Option 2: Install Flannel
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

### Option 3: Install Weave Net
```bash
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
```

## Check What's Happening

Let's diagnose why the node is NotReady:

```bash
# Get detailed node information
kubectl describe node edge-ai-control-plane

# Check system pods status
kubectl get pods -n kube-system

# Check for any events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## Wait and Verify

After installing a CNI plugin:

```bash
# Wait a minute or two, then check node status
kubectl get nodes

# Check that system pods are running
kubectl get pods -n kube-system

# Once ready, you should see something like:
# NAME                    STATUS   ROLES           AGE   VERSION
# edge-ai-control-plane   Ready    control-plane   2m    v1.27.3
```


## Next Steps

Now that your cluster is ready, you can:

```bash
# Verify everything is working
kubectl get nodes
kubectl get pods -A

# Deploy your applications
kubectl create namespace my-app
kubectl apply -f your-manifests.yaml

# Check cluster resources
kubectl top nodes  # (if metrics-server is installed)
```
