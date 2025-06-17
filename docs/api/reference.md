# API Reference

```
    _    ____ ___ 
   / \  |  _ \_ _|
  / _ \ | |_) | | 
 / ___ \|  __/| | 
/_/   \_\_|  |___|
```

## Base URL
All API endpoints are relative to the base URL of the Nginx Gateway:
```
http://localhost:30080
```

## Ollama API Endpoints

### List Models
```
GET /api/tags
```

**Response**
```json
{
  "models": [
    {
      "name": "llama2",
      "modified_at": "2023-08-02T19:22:45.499Z",
      "size": 3826564946
    }
  ]
}
```

### Generate Text
```
POST /api/generate
```

**Request Body**
```json
{
  "model": "llama2",
  "prompt": "Why is the sky blue?",
  "stream": false
}
```

**Response**
```json
{
  "model": "llama2",
  "created_at": "2023-08-04T08:52:19.385406455-07:00",
  "response": "The sky appears blue due to a phenomenon called Rayleigh scattering...",
  "done": true,
  "context": [1, 2, 3],
  "total_duration": 5040554666,
  "load_duration": 5025959,
  "prompt_eval_count": 46,
  "eval_count": 290,
  "eval_duration": 5014707473
}
```

## ONNX Runtime API Endpoints

### Health Check
```
GET /v1/
```

**Response**
```
Healthy
```

### Model Inference
```
POST /v1/models/:model/versions/:version
```

**Request Headers**
```
Content-Type: application/json
```

**Request Body**
```json
{
  "inputs": [
    {
      "name": "input1",
      "shape": [1, 3, 224, 224],
      "datatype": "FP32",
      "data": [0.1, 0.2, 0.3, ...]
    }
  ]
}
```

**Response**
```json
{
  "model_name": "resnet50",
  "model_version": "1",
  "outputs": [
    {
      "name": "output1",
      "shape": [1, 1000],
      "datatype": "FP32",
      "data": [0.01, 0.02, ...]
    }
  ]
}
```

## Monitoring Endpoints

### Prometheus Metrics
```
GET /metrics
```

**Response**
```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",status="200"} 1234
http_requests_total{method="POST",status="200"} 567
```

## Error Responses

### 400 Bad Request
```json
{
  "error": {
    "code": 400,
    "message": "Invalid request format",
    "details": "Expected 'prompt' field in request body"
  }
}
```

### 404 Not Found
```json
{
  "error": {
    "code": 404,
    "message": "Model not found",
    "details": "Model 'unknown-model' does not exist"
  }
}
```

### 500 Internal Server Error
```json
{
  "error": {
    "code": 500,
    "message": "Internal server error",
    "details": "Failed to load model weights"
  }
}
```

## Rate Limiting

- **Rate Limit**: 60 requests per minute per IP
- **Response Headers**:
  - `X-RateLimit-Limit`: Request limit per time window
  - `X-RateLimit-Remaining`: Remaining requests in current window
  - `X-RateLimit-Reset`: Time when the rate limit resets (UTC epoch seconds)

## Authentication

Some endpoints may require authentication. Include your API key in the request header:

```
Authorization: Bearer your-api-key-here
```

## Response Format

All successful responses include a `Content-Type` header of `application/json` unless otherwise specified. Error responses follow the JSON:API error format.
