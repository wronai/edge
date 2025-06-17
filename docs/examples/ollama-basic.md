# Ollama Basic Example

## Running Your First LLM Query

### Prerequisites
- Ollama service running (via `make up`)
- `curl` or any HTTP client

### Example: Basic Text Generation

```bash
# Generate text using the default model
curl -X POST http://localhost:11435/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama2",
    "prompt": "Explain quantum computing in simple terms"
  }'
```

### Example: Chat Completion

```bash
# Start a chat session
curl -X POST http://localhost:11435/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama2",
    "messages": [
      { "role": "user", "content": "Hello!" },
      { "role": "assistant", "content": "Hello! How can I help you today?" },
      { "role": "user", "content": "What can you do?" }
    ]
  }'
```

### Available Models

List available models:

```bash
curl http://localhost:11435/api/tags
```

Pull a new model:

```bash
curl -X POST http://localhost:11435/api/pull \
  -H "Content-Type: application/json" \
  -d '{"name": "llama2:13b"}'
```

## Python Client Example

```python
import requests

def generate_text(prompt, model="llama2"):
    response = requests.post(
        "http://localhost:11435/api/generate",
        json={
            "model": model,
            "prompt": prompt,
            "stream": False
        }
    )
    return response.json()["response"]

# Usage
response = generate_text("Write a haiku about artificial intelligence")
print(response)
```

## Advanced Usage

### Model Configuration

Create a `Modelfile` to customize models:

```dockerfile
FROM llama2

# Set system prompt
SYSTEM """You are a helpful AI assistant that provides concise answers.
Keep responses under 3 sentences when possible."""

# Set generation parameters
PARAMETER temperature 0.7
PARAMETER top_k 50
PARAMETER top_p 0.9
```

Create and use the custom model:

```bash
# Build the model
curl -X POST http://localhost:11435/api/create \
  -H "Content-Type: application/json" \
  -d '{"name": "concise-llama2", "modelfile": "FROM llama2\nSYSTEM \"Be concise in your answers\""}'

# Use the custom model
curl -X POST http://localhost:11435/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "concise-llama2", "prompt": "Tell me about quantum computing"}'
```

## Troubleshooting

### Check Service Status
```bash
# Check if Ollama is running
docker-compose ps ollama

# View logs
docker-compose logs -f ollama
```

### Common Issues

**Model not found**
- Ensure you've pulled the model first
- Check network connectivity

**Out of memory**
- Try smaller models (e.g., `llama2:7b` instead of `llama2:70b`)
- Increase system memory or enable swap

**Slow responses**
- Check system resource usage
- Consider using a GPU-accelerated setup for better performance

## Next Steps
- [ONNX Runtime Examples](/docs/examples/onnx-basic)
- [API Reference](/docs/api/ollama)
- [Performance Tuning Guide](/docs/guides/performance)
