# Edge AI Model Tools

A Python package for converting and validating machine learning models, with a focus on ONNX format.

## Features

- **Model Validation**: Comprehensive validation of ONNX models
- **Model Conversion**:
  - PyTorch to ONNX
  - TensorFlow/Keras to ONNX
  - TensorFlow SavedModel to ONNX
  - TensorFlow functions to ONNX
- **CLI Tools**: Easy-to-use command-line interface
- **Rich Output**: Beautiful console output with rich

## Installation

```bash
# Install with PyTorch support
pip install wronai_edge[torch]

# Install with TensorFlow support
pip install wronai_edge[tensorflow]

# Install with all dependencies
pip install wronai_edge[all]
```

## Usage

### Command Line Interface

```bash
# Validate an ONNX model
wronai_edge validate-model path/to/model.onnx

# Convert a PyTorch model to ONNX
wronai_edge convert-pytorch path/to/model.pt path/to/output.onnx --input-shape 1,3,224,224

# Convert a Keras model to ONNX
wronai_edge convert-keras path/to/keras_model path/to/output.onnx
```

### Python API

```python
from wronai_edge import validate_model, convert_to_onnx

# Validate a model
results = validate_model("path/to/model.onnx")
print(f"Model validation passed: {results['validation_summary']['passed']}")

# Convert a PyTorch model to ONNX
convert_to_onnx(
    model_path="path/to/model.pt",
    output_path="path/to/output.onnx",
    input_shapes=[(1, 3, 224, 224)],
    output_names=["output"]
)
```

## Examples

See the [examples](/examples) directory for complete examples of model conversion and validation.

## Development

1. Clone the repository
2. Install dependencies:
   ```bash
   poetry install --with dev
   ```
3. Run tests:
   ```bash
   poetry run pytest
   ```

## License

MIT
