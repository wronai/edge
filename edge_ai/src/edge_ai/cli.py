"""Command-line interface for Edge AI model tools."""

import click
from rich.console import Console
from rich.table import Table

console = Console()

@click.group()
@click.version_option()
def cli():
    """Edge AI model testing and building tools."""
    pass

@cli.command()
@click.option(
    "--model-path",
    required=True,
    type=click.Path(exists=True, dir_okay=False),
    help="Path to the ONNX model file"
)
def test_model(model_path):
    """Test an ONNX model."""
    from .models.validator import validate_model
    
    try:
        console.print(f"[bold]Testing model:[/] {model_path}")
        results = validate_model(model_path)
        
        # Display results
        table = Table(show_header=True, header_style="bold magenta")
        table.add_column("Test", style="dim")
        table.add_column("Status", justify="right")
        
        for test, status in results.items():
            status_style = "green" if status["passed"] else "red"
            status_text = "✓" if status["passed"] else "✗"
            table.add_row(test, f"[{status_style}]{status_text} {status['message']}")
        
        console.print(table)
        
    except Exception as e:
        console.print(f"[red]Error testing model:[/] {str(e)}", style="bold")
        raise click.Abort()

@cli.command()
@click.option(
    "--model-path",
    required=True,
    type=click.Path(exists=True, dir_okay=False),
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
