# Model Conversion and Optimization Guide

This guide explains how to convert and optimize models for use with the Edge AI platform's ONNX Runtime service.

## Table of Contents
- [Supported Frameworks](#supported-frameworks)
- [Model Conversion](#model-conversion)
  - [PyTorch to ONNX](#pytorch-to-onnx)
  - [TensorFlow/Keras to ONNX](#tensorflowkeras-to-onnx)
- [Model Optimization](#model-optimization)
  - [Quantization](#quantization)
  - [Graph Optimization](#graph-optimization)
- [Model Validation](#model-validation)
- [Performance Benchmarking](#performance-benchmarking)
- [Troubleshooting](#troubleshooting)

## Supported Frameworks

The Edge AI platform supports models from the following frameworks:

- PyTorch (`.pt`, `.pth`)
- TensorFlow (`.h5`, `.pb`, saved_model)
- Keras (`.h5`, `.keras`)
- ONNX (`.onnx`)

## Model Conversion

### PyTorch to ONNX

#### Using Makefile
```bash
make onnx-convert MODEL_PATH=/path/to/model.pth MODEL_TYPE=pytorch
```

#### Manual Conversion
```python
import torch
import torchvision

# Load your PyTorch model
model = YourModelClass()
model.load_state_dict(torch.load('model.pth'))
model.eval()

# Create dummy input
dummy_input = torch.randn(1, 3, 224, 224)

# Export the model
torch.onnx.export(
    model,
    dummy_input,
    'model.onnx',
    export_params=True,
    opset_version=11,
    do_constant_folding=True,
    input_names=['input'],
    output_names=['output'],
    dynamic_axes={
        'input': {0: 'batch_size'},
        'output': {0: 'batch_size'}
    }
)
```

### TensorFlow/Keras to ONNX

#### Using Makefile
```bash
make onnx-convert MODEL_PATH=/path/to/model.h5 MODEL_TYPE=tensorflow
```

#### Manual Conversion
```python
import tensorflow as tf
import tf2onnx

# Load your TensorFlow/Keras model
model = tf.keras.models.load_model('model.h5')

# Define input signature
input_signature = (tf.TensorSpec((None, 224, 224, 3), tf.float32, name='input'),)

# Convert to ONNX
model_proto, _ = tf2onnx.convert.from_keras(
    model,
    input_signature=input_signature,
    opset=11,
    output_path='model.onnx'
)
```

## Model Optimization

### Quantization

Reduce model size and improve inference speed by quantizing weights and activations:

```python
import onnx
from onnxruntime.quantization import quantize_dynamic, QuantType

# Load the ONNX model
model_path = 'model.onnx'
quantized_model_path = 'model.quant.onnx'

# Apply dynamic quantization
quantize_dynamic(
    model_path,
    quantized_model_path,
    weight_type=QuantType.QUInt8
)
```

### Graph Optimization

Optimize the ONNX model graph:

```python
import onnx
from onnxruntime.transformers import optimizer

# Load the ONNX model
model_path = 'model.onnx'
optimized_model_path = 'model.optimized.onnx'

# Optimize model
optimized_model = optimizer.optimize_model(model_path, model_type='bert')
optimized_model.save_model_to_file(optimized_model_path)
```

## Model Validation

Verify your converted model:

```python
import onnx
import onnxruntime as ort

# Check model validity
onnx_model = onnx.load('model.onnx')
onnx.checker.check_model(onnx_model)

# Test inference
sess = ort.InferenceSession('model.onnx')
input_name = sess.get_inputs()[0].name
output_name = sess.get_outputs()[0].name

# Run inference
dummy_input = np.random.randn(1, 3, 224, 224).astype(np.float32)
result = sess.run([output_name], {input_name: dummy_input})
```

## Performance Benchmarking

Use the built-in benchmark tool:

```bash
# Run benchmark with default settings
make onnx-benchmark

# For more control, run directly:
python -m onnxruntime.tools.benchmark \
  -m model.onnx \
  -i 100 \
  -p 4 \
  -r 10 \
  -x 0  # Use CPU
```

## Troubleshooting

### Common Issues

#### 1. Unsupported Operators
```
RuntimeError: Unsupported ONNX opset version: 12
```
**Solution:** Specify a supported opset version (e.g., 11) during conversion.

#### 2. Shape Mismatch
```
RuntimeError: [ShapeInferenceError] Incompatible dimensions
```
**Solution:** Verify input shapes match model expectations.

#### 3. Missing Dependencies
```
ModuleNotFoundError: No module named 'tf2onnx'
```
**Solution:** Install required packages:
```bash
pip install tf2onnx onnxruntime
```

#### 4. Performance Issues
If inference is slow:
1. Enable graph optimizations
2. Quantize the model
3. Use appropriate execution providers

## Best Practices

1. **Use the latest ONNX opset** for better performance and compatibility
2. **Test thoroughly** after conversion
3. **Profile performance** with realistic inputs
4. **Consider quantization** for deployment
5. **Document model requirements** (input shapes, preprocessing, etc.)

## Additional Resources

- [ONNX Runtime Documentation](https://onnxruntime.ai/)
- [PyTorch ONNX Export](https://pytorch.org/docs/stable/onnx.html)
- [TensorFlow to ONNX](https://github.com/onnx/tensorflow-onnx)
- [ONNX Model Zoo](https://github.com/onnx/models)
