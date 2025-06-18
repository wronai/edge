"""Edge AI model testing and building tools."""

__version__ = "0.1.0"

# Import key components for easier access
from .models.validator import validate_model, validate_model_cli
from .models.converter import convert_to_onnx

__all__ = [
    'validate_model',
    'validate_model_cli',
    'convert_to_onnx',
]
