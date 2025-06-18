"""Tests for the Edge AI CLI commands."""

import os
import sys
import json
import pytest
import tempfile
from pathlib import Path
from unittest.mock import patch, MagicMock
from click.testing import CliRunner

# Add the src directory to the Python path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

# Import the CLI module
from edge_ai.cli import cli

# Test data paths
TEST_DATA_DIR = Path(__file__).parent / "test_data"
TEST_MODEL_PATH = TEST_DATA_DIR / "test_model.onnx"
TEST_PYTORCH_MODEL_PATH = TEST_DATA_DIR / "test_model.pt"
TEST_KERAS_MODEL_PATH = TEST_DATA_DIR / "test_model.h5"
TEST_SAVED_MODEL_PATH = TEST_DATA_DIR / "saved_model"

# Create test data directory if it doesn't exist
TEST_DATA_DIR.mkdir(exist_ok=True)

# Create a simple ONNX model for testing
if not TEST_MODEL_PATH.exists():
    import numpy as np
    import onnx
    from onnx import helper, TensorProto
    
    # Create a simple model
    X = helper.make_tensor_value_info('X', TensorProto.FLOAT, [1, 3, 224, 224])
    Y = helper.make_tensor_value_info('Y', TensorProto.FLOAT, [1, 10])
    
    # Create a simple graph
    node = helper.make_node(
        'Gemm',
        ['X'],
        ['Y'],
        name='gemm_node'
    )
    
    # Create the graph
    graph_def = helper.make_graph(
        [node],
        'test-model',
        [X],
        [Y]
    )
    
    # Create the model
    model_def = helper.make_model(graph_def, producer_name='test-model')
    
    # Save the model
    onnx.save(model_def, str(TEST_MODEL_PATH))

# Create a dummy PyTorch model for testing
if not TEST_PYTORCH_MODEL_PATH.exists():
    import torch
    import torch.nn as nn
    
    class DummyModel(nn.Module):
        def __init__(self):
            super().__init__()
            self.fc = nn.Linear(10, 2)
        
        def forward(self, x):
            return self.fc(x)
    
    model = DummyModel()
    torch.save(model.state_dict(), str(TEST_PYTORCH_MODEL_PATH))

@pytest.fixture
def runner():
    """Fixture for CLI runner."""
    return CliRunner()

@pytest.fixture
def temp_dir():
    """Fixture for temporary directory."""
    with tempfile.TemporaryDirectory() as tmpdir:
        yield Path(tmpdir)

def test_cli_help(runner):
    """Test the CLI help output."""
    # Test main help
    result = runner.invoke(cli, ["--help"])
    assert result.exit_code == 0
    assert "Edge AI model testing and building tools" in result.output
    
    # Test test-model help
    result = runner.invoke(cli, ["test-model", "--help"])
    assert result.exit_code == 0
    
    # Test convert help
    result = runner.invoke(cli, ["convert", "--help"])
    assert result.exit_code == 0

def test_test_model_command(runner, temp_dir):
    """Test the test-model command with a valid model."""
    # Create a test model if it doesn't exist
    if not TEST_MODEL_PATH.exists():
        pytest.skip("Test model not found")
    
    # Test with default options
    result = runner.invoke(cli, ["test-model", str(TEST_MODEL_PATH)])
    assert result.exit_code == 0
    assert "Model validation" in result.output
    
    # Test with JSON output
    output_json = temp_dir / "results.json"
    result = runner.invoke(cli, [
        "test-model",
        str(TEST_MODEL_PATH),
        "--output-json", str(output_json)
    ])
    assert result.exit_code == 0
    assert output_json.exists()
    
    # Verify JSON content
    with open(output_json) as f:
        data = json.load(f)
    assert "model_loaded" in data
    assert data["model_loaded"]["passed"] is True

@patch("edge_ai.cli.convert_to_onnx")
def test_convert_pytorch_command(mock_convert, runner, temp_dir):
    """Test the convert pytorch command."""
    # Setup mock
    mock_convert.return_value = None
    
    output_path = temp_dir / "output.onnx"
    
    # Test with required arguments
    result = runner.invoke(cli, [
        "convert", "pytorch",
        str(TEST_PYTORCH_MODEL_PATH),
        str(output_path),
        "--input-shape", "1,3,224,224"
    ])
    
    assert result.exit_code == 0
    assert "Successfully converted PyTorch model" in result.output
    mock_convert.assert_called_once()

@patch("edge_ai.cli.convert_keras_model")
def test_convert_keras_command(mock_convert, runner, temp_dir):
    """Test the convert keras command."""
    # Setup mock
    mock_convert.return_value = None
    
    output_path = temp_dir / "output.onnx"
    
    # Test with required arguments
    result = runner.invoke(cli, [
        "convert", "keras",
        str(TEST_KERAS_MODEL_PATH),
        str(output_path),
        "--input-shape", "1,224,224,3"
    ])
    
    # If TensorFlow is not installed, the command should fail with exit code 1
    if "No module named 'tensorflow'" in str(result.exception):
        assert result.exit_code == 1
    else:
        assert result.exit_code == 0
        assert "Successfully converted Keras model" in result.output
        mock_convert.assert_called_once()

@patch("edge_ai.cli.convert_saved_model")
def test_convert_saved_model_command(mock_convert, runner, temp_dir):
    """Test the convert saved-model command."""
    # Setup mock
    mock_convert.return_value = None
    
    output_path = temp_dir / "output.onnx"
    saved_model_dir = temp_dir / "saved_model"
    saved_model_dir.mkdir()
    
    # Test with required arguments
    result = runner.invoke(cli, [
        "convert", "saved-model",
        str(saved_model_dir),
        str(output_path)
    ])
    
    # If TensorFlow is not installed, the command should fail with exit code 1
    if "No module named 'tensorflow'" in str(result.exception):
        assert result.exit_code == 1
    else:
        assert result.exit_code == 0
        assert "Successfully converted SavedModel" in result.output
        mock_convert.assert_called_once()

def test_verbose_flag(runner):
    """Test the verbose flag."""
    # Test with verbose flag
    result = runner.invoke(cli, ["--version", "--verbose"])
    assert result.exit_code == 0
    assert "Verbose mode enabled" in result.output

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
