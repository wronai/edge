import click
from pathlib import Path
from typing import Optional

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
    from ..converters import convert_model
    
    try:
        output_path = convert_model(model_type, model_path, output, opset)
        click.echo(f"✓ Model converted successfully to {output_path}")
    except Exception as e:
        click.echo(f"Error converting model: {str(e)}", err=True)
        raise click.Abort()

@cli.command()
@click.argument('model_path', type=click.Path(exists=True))
@click.option('--input-shape', '-i', multiple=True, help='Input shape (e.g., 1,3,224,224)')
@click.option('--warmup', type=int, default=10, help='Number of warmup runs')
@click.option('--runs', type=int, default=100, help='Number of benchmark runs')
def benchmark(model_path: str, input_shape: Optional[tuple], warmup: int, runs: int):
    """Benchmark an ONNX model"""
    from ..models import benchmark_model
    
    try:
        if input_shape:
            input_shape = [tuple(map(int, shape.split(','))) for shape in input_shape]
        
        results = benchmark_model(model_path, input_shape, warmup, runs)
        
        click.echo("\nBenchmark Results:")
        click.echo(f"Model: {model_path}")
        click.echo(f"Latency (avg): {results['avg_latency']:.4f} ms")
        click.echo(f"Throughput: {results['throughput']:.2f} samples/sec")
        click.echo(f"Memory usage: {results['memory_mb']:.2f} MB")
        
    except Exception as e:
        click.echo(f"Error benchmarking model: {str(e)}", err=True)
        raise click.Abort()

if __name__ == '__main__':
    cli()
