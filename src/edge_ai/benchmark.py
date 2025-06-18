"""Model benchmarking utilities."""

import time
import numpy as np
import onnxruntime as ort
from pathlib import Path
from typing import Dict, Any, List, Optional, Tuple, Union
import psutil
import os

def benchmark_model(
    model_path: Union[str, Path],
    input_shapes: Optional[List[Tuple[int, ...]]] = None,
    warmup: int = 10,
    runs: int = 100,
    use_gpu: bool = True
) -> Dict[str, float]:
    """
    Benchmark an ONNX model.
    
    Args:
        model_path: Path to the ONNX model
        input_shapes: List of input shapes for the model
        warmup: Number of warmup runs
        runs: Number of benchmark runs
        use_gpu: Whether to use GPU for inference
        
    Returns:
        Dictionary containing benchmark results
    """
    # Set up ONNX Runtime session
    providers = ['CUDAExecutionProvider', 'CPUExecutionProvider'] if use_gpu else ['CPUExecutionProvider']
    session_options = ort.SessionOptions()
    session_options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
    
    session = ort.InferenceSession(
        str(model_path),
        providers=providers,
        sess_options=session_options
    )
    
    # Get model inputs
    input_details = session.get_inputs()
    
    # Generate random input data if shapes not provided
    if input_shapes is None:
        input_shapes = [tuple(dim if isinstance(dim, int) and dim > 0 else 1 
                            for dim in input_.shape) 
                       for input_ in input_details]
    
    # Create random input data
    input_data = {
        input_.name: np.random.randn(*shape).astype(np.float32)
        for input_, shape in zip(input_details, input_shapes)
    }
    
    # Warmup runs
    for _ in range(warmup):
        session.run(None, input_data)
    
    # Benchmark runs
    start_mem = _get_process_memory()
    start_time = time.perf_counter()
    
    for _ in range(runs):
        session.run(None, input_data)
    
    end_time = time.perf_counter()
    end_mem = _get_process_memory()
    
    # Calculate metrics
    total_time = end_time - start_time
    avg_latency = (total_time / runs) * 1000  # Convert to ms
    throughput = runs / total_time
    memory_usage = max(0, end_mem - start_mem)
    
    return {
        'avg_latency': avg_latency,
        'throughput': throughput,
        'memory_mb': memory_usage,
        'total_time': total_time,
        'runs': runs
    }

def _get_process_memory() -> float:
    """Get current process memory usage in MB."""
    process = psutil.Process(os.getpid())
    return process.memory_info().rss / (1024 * 1024)  # Convert to MB

def compare_models(
    model_paths: List[Union[str, Path]],
    input_shapes: Optional[List[Tuple[int, ...]]] = None,
    warmup: int = 10,
    runs: int = 100,
    use_gpu: bool = True
) -> Dict[str, Dict[str, float]]:
    """
    Compare multiple ONNX models.
    
    Args:
        model_paths: List of paths to ONNX models
        input_shapes: List of input shapes for the models
        warmup: Number of warmup runs
        runs: Number of benchmark runs
        use_gpu: Whether to use GPU for inference
        
    Returns:
        Dictionary mapping model names to benchmark results
    """
    results = {}
    
    for model_path in model_paths:
        model_name = Path(model_path).stem
        print(f"Benchmarking {model_name}...")
        
        try:
            results[model_name] = benchmark_model(
                model_path=model_path,
                input_shapes=input_shapes,
                warmup=warmup,
                runs=runs,
                use_gpu=use_gpu
            )
        except Exception as e:
            print(f"Error benchmarking {model_name}: {str(e)}")
            continue
    
    return results

def print_benchmark_results(results: Dict[str, Dict[str, float]]):
    """Print benchmark results in a formatted table."""
    if not results:
        print("No benchmark results to display.")
        return
    
    # Prepare data for printing
    headers = ["Model", "Avg Latency (ms)", "Throughput (samples/s)", "Memory (MB)"]
    rows = []
    
    for model_name, metrics in results.items():
        rows.append([
            model_name,
            f"{metrics['avg_latency']:.2f}",
            f"{metrics['throughput']:.2f}",
            f"{metrics['memory_mb']:.2f}"
        ])
    
    # Find maximum width for each column
    col_widths = [max(len(str(row[i])) for row in [headers] + rows) for i in range(len(headers))]
    
    # Print headers
    header_row = " | ".join(h.ljust(w) for h, w in zip(headers, col_widths))
    print("\n" + "=" * len(header_row))
    print(header_row)
    print("-" * len(header_row))
    
    # Print rows
    for row in rows:
        print(" | ".join(str(x).ljust(w) for x, w in zip(row, col_widths)))
    
    print("=" * len(header_row) + "\n")
