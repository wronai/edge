"""Tests for the model validator."""

import pytest
from pathlib import Path
from wronai_edge.models.validator import validate_model

# This is a simple test model that should be available in the tests directory
TEST_MODEL_PATH = Path(__file__).parent / "test_data" / "test_model.onnx"

@pytest.mark.skipif(not TEST_MODEL_PATH.exists(), reason="Test model not found")
def test_validate_model():
    """Test model validation with a test ONNX model."""
    results = validate_model(str(TEST_MODEL_PATH))
    
    # Basic checks
    assert "model_loaded" in results
    assert results["model_loaded"]["passed"] is True
    
    # Check if inputs and outputs are detected
    assert "model_inputs" in results
    assert "model_outputs" in results
    assert results["model_inputs"]["passed"] is True
    assert results["model_outputs"]["passed"] is True
    
    # Check if inference test was run
    if "inference_test" in results:
        assert results["inference_test"]["passed"] is True
