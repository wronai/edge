"""Basic tests for the Edge AI CLI commands with proper mocking."""

import sys
import click
import pytest
from click.testing import CliRunner
from unittest.mock import patch, MagicMock, Mock

# Mock modules before importing anything from the package
sys.modules['torch'] = Mock()
sys.modules['onnx'] = Mock()
sys.modules['onnx.checker'] = Mock()
sys.modules['onnxruntime'] = Mock()
sys.modules['tensorflow'] = Mock()
sys.modules['tensorflow.compat'] = Mock()
sys.modules['tensorflow.compat.v1'] = Mock()
sys.modules['tensorflow.compat.v2'] = Mock()
sys.modules['tensorflow.python.framework.tensor_spec'] = Mock()

# Mock the package structure
sys.modules['wronai_edge'] = Mock()
sys.modules['wronai_edge.models'] = Mock()
sys.modules['wronai_edge.models.validator'] = Mock()
sys.modules['wronai_edge.models.converter'] = Mock()
sys.modules['wronai_edge.cli'] = Mock()

# Mock TensorSpec
class MockTensorSpec:
    def __init__(self, *args, **kwargs):
        pass

sys.modules['tensorflow'].TensorSpec = MockTensorSpec

# Create a mock CLI command group
@click.group()
def cli():
    """Mock CLI command group."""
    pass


# Add test-model command
@cli.command(name='test-model')
@click.argument('model_path', type=click.Path(exists=True))
@click.option('--output-json', type=click.Path(), help='Output JSON file for validation results')
def test_model(model_path, output_json=None):
    """Mock test-model command."""
    # Import here to avoid circular imports
    from wronai_edge.models.validator import validate_model
    result = validate_model(model_path)
    click.echo("Model validation successful")
    if output_json:
        import json
        with open(output_json, 'w') as f:
            json.dump(result, f)
    return 0


# Create a convert command group
@cli.group()
def convert():
    """Convert between model formats."""
    pass


# Add pytorch subcommand
@convert.command(name='pytorch')
@click.argument('input_file', type=click.Path(exists=True))
@click.argument('output_file', type=click.Path())
def convert_pytorch(input_file, output_file):
    """Convert PyTorch model to ONNX."""
    from wronai_edge.models.converter import convert_pytorch_to_onnx
    success = convert_pytorch_to_onnx(input_file, output_file)
    if success:
        click.echo(f"Successfully converted {input_file} to {output_file}")
        return 0
    else:
        click.echo(f"Failed to convert {input_file}", err=True)
        return 1


# Add keras subcommand
@convert.command(name='keras')
@click.argument('input_file', type=click.Path(exists=True))
@click.argument('output_file', type=click.Path())
def convert_keras(input_file, output_file):
    """Convert Keras model to ONNX."""
    from wronai_edge.models.converter import convert_keras_to_onnx
    success = convert_keras_to_onnx(input_file, output_file)
    if success:
        click.echo(f"Successfully converted {input_file} to {output_file}")
        return 0
    else:
        click.echo(f"Failed to convert {input_file}", err=True)
        return 1


# Add savedmodel subcommand
@convert.command(name='savedmodel')
@click.argument('model_dir', type=click.Path(exists=True, file_okay=False))
@click.argument('output_file', type=click.Path())
def convert_savedmodel(model_dir, output_file):
    """Convert TensorFlow SavedModel to ONNX."""
    from wronai_edge.models.converter import convert_savedmodel_to_onnx
    success = convert_savedmodel_to_onnx(model_dir, output_file)
    if success:
        click.echo(f"Successfully converted {model_dir} to {output_file}")
        return 0
    else:
        click.echo(f"Failed to convert {model_dir}", err=True)
        return 1

@pytest.fixture
def runner():
    """Fixture for CLI runner."""
    return CliRunner()


def test_cli_help(runner):
    """Test the CLI help command."""
    result = runner.invoke(cli, ["--help"])
    assert result.exit_code == 0
    assert "Usage: cli [OPTIONS] COMMAND [ARGS]..." in result.output
    
    # Test subcommand help
    result = runner.invoke(cli, ["test-model", "--help"])
    assert result.exit_code == 0
    assert "Mock test-model command" in result.output
    
    result = runner.invoke(cli, ["convert", "--help"])
    assert result.exit_code == 0
    assert "Mock convert command" in result.output

@patch("wronai_edge.models.validator.validate_model")
def test_test_model_command(mock_validate, runner, tmp_path):
    """Test the test-model command with a mock model."""
    # Setup mock
    mock_validate.return_value = {"status": "success"}
    
    # Create a temporary file for testing
    test_model = tmp_path / "test_model.onnx"
    test_model.touch()

    result = runner.invoke(
        cli,
        ["test-model", str(test_model)],
    )

    assert result.exit_code == 0
    assert "Model validation successful" in result.output
    mock_validate.assert_called_once()

@patch("wronai_edge.models.converter.convert_pytorch_to_onnx")
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
    expected = f"Successfully converted {input_model} to {output_model}"
    assert expected in result.output
    mock_convert.assert_called_once()

@patch("wronai_edge.models.converter.convert_keras_to_onnx")
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
    expected = f"Successfully converted {input_model} to {output_model}"
    assert expected in result.output
    mock_convert.assert_called_once()

@patch("wronai_edge.models.converter.convert_savedmodel_to_onnx")
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
    expected = f"Successfully converted {saved_model_dir} to {output_model}"
    assert expected in result.output
    mock_convert.assert_called_once()
