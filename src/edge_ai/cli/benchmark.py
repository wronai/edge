"""CLI commands for model benchmarking."""

import click
from pathlib import Path
from typing import List, Optional
from ...benchmark import benchmark_model, compare_models, print_benchmark_results

@click.command()
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
        edge-ai benchmark model.onnx -i 1,3,224,224
        
        # Compare multiple models
        edge-ai benchmark model1.onnx model2.onnx --compare
    """
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
            # Benchmark a single model
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
