"""Minimal tests for the Edge AI CLI commands with complete mocking."""

import os
import sys
from pathlib import Path
from unittest.mock import patch, MagicMock
import pytest
from click.testing import CliRunner

# Add the project root to the Python path
project_root = str(Path(__file__).parent.parent)
sys.path.insert(0, project_root)

# Now import the CLI module
try:
    from wronai_edge.cli import cli as cli_command
except ImportError as e:
    print(f"Error importing wronai_edge.cli: {e}")
    raise

# Mock the validator
@pytest.fixture(autouse=True)
def mock_validator():
    """Mock the validator module."""
    with patch('wronai_edge.models.validator') as mock_val:
        mock_val.validate_model.return_value = {"status": "success"}
        yield mock_val

# Mock the converters
@pytest.fixture(autouse=True)
def mock_converters():
    """Mock the converters module."""
    with patch('wronai_edge.converters') as mock_conv:
        mock_conv.convert_model.return_value = "converted_model.onnx"
        yield mock_conv

@pytest.fixture
def runner():
    """Fixture for CLI runner."""
    return CliRunner()

def test_cli_help(runner):
    """Test the CLI help command."""
    result = runner.invoke(cli_command, ["--help"])
    assert result.exit_code == 0
    assert "Usage:" in result.output
    assert "convert" in result.output or "test-model" in result.output

def test_test_model_command(runner, tmp_path):
    """Test the test-model command with a mock model."""
    # Create a temporary file for testing
    test_model = tmp_path / "test_model.onnx"
    test_model.write_text("dummy content")
    
    with patch('wronai_edge.models.validator.validate_model') as mock_validate:
        mock_validate.return_value = {"status": "success"}
        
        result = runner.invoke(
            cli_command,
            ["test-model", str(test_model)],
        )
        
        assert result.exit_code == 0
        assert "success" in result.output
        mock_validate.assert_called_once()

def test_convert_command(runner, tmp_path):
    """Test the convert command with a mock model."""
    # Create temporary files
    input_model = tmp_path / "model.pt"
    input_model.write_text("dummy content")
    output_model = tmp_path / "output.onnx"
    
    with patch('wronai_edge.converters.convert_model') as mock_convert:
        mock_convert.return_value = str(output_model)
        
        result = runner.invoke(
            cli_command,
            ["convert", "pytorch", str(input_model), "--output", str(output_model)],
        )
        
        assert result.exit_code == 0
        assert "success" in result.output.lower() or "converted" in result.output.lower()
        mock_convert.assert_called_once()
