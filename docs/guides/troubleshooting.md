# Troubleshooting Guide

```
 _____           _                 _           _             _   _             _   _           _       _   _             
|_   _|         | |               | |         (_)           | | | |           | | (_)         | |     | | (_)            
  | |  _ __  ___| |_ __ _ _ __   | |__  _   _ _ _ __   __ _| |_| |  _ __   __| |_ _ _ __   __| | __ _| |_ _  ___  _ __ 
  | | | '_ \/ __| __/ _` | '_ \  | '_ \| | | | | '_ \ / _` | __| | | '_ \ / _` | | | '_ \ / _` |/ _` | __| |/ _ \| '_ \
 _| |_| | | \__ \ || (_| | | | | | |_) | |_| | | | | | (_| | |_| | | | | | (_| | | | | | | (_| | (_| | |_| | (_) | | | |
|_____|_| |_|___/\__\__,_|_| |_| |_.__/ \__,_|_|_| |_|\__,_|\__|_| |_| |_|\__,_|_|_|_| |_|\__,_|\__,_|\__|_|\___/|_| |_|
```

## Common Issues and Solutions

### 1. Container Fails to Start

#### Symptoms
- Containers exit immediately after starting
- `docker-compose ps` shows containers as "Restarting"

#### Troubleshooting Steps
1. Check the container logs:
   ```bash
   docker-compose logs <service_name>
   ```

2. Common causes:
   - **Port conflicts**: Ensure no other services are using ports 30080, 11435, 8001, 3007, or 9090
   - **Insufficient resources**: Check Docker's resource allocation in settings
   - **Permission issues**: Ensure Docker has proper permissions to access volumes

### 2. Ollama Service Issues

#### Symptoms
- Cannot connect to Ollama API
- Models fail to load
- Health checks failing

#### Troubleshooting Steps
1. Check Ollama logs:
   ```bash
   docker-compose logs ollama
   ```

2. Verify API access:
   ```bash
   curl http://localhost:11435/api/tags
   ```

3. Common solutions:
   - **Model not found**: Pull the model first with `curl -X POST http://localhost:30080/api/pull -d '{"name": "llama2"}'`
   - **Insufficient memory**: Increase Docker's memory allocation
   - **Permission issues**: Check volume permissions in `~/.ollama`

### 3. ONNX Runtime Issues

#### Symptoms
- Model loading failures
- Inference errors
- Service restarting

#### Troubleshooting Steps
1. Check ONNX Runtime logs:
   ```bash
   docker-compose logs onnx-runtime
   ```

2. Verify model files:
   ```bash
   ls -la models/
   ```

3. Common solutions:
   - **Invalid model file**: Ensure the ONNX model is valid and compatible
   - **Missing dependencies**: Check if all required model files are present
   - **Insufficient resources**: Increase Docker's CPU/memory allocation

### 4. Nginx Gateway Issues

#### Symptoms
- 502 Bad Gateway errors
- Connection timeouts
- SSL/TLS handshake failures

#### Troubleshooting Steps
1. Check Nginx logs:
   ```bash
   docker-compose logs nginx-gateway
   ```

2. Verify backend services:
   ```bash
   # Check if services are accessible from Nginx
   docker-compose exec nginx-gateway curl -v http://ollama:11434/api/tags
   docker-compose exec nginx-gateway curl -v http://onnx-runtime:8001/v1/
   ```

3. Common solutions:
   - **Service discovery**: Ensure service names in docker-compose.yml match Nginx config
   - **Timeouts**: Adjust proxy timeouts in Nginx config
   - **SSL issues**: Verify SSL certificate paths and permissions

## Monitoring and Logs

### Viewing Logs
```bash
# Follow logs for all services
docker-compose logs -f

# View logs for a specific service
docker-compose logs -f <service_name>

# View container stats
docker stats
```

### Monitoring Endpoints
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3007 (admin/admin)

## Performance Tuning

### Ollama
- Increase model cache size: Set `OLLAMA_MAX_LOADED_MODELS` environment variable
- Adjust context window: Set `OLLAMA_CONTEXT_LENGTH` (default: 2048)
- Enable GPU acceleration: Set `OLLAMA_GPU_LAYERS`

### ONNX Runtime
- Set thread count: `OMP_NUM_THREADS=4`
- Enable optimizations: Set `ORT_DISABLE_OPTIMIZATIONS=0`
- Memory optimizations: Set `ORT_MEMORY_OPT_LEVEL=1`

## Common Error Messages

### "Failed to load model"
- Check if model exists in `~/.ollama/models`
- Verify sufficient disk space
- Check file permissions

### "Connection refused"
- Verify service is running: `docker-compose ps`
- Check for port conflicts
- Ensure Docker network is functioning

### "Out of memory"
- Reduce model size or batch size
- Increase Docker memory allocation
- Enable model offloading if using GPU

## Getting Help

### Collect Debug Information
```bash
# System information
docker info

# Service configurations
docker-compose config

# Container resource usage
docker stats --no-stream
```

### Support Resources
- [GitHub Issues](https://github.com/wronai/edge/issues)
- [Documentation](https://docs.wronai_edge.wron.ai)
- [Community Forum](https://community.wronai_edge.wron.ai)

## Known Issues

### Ollama
- Large models may require significant RAM
- First-time model loading can be slow
- Some models may not be compatible with all hardware

### ONNX Runtime
- Model conversion from other frameworks may require additional steps
- Some operators may not be supported on all platforms
- Performance varies by hardware and model architecture
