# 📚 API Reference

```
  ___   ___  ___    ___   ___  ___  ___  ___ 
 | _ \ / _ \| _ \  | _ ) / _ \| _ \/ __|/ __|
 |  _/|  _/|   /  | _ \ (_) |  _/\__ \\__ \
 |_|  |_|  |_|_\  |___/\___/|_|  |___/|___/
```

## 📡 API Gateway Endpoints

### Base URL: `http://localhost:30080`

## 🔍 Ollama API (via Gateway)

### List Models
```http
GET /api/ollama/tags
```

**Example:**
```bash
curl http://localhost:30080/api/ollama/tags
```

### Generate Text
```http
POST /api/ollama/api/generate
```

**Example:**
```bash
curl -X POST http://localhost:30080/api/ollama/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama2",
    "prompt": "Tell me about AI"
  }'
```

### Chat Completion
```http
POST /api/ollama/api/chat
```

**Example:**
```bash
curl -X POST http://localhost:30080/api/ollama/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama2",
    "messages": [
      {"role": "user", "content": "Hello!"}
    ]
  }'
```

## 🤖 ONNX Runtime API

### Health Check
```http
GET /api/onnx/v1/health
```

**Example:**
```bash
curl http://localhost:30080/api/onnx/v1/health
```

### List Models
```http
GET /api/onnx/v1/models
```

### Run Inference
```http
POST /api/onnx/v1/models/{model_name}/versions/{version}:predict
```

**Example:**
```bash
curl -X POST http://localhost:30080/api/onnx/v1/models/resnet50/versions/1:predict \
  -H "Content-Type: application/json" \
  -d '{
    "inputs": [
      {
        "name": "input",
        "shape": [1, 3, 224, 224],
        "datatype": "FP32",
        "data": [...]
      }
    ]
  }'
```

## 📊 Monitoring API

### Prometheus Metrics
```http
GET /metrics
```

### Grafana API
```http
GET /grafana/api/health
```

## 🔐 Authentication

> **Note**: Currently, the API is not secured. For production use, please implement authentication.

## 🚦 Rate Limiting

- **Ollama API**: 60 requests per minute
- **ONNX Runtime**: 100 requests per minute

## 🧪 Testing API Endpoints

### Using cURL
```bash
# Test Ollama health
curl -v http://localhost:30080/api/ollama/

# Test ONNX Runtime health
curl -v http://localhost:30080/api/onnx/v1/health
```

### Using HTTPie
```bash
# Install HTTPie if needed
pip install httpie

# Test endpoints
http :30080/api/ollama/
http :30080/api/onnx/v1/health
```

## 🔄 WebSocket Endpoints

### Ollama Chat Stream
```
ws://localhost:30080/api/ollama/api/chat
```

**Example:**
```javascript
const ws = new WebSocket('ws://localhost:30080/api/ollama/api/chat');
ws.onmessage = (event) => {
  console.log('Received:', JSON.parse(event.data));
};
ws.send(JSON.stringify({
  model: 'llama2',
  messages: [{role: 'user', content: 'Hello!'}],
  stream: true
}));
```

## 📈 Monitoring Endpoints

### Prometheus Metrics
```
http://localhost:30080/prometheus
```

### Grafana Dashboards
```
http://localhost:30080/grafana
```

## 🛠️ Troubleshooting

### Common HTTP Status Codes

| Code | Description | Possible Solution |
|------|-------------|-------------------|
| 200 | Success | - |
| 400 | Bad Request | Check request body/parameters |
| 404 | Not Found | Verify endpoint URL |
| 429 | Too Many Requests | Respect rate limits |
| 500 | Server Error | Check service logs |

### Viewing Logs

```bash
# View all service logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f ollama
docker-compose logs -f onnx-runtime
```

## 📚 Related Documentation

- [Ollama API Reference](https://github.com/jmorganca/ollama/blob/main/docs/api.md)
- [ONNX Runtime API Documentation](https://onnxruntime.ai/docs/api/)
- [Prometheus API](https://prometheus.io/docs/prometheus/latest/querying/api/)
- [Grafana HTTP API](https://grafana.com/docs/grafana/latest/developers/http_api/)
