# ONNX Runtime Integration

This guide covers how to use ONNX Runtime for model serving in the Edge AI platform, including model conversion, optimization, and deployment.

## Table of Contents
- [Overview](#overview)
- [Quick Start](#quick-start)
- [Model Conversion](#model-conversion)
- [Model Optimization](#model-optimization)
- [API Reference](#api-reference)
- [Model Management](#model-management)
- [Performance Tuning](#performance-tuning)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Advanced Topics](#advanced-topics)

## Overview

ONNX Runtime is a high-performance inference engine for machine learning models in the ONNX format. The Edge AI platform includes a pre-configured ONNX Runtime server that can serve multiple models simultaneously.

## Quick Start

1. **Start the services**:
   ```bash
   # Start all services
   make up
   
   # Or start just ONNX Runtime
   docker-compose up -d onnx-runtime
   ```

2. **Check ONNX Runtime status**:
   ```bash
   # Basic status check
   make onnx-status
   
   # Detailed metrics
   make onnx-metrics
   ```

3. **Convert and load a model**:
   ```bash
   # Convert PyTorch model
   make onnx-convert MODEL_PATH=model.pth MODEL_TYPE=pytorch
   
   # Or load existing ONNX model
   make onnx-load MODEL=my-model PATH=model.onnx
   ```

4. **Test and benchmark**:
   ```bash
   # Run a test inference
   make onnx-test
   
   # Run performance benchmark
   make onnx-benchmark
   ```

## API Reference

### Base URL
```
http://localhost:8001/v1/
```

### Endpoints

#### 1. List Models
```
GET /v1/models
```

#### 2. Model Metadata
```
GET /v1/models/{model_name}
```

#### 3. Model Inference
```
POST /v1/models/{model_name}/versions/{version}/infer
```

**Request Body:**
```json
{
  "inputs": {
    "input_1": {
      "name": "input_1",
      "shape": [1, 5],
      "datatype": "FP32",
      "data": [0.1, 0.2, 0.3, 0.4, 0.5]
    }
  },
  "outputs": [
    {"name": "output_1"}
  ]
}
```

## Model Conversion

For detailed instructions on converting models from various frameworks to ONNX format, see the [Model Conversion Guide](model-conversion.md).

### Quick Conversion Examples

#### PyTorch to ONNX
```bash
make onnx-convert MODEL_PATH=model.pth MODEL_TYPE=pytorch
```

#### TensorFlow/Keras to ONNX
```bash
make onnx-convert MODEL_PATH=model.h5 MODEL_TYPE=tensorflow
```

## Model Optimization

### Quantization
Reduce model size and improve performance:

```python
from onnxruntime.quantization import quantize_dynamic, QuantType

quantize_dynamic(
    'model.onnx',
    'model.quant.onnx',
    weight_type=QuantType.QUInt8
)
```

### Graph Optimization
Optimize the model graph for better performance:

```python
from onnxruntime.transformers import optimizer

optimized_model = optimizer.optimize_model('model.onnx')
optimized_model.save_model_to_file('model.optimized.onnx')
```

## Model Management

### Supported Model Formats
- ONNX models (`.onnx`)
- Quantized ONNX models (`.quant.onnx`)
- Optimized ONNX models (`.optimized.onnx`)

### Model Directory Structure
Place your models in the `models` directory:
```
edge/
  models/
    model1.onnx
    model1.quant.onnx
    model2.optimized.onnx
```

### Loading Models
1. **Manual**: Copy model files to the `models` directory
2. **Using Makefile**:
   ```bash
   # Load a single model
   make onnx-load MODEL=my-model PATH=model.onnx
   
   # Load all models from a directory
   cp /path/to/models/*.onnx models/
   ```

### Model Validation
Verify your model before deployment:

```bash
# Check model validity
python -m onnxruntime.tools.check_onnx_model model.onnx

# Run a quick inference test
python -c "
import onnxruntime as ort
sess = ort.InferenceSession('model.onnx')
print('Inputs:', [i.name for i in sess.get_inputs()])
print('Outputs:', [o.name for o in sess.get_outputs()])
"

## Examples

### Python Client
```python
import requests
import json

def predict(model_name, inputs):
    url = f"http://localhost:8001/v1/models/{model_name}/versions/1/infer"
    payload = {
        "inputs": {
            "input_1": {
                "name": "input_1",
                "shape": [1, 5],
                "datatype": "FP32",
                "data": inputs
            }
        },
        "outputs": [{"name": "output_1"}]
    }
    
    response = requests.post(url, json=payload)
    return response.json()

# Example usage
result = predict("wronai", [0.1, 0.2, 0.3, 0.4, 0.5])
print(json.dumps(result, indent=2))
```

### cURL Example
```bash
curl -X POST http://localhost:8001/v1/models/wronai/versions/1/infer \
  -H "Content-Type: application/json" \
  -d '{
    "inputs": {
      "input_1": {
        "name": "input_1",
        "shape": [1, 5],
        "datatype": "FP32",
        "data": [0.1, 0.2, 0.3, 0.4, 0.5]
      }
    },
    "outputs": [{"name": "output_1"}]
  }'
```

## Troubleshooting

### Common Issues

#### 1. Model Not Found
```
{
  "error_code": 404,
  "error_message": "Not Found. For HTTP method: POST and request path: /v1/models/non-existent-model/versions/1/infer"
}
```
**Solution**: Check the model name and ensure the model file exists in the `models` directory.

#### 2. Invalid Input Shape
```
{
  "error_code": 400,
  "error_message": "Invalid input shape"
}
```
**Solution**: Verify the input shape matches what the model expects.

#### 3. Server Not Responding
```
curl: (7) Failed to connect to localhost port 8001: Connection refused
```
**Solution**: Make sure the ONNX Runtime server is running:
```bash
docker-compose ps onnx-runtime
```

### Logs
View ONNX Runtime logs:
```bash
make onnx-logs
```

### Performance Tuning
For better performance, consider:
1. Using appropriate batch sizes
2. Enabling model optimization
3. Configuring thread pool size

## Advanced Configuration

### Environment Variables
Edit `docker-compose.yml` to customize ONNX Runtime settings:

```yaml
services:
  onnx-runtime:
    environment:
      - MODEL_DIR=/models
      - LOG_LEVEL=info
      - OMP_NUM_THREADS=4
```

### Model Optimization
For optimal performance, consider:
1. Quantizing models
2. Using ONNX Runtime optimizations
3. Enabling execution providers (CUDA, TensorRT, etc.)

## Monitoring
Monitor ONNX Runtime metrics in Grafana:
```
http://localhost:3007
```

## See Also
- [ONNX Runtime Documentation](https://onnxruntime.ai/)
- [ONNX Model Zoo](https://github.com/onnx/models)
