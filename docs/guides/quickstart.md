# Quick Start Guide

```
  ___        _      _   _             _____ _             _   
 / _ \ _   _| | ___| |_(_) ___  _ __ |_   _| |_   _  ___| |_ 
| | | | | | | |/ _ \ __| |/ _ \| '_ \  | | | | | | |/ __| __|
| |_| | |_| | |  __/ |_| | (_) | | | | | | | | |_| | (__| |_ 
 \__\_\\__,_|_|\___|\__|_|\___/|_| |_| |_| |_|\__,_|\___|\__|
```

## Prerequisites

- Docker 20.10.0 or later
- Docker Compose 1.29.0 or later
- 8GB+ RAM (16GB recommended for larger models)
- 20GB+ free disk space for models

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/wronai/edge.git
   cd edge
   ```

2. **Create required directories**
   ```bash
   mkdir -p models
   ```

3. **Start the services**
   ```bash
   docker-compose up -d
   ```

4. **Verify services are running**
   ```bash
   docker-compose ps
   ```

## Your First Request

### Test Ollama API

```bash
# List available models (should be empty initially)
curl http://localhost:30080/api/tags

# Pull a model (llama2)
curl http://localhost:30080/api/pull -d '{"name": "llama2"}'

# Generate text
curl http://localhost:30080/api/generate -d '{
  "model": "llama2",
  "prompt": "Why is the sky blue?",
  "stream": false
}'
```

### Test ONNX Runtime

1. **Download a sample ONNX model**
   ```bash
   wget -O models/sample.onnx https://github.com/onnx/models/raw/main/vision/classification/squeezenet/model/squeezenet1.1-7.onnx
   ```

2. **Verify the model is loaded**
   ```bash
   curl http://localhost:30080/v1/
   ```

3. **Make an inference request** (example with sample data)
   ```bash
   curl -X POST http://localhost:30080/v1/models/sample/versions/1 \
     -H "Content-Type: application/json" \
     -d '{"inputs":[{"name":"data","shape":[1,3,224,224],"type":"float32","data":[0.1,0.2,0.3]}]}'
   ```

## Monitoring

Access the monitoring dashboards:

- **Grafana**: http://localhost:3007 (admin/admin)
- **Prometheus**: http://localhost:9090

## Common Tasks

### View Logs

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f ollama
```

### Stop Services

```bash
docker-compose down
```

### Remove All Data

```bash
docker-compose down -v
rm -rf ~/.ollama/models
```

## Next Steps

- [Explore the API Reference](../api/reference.md)
- [Learn about the Architecture](../architecture/overview.md)
- [Deploy in Production](../guides/production.md)
- [Troubleshooting Guide](../guides/troubleshooting.md)

## Need Help?

- [Open an Issue](https://github.com/wronai/edge/issues)
- [Join our Discord](https://discord.gg/wronai_edge)
- Check out the [FAQ](../faq.md)
