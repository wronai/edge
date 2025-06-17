# ONNX Runtime Examples

This directory contains example scripts for working with the ONNX Runtime server.

## Prerequisites

1. Python 3.8 or higher
2. Required Python packages:
   ```bash
   pip install -r requirements.txt
   ```
3. A running ONNX Runtime server (default: http://localhost:8001)

## Example Scripts

### 1. Quickstart Example

`onnx_quickstart.py` - A complete example showing how to:
- Connect to the ONNX Runtime server
- List available models
- Get model metadata
- Make predictions

**Usage:**
```bash
python onnx_quickstart.py
```

### 2. ONNX Inference Example

`onnx_inference.py` - A more detailed example showing how to:
- Initialize the ONNX client
- Make predictions with proper error handling
- Process model inputs and outputs

**Usage:**
```bash
python onnx_inference.py
```

## Example API Usage

### Checking Server Status

```python
import requests

response = requests.get("http://localhost:8001/v1/")
print(response.json())
```

### Making a Prediction

```python
import requests
import json

# Example input - adjust based on your model's expected input
input_data = {
    "instances": [
        {
            "input_1": [0.1, 0.2, 0.3, 0.4, 0.5]
        }
    ]
}

response = requests.post(
    "http://localhost:8001/v1/models/your-model-name:predict",
    json=input_data,
    headers={"Content-Type": "application/json"}
)

print(json.dumps(response.json(), indent=2))
```

## Troubleshooting

1. **Connection Refused**
   - Make sure the ONNX Runtime server is running
   - Check the server URL and port

2. **Model Not Found**
   - Verify the model name is correct
   - Check that the model is loaded in the server

3. **Input Shape Mismatch**
   - Verify the input shape matches what the model expects
   - Check the model's input requirements

For more information, see the [main documentation](../../README.md).
