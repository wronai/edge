"""Tests for the Edge AI CLI commands."""

import json
import tempfile
from pathlib import Path
from unittest.mock import patch

import pytest
from click.testing import CliRunner

# Import the CLI module
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


def test_test_model_command(runner):
    """Test the test-model command with a mock model."""
    with patch("wronai_edge.models.validator.validate_model") as mock_validate:
        # Mock the validation result
        mock_validate.return_value = {
            "model_info": {"format": "ONNX", "version": 8},
            "validation_results": {
                "model_valid": True,
                "checks": [
                    {"name": "model_structure", "passed": True, "message": "Valid model structure"},
                    {"name": "opset_version", "passed": True, "message": "Valid opset version"},
                ],
            },
        }

        with tempfile.NamedTemporaryFile(suffix=".onnx") as tmp:
            result = runner.invoke(
                cli,
                ["test-model", tmp.name, "--output-json", "validation_results.json"],
            )
    
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

@patch("wronai_edge.cli.convert_saved_model")
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
