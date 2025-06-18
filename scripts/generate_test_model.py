"""Generate test ONNX models for testing."""

import os
import numpy as np
import torch
import torch.nn as nn
from pathlib import Path

class SimpleModel(nn.Module):
    """A simple test model for ONNX export."""
    def __init__(self):
        super().__init__()
        self.linear = nn.Linear(10, 5)
        self.relu = nn.ReLU()
    
    def forward(self, x):
        return self.relu(self.linear(x))

def generate_onnx_model(output_path: str, input_shape: tuple = (1, 10)):
    """Generate a simple ONNX model for testing.
    
    Args:
        output_path: Path to save the ONNX model
        input_shape: Input shape for the model
    """
    model = SimpleModel()
    model.eval()
    
    # Create dummy input
    dummy_input = torch.randn(*input_shape)
    
    # Export the model
    torch.onnx.export(
        model,
        dummy_input,
        output_path,
        input_names=['input'],
        output_names=['output'],
        dynamic_axes={
            'input': {0: 'batch_size'},
            'output': {0: 'batch_size'}
        }
    )

if __name__ == "__main__":
    # Create test models directory if it doesn't exist
    test_models_dir = Path("tests/test_models")
    test_models_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate test models
    generate_onnx_model(test_models_dir / "simple_model.onnx", (1, 10))
    generate_onnx_model(test_models_dir / "batch_model.onnx", (5, 10))
    
    print(f"Test models generated in {test_models_dir}")
