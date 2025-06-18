"""Basic tests for the Edge AI CLI commands with proper mocking."""

import sys
from unittest.mock import patch, MagicMock, mock_open
import pytest
from click.testing import CliRunner

# Mock TensorFlow and ONNX imports before importing the CLI module
sys.modules['tensorflow'] = MagicMock()
sys.modules['tensorflow.compat'] = MagicMock()
sys.modules['tensorflow.compat.v1'] = MagicMock()
sys.modules['tensorflow.compat.v2'] = MagicMock()
sys.modules['tensorflow.python.framework.tensor_spec'] = MagicMock()
sys.modules['onnx'] = MagicMock()
sys.modules['onnx.checker'] = MagicMock()

# Mock the tensorflow.TensorSpec class
class MockTensorSpec:
    def __init__(self, *args, **kwargs):
        pass

sys.modules['tensorflow'].TensorSpec = MockTensorSpec

# Now import the CLI module
from wronai_edge.cli import cli  # noqa: E402

@pytest.fixture
def runner():
    """Fixture for CLI runner."""
    return CliRunner()

def test_cli_help(runner):
    """Test the CLI help command."""
    result = runner.invoke(cli, ["--help"])
    assert result.exit_code == 0
    assert "Usage: cli [OPTIONS] COMMAND [ARGS]..." in result.output

@patch("wronai_edge.models.validator.validate_model")
def test_test_model_command(mock_validate, runner, tmp_path):
    """Test the test-model command with a mock model."""
    # Mock the validation result
    mock_validate.return_value = {
        "model_info": {"format": "ONNX", "version": 8},
        "validation_results": {
            "model_valid": True,
            "checks": [
                {"name": "model_structure", "passed": True, "message": "Valid"},
                {"name": "opset_version", "passed": True, "message": "Valid"},
            ],
        },
    }

    # Create a temporary file for testing
    test_model = tmp_path / "test_model.onnx"
    test_model.touch()
    output_json = tmp_path / "validation.json"

    result = runner.invoke(
        cli,
        ["test-model", str(test_model), "--output-json", str(output_json)],
    )

    assert result.exit_code == 0
    assert "Model validation successful" in result.output
    assert output_json.exists()

@patch("wronai_edge.cli.convert_pytorch_to_onnx")
def test_convert_pytorch_command(mock_convert, runner, tmp_path):
    """Test the convert pytorch command with a mock model."""
    mock_convert.return_value = True
    
    # Create temporary files
    input_model = tmp_path / "model.pt"
    input_model.touch()
    output_model = tmp_path / "output.onnx"

    result = runner.invoke(
        cli,
        ["convert", "pytorch", str(input_model), str(output_model)],
    )

    assert result.exit_code == 0
    assert "Successfully converted" in result.output
    mock_convert.assert_called_once()

@patch("wronai_edge.cli.convert_keras_to_onnx")
def test_convert_keras_command(mock_convert, runner, tmp_path):
    """Test the convert keras command with a mock model."""
    mock_convert.return_value = True
    
    # Create temporary files
    input_model = tmp_path / "model.h5"
    input_model.touch()
    output_model = tmp_path / "output.onnx"

    result = runner.invoke(
        cli,
        ["convert", "keras", str(input_model), str(output_model)],
    )

    assert result.exit_code == 0
    assert "Successfully converted" in result.output
    mock_convert.assert_called_once()

@patch("wronai_edge.cli.convert_savedmodel_to_onnx")
def test_convert_savedmodel_command(mock_convert, runner, tmp_path):
    """Test the convert savedmodel command with a mock model."""
    mock_convert.return_value = True
    
    # Create temporary directory for saved model
    saved_model_dir = tmp_path / "saved_model"
    saved_model_dir.mkdir()
    output_model = tmp_path / "output.onnx"

    result = runner.invoke(
        cli,
        ["convert", "savedmodel", str(saved_model_dir), str(output_model)],
    )

    assert result.exit_code == 0
    assert "Successfully converted" in result.output
    mock_convert.assert_called_once()
