# Troubleshooting Guide

This guide provides solutions to common issues you might encounter when working with the Edge AI platform.

## Table of Contents
- [Service Startup Issues](#service-startup-issues)
- [Port Conflicts](#port-conflicts)
- [Model Loading Problems](#model-loading-problems)
- [API Access Issues](#api-access-issues)
- [Monitoring and Logs](#monitoring-and-logs)
- [Common Error Messages](#common-error-messages)

## Service Startup Issues

### 1. Containers fail to start
**Symptoms**: Containers exit immediately after starting or fail to start.

**Solution**:
1. Check container logs:
   ```bash
   docker-compose logs [service_name]
   ```
2. Verify Docker has enough resources (CPU, memory, disk space)
3. Check for port conflicts (see [Port Conflicts](#port-conflicts))

### 2. Ollama container keeps restarting
**Symptoms**: Ollama container shows as "restarting" in `docker-compose ps`

**Solution**:
1. Check logs for specific errors:
   ```bash
   docker-compose logs ollama
   ```
2. Verify port 11434/11435 is available
3. Check disk space in Docker storage

## Port Conflicts

### 1. Port already in use
**Symptoms**: Errors about ports being in use when starting services.

**Solution**:
1. Identify the process using the port:
   ```bash
   sudo lsof -i :[port_number]
   # or
   sudo netstat -tulpn | grep [port_number]
   ```
2. Stop the conflicting process or change the port in `docker-compose.yml`

## Model Loading Problems

### 1. ONNX Runtime fails to load model
**Symptoms**: Errors about invalid or corrupted model files.

**Solution**:
1. Verify the model file exists in the `./models` directory
2. Check file permissions:
   ```bash
   ls -l models/
   ```
3. Test the model file locally:
   ```bash
   python3 test_onnx_model.py
   ```

## API Access Issues

### 1. 404 Not Found errors
**Symptoms**: API endpoints return 404 errors.

**Solution**:
1. Verify the service is running:
   ```bash
   docker-compose ps
   ```
2. Check the Nginx configuration for correct routing
3. Verify the endpoint URL is correct

### 2. 405 Method Not Allowed
**Symptoms**: GET requests to ONNX Runtime return 405.

**Explanation**: This is expected behavior. ONNX Runtime requires POST requests for inference.

## Monitoring and Logs

### 1. Accessing Container Logs
```bash
# View logs for all services
docker-compose logs

# Follow logs in real-time
docker-compose logs -f

# View logs for a specific service
docker-compose logs [service_name]
```

### 2. Accessing Monitoring
- **Grafana**: http://localhost:3007 (admin/admin)
- **Prometheus**: http://localhost:9090

## Common Error Messages

### 1. "Address already in use"
**Solution**: Change the port in `docker-compose.yml` or stop the conflicting service.

### 2. "Permission denied" when accessing files
**Solution**: Ensure the Docker container has proper permissions to access mounted volumes.

### 3. "Connection refused"
**Solution**:
1. Verify the service is running
2. Check if the service is listening on the correct port
3. Ensure there are no firewall rules blocking the connection

## Getting Help

If you encounter issues not covered in this guide:
1. Check the [GitHub Issues](https://github.com/wronai/edge/issues)
2. Search the [Discussions](https://github.com/wronai/edge/discussions)
3. Open a new issue with details about your problem

## Debugging Tips

1. Increase log verbosity by setting environment variables:
   ```yaml
   environment:
     - LOG_LEVEL=debug
   ```

2. Access a shell in a running container:
   ```bash
   docker-compose exec [service_name] sh
   ```

3. Check container resource usage:
   ```bash
   docker stats
   ```
