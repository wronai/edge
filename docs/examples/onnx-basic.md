# ONNX Runtime Basic Example

## Getting Started with ONNX Models

### Prerequisites
- ONNX Runtime service running (via `make up`)
- Python 3.7+
- `requests` library

### Basic Inference Example

```python
import requests
import numpy as np

# Sample input data (adjust based on your model's expected input)
input_data = {
    "input": np.random.randn(1, 3, 224, 224).tolist()  # Example for image classification
}

# Send prediction request
response = requests.post(
    "http://localhost:8001/v1/models/model:predict",
    json={"instances": [input_data]}
)

print("Prediction results:", response.json())
```

## Loading Custom Models

1. Place your `.onnx` model file in the `models` directory
2. The service will automatically load models on startup

### Example: Image Classification

```python
from PIL import Image
import numpy as np
import requests

def preprocess_image(image_path):
    # Load and preprocess image
    img = Image.open(image_path).convert('RGB')
    img = img.resize((224, 224))  # Adjust size based on model
    img_array = np.array(img).astype(np.float32)
    img_array = np.transpose(img_array, (2, 0, 1))  # HWC to CHW
    img_array = np.expand_dims(img_array, axis=0)    # Add batch dimension
    return img_array

# Preprocess image
input_data = preprocess_image("path/to/your/image.jpg")

# Make prediction
response = requests.post(
    "http://localhost:8001/v1/models/model:predict",
    json={"instances": [{"input": input_data.tolist()}]}
)

print("Classification results:", response.json())
```

## Model Management

### List Available Models

```bash
curl http://localhost:8001/v1/models
```

### Model Metadata

```bash
curl http://localhost:8001/v1/models/model
```

## Performance Optimization

### Enable GPU Acceleration

Update the `docker-compose.yml` to enable GPU:

```yaml
  onnx-runtime:
    image: mcr.microsoft.com/onnxruntime/server:latest-gpu  # Use GPU version
    runtime: nvidia  # Requires NVIDIA Container Toolkit
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
    # ... rest of the config
```

### Batch Processing

```python
# Process multiple inputs in a single request
batch_inputs = [preprocess_image(f"image_{i}.jpg") for i in range(4)]
response = requests.post(
    "http://localhost:8001/v1/models/model:predict",
    json={"instances": [{"input": x.tolist()} for x in batch_inputs]}
)
```

## Monitoring

Check the service metrics:
```bash
# Prometheus metrics endpoint
curl http://localhost:8001/metrics
```

## Troubleshooting

### Common Issues

**Model Loading Errors**
- Check model compatibility with ONNX Runtime version
- Verify model input/output shapes

**Performance Issues**
- Enable GPU acceleration if available
- Use model optimization techniques (quantization, pruning)
- Increase container resources if needed

**Memory Issues**
- Reduce batch size
- Use smaller models
- Enable model sharding for large models

## Next Steps
- [Advanced ONNX Examples](/docs/examples/onnx-advanced)
- [Model Optimization Guide](/docs/guides/optimization)
- [API Reference](/docs/api/onnx)
