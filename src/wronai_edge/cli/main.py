"""Edge AI Model Management CLI."""

import click
import sys
import os
from pathlib import Path
from typing import Optional, List, Tuple

# Add the package root to the Python path
package_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, package_root)

# Now import the package modules
from wronai_edge.converters import convert_model
from wronai_edge.benchmark import benchmark_model, compare_models, print_benchmark_results

@click.group()
def cli():
    """Edge AI Model Management CLI"""
    pass

@cli.command()
@click.argument('model_type', type=click.Choice(['pytorch', 'tensorflow']))
@click.argument('model_path', type=click.Path(exists=True))
@click.option('--output', '-o', default='model.onnx', help='Output ONNX model path')
@click.option('--opset', type=int, default=13, help='ONNX opset version')
def convert(model_type: str, model_path: str, output: str, opset: int):
    """Convert a PyTorch or TensorFlow model to ONNX format"""
    from wronai_edge.converters import convert_model
    
    try:
        output_path = convert_model(model_type, model_path, output, opset)
        click.echo(f"✓ Model converted successfully to {output_path}")
    except Exception as e:
        click.echo(f"Error converting model: {str(e)}", err=True)
        raise click.Abort()

@cli.command()
@click.argument('model_paths', nargs=-1, type=click.Path(exists=True))
@click.option('--input-shape', '-i', multiple=True, 
              help='Input shape (e.g., 1,3,224,224). Can be specified multiple times for multiple inputs.')
@click.option('--warmup', type=int, default=10, help='Number of warmup runs')
@click.option('--runs', type=int, default=100, help='Number of benchmark runs')
@click.option('--cpu/--gpu', default=False, help='Force CPU usage')
@click.option('--compare', is_flag=True, help='Compare multiple models')
def benchmark(
    model_paths: List[str],
    input_shape: List[str],
    warmup: int,
    runs: int,
    cpu: bool,
    compare: bool
):
    """Benchmark ONNX model(s) performance.
    
    Examples:
        # Benchmark a single model
        wronai_edge benchmark model.onnx -i 1,3,224,224
        
        # Compare multiple models
        wronai_edge benchmark model1.onnx model2.onnx --compare
    """
    from ..benchmark import benchmark_model, compare_models, print_benchmark_results
    
    if not model_paths:
        click.echo("Error: At least one model path must be provided.", err=True)
        return
    
    # Parse input shapes
    input_shapes = None
    if input_shape:
        input_shapes = [
            tuple(int(dim) for dim in shape.split(','))
            for shape in input_shape
        ]
    
    try:
        if compare and len(model_paths) > 1:
            # Compare multiple models
            results = {}
            for model_path in model_paths:
                click.echo(f"\nBenchmarking {Path(model_path).name}...")
                results[model_path] = benchmark_model(
                    model_path=model_path,
                    input_shapes=input_shapes,
                    warmup=warmup,
                    runs=runs,
                    use_gpu=not cpu
                )
            
            click.echo("\n=== Benchmark Results ===")
            print_benchmark_results(results)
            
        else:
            # Benchmark a single model (legacy behavior)
            if len(model_paths) > 1:
                click.echo("Warning: Multiple models provided but --compare flag not set. "
                          "Only the first model will be benchmarked.", err=True)
            
            model_path = model_paths[0]
            click.echo(f"Benchmarking {model_path}...")
            
            result = benchmark_model(
                model_path=model_path,
                input_shapes=input_shapes,
                warmup=warmup,
                runs=runs,
                use_gpu=not cpu
            )
            
            click.echo("\n=== Benchmark Results ===")
            print_benchmark_results({Path(model_path).name: result})
            
    except Exception as e:
        click.echo(f"Error during benchmarking: {str(e)}", err=True)
        raise click.Abort()

# Import other command groups
from wronai_edge.cli import benchmark as benchmark_commands

if __name__ == '__main__':
    cli()
