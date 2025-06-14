# 🔧 Quick Fix Guide - K3s Deployment Issues

## 🚨 Immediate Solution

3 opcje aby szybko uruchomić projekt:

### Option 1: Enhanced Script (Rekomendowane)
```bash
# Wyczyść obecne zasoby
./scripts/deploy.sh cleanup

# Spróbuj ponownie z diagnostyką
./scripts/deploy.sh troubleshoot
./scripts/deploy.sh deploy
```

### Option 2: Alternative KIND Deployment
```bash
# Wyczyść K3s
./scripts/deploy.sh cleanup

# Zainstaluj KIND (jeśli nie masz)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Deploy z KIND
./scripts/deploy.sh deploy kind
```

### Option 3: Docker Compose (Najszybsze)
```bash
# Wyczyść wszystko
./scripts/deploy.sh cleanup

# Deploy z Docker Compose (bez Kubernetes)
./scripts/deploy.sh deploy local
```

## 🔍 Diagnoza problemów K3s

Sprawdź co się dzieje:

```bash
# 1. Status kontenera K3s
docker ps -a | grep k3s
docker logs k3s-server

# 2. Zasoby systemowe
free -h
df -h
docker system df

# 3. Porty w użyciu
netstat -tuln | grep -E ':(6443|8080|8443)'

# 4. Wyczyść Docker cache
docker system prune -f
docker volume prune -f
```

## 🎯 Typowe przyczyny problemów K3s

### 1. Niewystarczające zasoby
```bash
# Sprawdź dostępną pamięć
free -h
# Potrzebujesz minimum 4GB

# Sprawdź miejsce na dysku  
df -h /var/lib/docker
# Potrzebujesz minimum 10GB
```

### 2. Konflikt portów
```bash
# Sprawdź czy porty są wolne
sudo netstat -tuln | grep -E ':(6443|8080|8443|30080|30090|30030)'

# Zabij procesy używające portów
sudo lsof -ti:6443 | xargs kill -9
```

### 3. Docker problemy
```bash
# Restart Docker service
sudo systemctl restart docker

# Sprawdź status
sudo systemctl status docker
docker version
```

## 🚀 Szybkie rozwiązanie (Docker Compose)

Jeśli K3s nadal nie działa, użyj Docker Compose:

### 1. Stwórz docker-compose.yml
```yaml
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

  onnx-runtime:
    image: mcr.microsoft.com/onnxruntime/server:latest
    ports:
      - "8001:8001"

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin

volumes:
  ollama_data:
```

### 2. Uruchom
```bash
docker-compose up -d
docker-compose ps
```

### 3. Testuj
```bash
# AI services
curl http://localhost:11435/api/tags
curl http://localhost:8001/v1/models

# Monitoring
open http://localhost:9090  # Prometheus
open http://localhost:3000  # Grafana (admin/admin)
```

## 🎬 Demo dla recruiters

Nawet z Docker Compose możesz pokazać:

### 1. Infrastructure as Code
```bash
# Pokaż terraform/main.tf
cat terraform/main.tf

# Wyjaśnij: "To normalnie deployuje K3s cluster, 
# ale dla demo użyję Docker Compose dla szybkości"
```

### 2. AI Integration
```bash
# Test Ollama LLM
curl -X POST http://localhost:11435/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "llama3.2:1b", "prompt": "Hello AI!"}'

# Test ONNX Runtime
curl http://localhost:8001/v1/models
```

### 3. Monitoring
```bash
# Pokaż Grafana dashboard
open http://localhost:3000

# Pokaż Prometheus metrics
open http://localhost:9090
```

### 4. Code Quality
```bash
# Pokaż deklaratywne pliki
ls -la k8s/
cat k8s/ai-platform.yaml | head -50
cat configs/Modelfile
```

## 💡 Komunikat dla recruiters

> "Ten projekt demonstruje Infrastructure as Code patterns. 
> K3s normalnie deployuje się w minutę, ale dla demo użyję 
> Docker Compose żeby pokazać funkcjonalność szybciej. 
> W produkcji używałbym pełnego Kubernetes cluster."

## 🔧 Następne kroki

1. **Immediate**: Użyj Docker Compose dla demo
2. **Investigation**: Debug K3s issue w tle
3. **Improvement**: Dodaj alternative deployment methods
4. **Documentation**: Update README z troubleshooting

## 📞 Emergency Contact

Jeśli nic nie działa:

```bash
# Nuclear option - complete reset
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)  
docker system prune -af
docker volume prune -f

# Start from scratch
./scripts/deploy.sh deploy local
```

