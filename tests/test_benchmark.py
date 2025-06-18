"""Tests for the benchmark module."""

import os
import pytest
import numpy as np
from pathlib import Path
from edge_ai.benchmark import benchmark_model, compare_models

# Create a simple ONNX model for testing
@pytest.fixture(scope="module")
def test_onnx_model(tmp_path_factory):
    import onnx
    from onnx import helper, TensorProto
    
    # Create a simple model: Add operation
    node_def = helper.make_node(
        'Add',
        inputs=['x', 'y'],
        outputs=['z']
    )
    
    graph_def = helper.make_graph(
        [node_def],
        'test-model',
        [
            helper.make_tensor_value_info('x', TensorProto.FLOAT, [1, 3, 224, 224]),
            helper.make_tensor_value_info('y', TensorProto.FLOAT, [1, 3, 224, 224]),
        ],
        [helper.make_tensor_value_info('z', TensorProto.FLOAT, [1, 3, 224, 224])]
    )
    
    model_def = helper.make_model(graph_def, producer_name='test-model')
    model_path = tmp_path_factory.mktemp("models") / "test_model.onnx"
    onnx.save(model_def, str(model_path))
    return model_path

def test_benchmark_model(test_onnx_model):
    """Test benchmarking a single model."""
    results = benchmark_model(
        model_path=test_onnx_model,
        input_shapes=[(1, 3, 224, 224), (1, 3, 224, 224)],
        warmup=1,
        runs=2,
        use_gpu=False  # Use CPU for testing
    )
    
    assert 'avg_latency' in results
    assert 'throughput' in results
    assert 'memory_mb' in results
    assert results['runs'] == 2

def test_compare_models(test_onnx_model, tmp_path):
    """Test comparing multiple models."""
    # Create a copy of the test model to compare against itself
    import shutil
    model_path2 = tmp_path / "test_model2.onnx"
    shutil.copy(test_onnx_model, model_path2)
    
    results = compare_models(
        model_paths=[test_onnx_model, model_path2],
        input_shapes=[(1, 3, 224, 224), (1, 3, 224, 224)],
        warmup=1,
        runs=2,
        use_gpu=False  # Use CPU for testing
    )
    
    assert len(results) == 2
    assert 'test_model' in str(results.keys())
    assert 'test_model2' in str(results.keys())
    
    for model_results in results.values():
        assert 'avg_latency' in model_results
        assert 'throughput' in model_results
        assert 'memory_mb' in model_results
        assert model_results['runs'] == 2
