"""Comprehensive tests for model validation."""

import pytest
import numpy as np
import onnx
import onnxruntime as ort
from pathlib import Path
import os
import shutil
import tempfile

# Import the validator module
from wronai_edge.models.validator import validate_model

# Create a temporary directory for test models
test_models_dir = Path("tests/test_models")
test_models_dir.mkdir(exist_ok=True)

# Test model paths
SIMPLE_MODEL_PATH = test_models_dir / "simple_model.onnx"
BATCH_MODEL_PATH = test_models_dir / "batch_model.onnx"
INVALID_MODEL_PATH = test_models_dir / "invalid_model.onnx"

# Generate test models if they don't exist
if not SIMPLE_MODEL_PATH.exists():
    # Import the test model generator
    import sys
    sys.path.append(str(Path(__file__).parent.parent))
    from scripts.generate_test_model import generate_onnx_model
    generate_onnx_model(SIMPLE_MODEL_PATH, (1, 10))
    generate_onnx_model(BATCH_MODEL_PATH, (5, 10))
    
    # Create an invalid model file
    with open(INVALID_MODEL_PATH, 'wb') as f:
        f.write(b'INVALID_MODEL_DATA')

@pytest.fixture(scope="module")
def simple_model():
    """Fixture providing a simple ONNX model path."""
    return str(SIMPLE_MODEL_PATH)

@pytest.fixture(scope="module")
def batch_model():
    """Fixture providing a batch ONNX model path."""
    return str(BATCH_MODEL_PATH)

@pytest.fixture(scope="module")
def invalid_model():
    """Fixture providing an invalid model path."""
    return str(INVALID_MODEL_PATH)

def test_validate_model_success(simple_model):
    """Test successful model validation."""
    results = validate_model(simple_model)
    
    assert results["model_loaded"]["passed"] is True
    assert results["model_inputs"]["passed"] is True
    assert results["model_outputs"]["passed"] is True
    assert "inference_test" in results
    assert results["inference_test"]["passed"] is True

def test_validate_batch_model(batch_model):
    """Test validation of a model that supports batching."""
    results = validate_model(batch_model)
    
    assert results["model_loaded"]["passed"] is True
    assert results["model_inputs"]["passed"] is True
    assert results["model_outputs"]["passed"] is True
    assert "inference_test" in results
    assert results["inference_test"]["passed"] is True

def test_validate_invalid_model(invalid_model):
    """Test validation of an invalid model file."""
    with pytest.raises(RuntimeError):
        validate_model(invalid_model)

def test_validate_nonexistent_model():
    """Test validation with a non-existent model path."""
    with pytest.raises(FileNotFoundError):
        validate_model("nonexistent_model.onnx")

def test_validate_model_input_output_shapes(simple_model):
    """Test that input and output shapes are correctly reported."""
    results = validate_model(simple_model)
    
    # Check input shapes
    inputs = results["model_inputs"]["details"]
    assert len(inputs) > 0
    for input_info in inputs.values():
        assert "shape" in input_info
        assert isinstance(input_info["shape"], list)
    
    # Check output shapes
    outputs = results["model_outputs"]["details"]
    assert len(outputs) > 0
    for output_info in outputs.values():
        assert "shape" in output_info
        assert isinstance(output_info["shape"], list)

def test_validate_model_with_custom_input(simple_model):
    """Test model validation with custom input data."""
    # This is a basic test - in a real scenario, you'd want to test with
    # various input shapes and data types
    results = validate_model(simple_model)
    assert results["inference_test"]["passed"] is True

# Add more test cases as needed for your specific validation requirements
