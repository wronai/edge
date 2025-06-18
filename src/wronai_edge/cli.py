"""Command-line interface for Edge AI model tools."""

import os
import json
import click
from pathlib import Path
from typing import Optional, Dict, Any
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn

console = Console()

def print_success(message: str) -> None:
    """Print a success message."""
    console.print(f"[green]✓ {message}[/]")

def print_error(message: str) -> None:
    """Print an error message."""
    console.print(f"[red]✗ {message}[/]")

def print_warning(message: str) -> None:
    """Print a warning message."""
    console.print(f"[yellow]! {message}[/]")

@click.group()
@click.version_option()
@click.option("--verbose", "-v", is_flag=True, help="Enable verbose output")
@click.pass_context
def cli(ctx: click.Context, verbose: bool):
    """Edge AI model testing and building tools."""
    ctx.ensure_object(dict)
    ctx.obj['VERBOSE'] = verbose
    if verbose:
        console.print("[dim]Verbose mode enabled[/]")

@cli.command()
@click.option(
    "--model-path",
    required=True,
    type=click.Path(exists=True, dir_okay=False, path_type=Path),
    help="Path to the ONNX model file"
)
@click.option(
    "--output-json",
    type=click.Path(writable=True, dir_okay=False, path_type=Path),
    help="Save validation results to a JSON file"
)
@click.pass_context
def test_model(ctx: click.Context, model_path: Path, output_json: Optional[Path]):
    """Validate and test an ONNX model."""
    from .models.validator import validate_model_cli
    
    verbose = ctx.obj.get('VERBOSE', False)
    
    if verbose:
        console.print(f"[dim]Validating model: {model_path}[/]")
    
    try:
        success = validate_model_cli(str(model_path), str(output_json) if output_json else None)
        if not success:
            ctx.exit(1)
    except Exception as e:
        print_error(f"Error testing model: {str(e)}")
        if verbose:
            import traceback
            console.print(traceback.format_exc())
        ctx.exit(1)

@cli.group()
def convert():
    """Convert models between different formats."""
    pass

@convert.command()
@click.argument(
    "model_path",
    type=click.Path(exists=True, dir_okay=False, path_type=Path),
)
@click.argument(
    "output_path",
    type=click.Path(writable=True, dir_okay=False, path_type=Path),
)
@click.option(
    "--input-shape",
    type=str,
    help="Input shape as comma-separated values (e.g., '1,3,224,224')",
)
@click.option(
    "--opset",
    type=int,
    default=13,
    help="ONNX opset version to use for conversion"
)
@click.pass_context
def pytorch(
    ctx: click.Context,
    model_path: Path,
    output_path: Path,
    input_shape: Optional[str],
    opset: int
):
    """Convert a PyTorch model to ONNX format."""
    from .models.converter import convert_to_onnx
    
    verbose = ctx.obj.get('VERBOSE', False)
    
    try:
        input_shapes = None
        if input_shape:
            input_shapes = [tuple(map(int, input_shape.split(',')))]
        
        if verbose:
            console.print(f"[dim]Converting PyTorch model: {model_path} -> {output_path}")
            if input_shapes:
                console.print(f"[dim]Input shape: {input_shapes[0]}")
        
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            transient=True,
        ) as progress:
            progress.add_task(description="Converting model...", total=None)
            convert_to_onnx(
                model_path=str(model_path),
                output_path=str(output_path),
                input_shapes=input_shapes,
                opset_version=opset,
            )
        
        print_success(f"Successfully converted PyTorch model to ONNX: {output_path}")
        
    except Exception as e:
        print_error(f"Error converting PyTorch model: {str(e)}")
        if verbose:
            import traceback
            console.print(traceback.format_exc())
        ctx.exit(1)

@convert.command()
@click.argument(
    "model_path",
    type=click.Path(exists=True, file_okay=True, dir_okay=True, path_type=Path),
)
@click.argument(
    "output_path",
    type=click.Path(writable=True, dir_okay=False, path_type=Path),
)
@click.option(
    "--input-shape",
    type=str,
    help="Input shape as comma-separated values (e.g., '1,224,224,3' for Keras)",
)
@click.option(
    "--opset",
    type=int,
    default=13,
    help="ONNX opset version to use for conversion"
)
@click.pass_context
def keras(
    ctx: click.Context,
    model_path: Path,
    output_path: Path,
    input_shape: Optional[str],
    opset: int
):
    """Convert a Keras model to ONNX format."""
    from .models.tensorflow_converter import convert_keras_model, TensorFlowConverterError
    
    verbose = ctx.obj.get('VERBOSE', False)
    
    try:
        input_signature = None
        if input_shape:
            import tensorflow as tf
            shape = tuple(map(int, input_shape.split(',')))
            input_signature = [tf.TensorSpec(shape=shape, dtype=tf.float32)]
        
        if verbose:
            console.print(f"[dim]Converting Keras model: {model_path} -> {output_path}")
            if input_signature:
                console.print(f"[dim]Input signature: {input_signature}")
        
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            transient=True,
        ) as progress:
            progress.add_task(description="Converting Keras model...", total=None)
            convert_keras_model(
                model_path=str(model_path),
                output_path=str(output_path),
                opset=opset,
                input_signature=input_signature
            )
        
        print_success(f"Successfully converted Keras model to ONNX: {output_path}")
        
    except ImportError as e:
        print_error("TensorFlow is required for Keras model conversion. Install with: pip install tensorflow")
        ctx.exit(1)
    except TensorFlowConverterError as e:
        print_error(f"Error converting Keras model: {str(e)}")
        if verbose:
            import traceback
            console.print(traceback.format_exc())
        ctx.exit(1)
    except Exception as e:
        print_error(f"Unexpected error: {str(e)}")
        if verbose:
            import traceback
            console.print(traceback.format_exc())
        ctx.exit(1)

@convert.command()
@click.argument(
    "saved_model_dir",
    type=click.Path(exists=True, file_okay=False, dir_okay=True, path_type=Path),
)
@click.argument(
    "output_path",
    type=click.Path(writable=True, dir_okay=False, path_type=Path),
)
@click.option(
    "--signature-key",
    type=str,
    default="serving_default",
    help="Signature key to use for the model"
)
@click.option(
    "--opset",
    type=int,
    default=13,
    help="ONNX opset version to use for conversion"
)
@click.pass_context
def saved_model(
    ctx: click.Context,
    saved_model_dir: Path,
    output_path: Path,
    signature_key: str,
    opset: int
):
    """Convert a TensorFlow SavedModel to ONNX format."""
    from .models.tensorflow_converter import convert_saved_model, TensorFlowConverterError
    
    verbose = ctx.obj.get('VERBOSE', False)
    
    try:
        if verbose:
            console.print(f"[dim]Converting SavedModel: {saved_model_dir} -> {output_path}")
            console.print(f"[dim]Using signature key: {signature_key}")
        
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            transient=True,
        ) as progress:
            progress.add_task(description="Converting SavedModel...", total=None)
            convert_saved_model(
                saved_model_dir=str(saved_model_dir),
                output_path=str(output_path),
                opset=opset,
                signature_key=signature_key
            )
        
        print_success(f"Successfully converted SavedModel to ONNX: {output_path}")
        
    except ImportError as e:
        print_error("TensorFlow is required for SavedModel conversion. Install with: pip install tensorflow tf2onnx")
        ctx.exit(1)
    except TensorFlowConverterError as e:
        print_error(f"Error converting SavedModel: {str(e)}")
        if verbose:
            import traceback
            console.print(traceback.format_exc())
        ctx.exit(1)
    except Exception as e:
        print_error(f"Unexpected error: {str(e)}")
        if verbose:
            import traceback
            console.print(traceback.format_exc())
        ctx.exit(1)
    help="Path to the PyTorch model file"
)
@click.option(
    "--output-path",
    required=True,
    type=click.Path(dir_okay=False),
    help="Output path for the ONNX model"
)
@click.option(
    "--input-shape",
    default="1,3,224,224",
    help="Input shape for the model (comma-separated)",
    show_default=True
)
def convert_model(model_path, output_path, input_shape):
    """Convert a PyTorch model to ONNX format."""
    from .models.converter import convert_to_onnx
    
    try:
        input_shape = tuple(map(int, input_shape.split(",")))
        console.print(f"[bold]Converting model:[/] {model_path} -> {output_path}")
        console.print(f"[dim]Input shape:[/] {input_shape}")
        
        convert_to_onnx(model_path, output_path, input_shape)
        console.print(f"[green]✓ Successfully converted model to:[/] {output_path}")
        
    except Exception as e:
        console.print(f"[red]Error converting model:[/] {str(e)}", style="bold")
        raise click.Abort()

if __name__ == "__main__":
    cli()
