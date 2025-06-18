from pathlib import Path
from typing import Union, Optional, Dict, Any
import warnings

# Suppress TensorFlow deprecation warnings
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
warnings.filterwarnings('ignore', category=DeprecationWarning)
warnings.filterwarnings('ignore', category=FutureWarning)

def convert_model(
    model_type: str,
    model_path: Union[str, Path],
    output_path: Union[str, Path],
    opset: int = 13,
    **kwargs
) -> Path:
    """
    Convert a model to ONNX format.
    
    Args:
        model_type: Type of the model ('pytorch' or 'tensorflow')
        model_path: Path to the input model
        output_path: Path to save the ONNX model
        opset: ONNX opset version to use
        **kwargs: Additional arguments for the specific converter
        
    Returns:
        Path to the converted ONNX model
    """
    model_path = Path(model_path)
    output_path = Path(output_path)
    
    if model_type.lower() == 'pytorch':
        return _convert_pytorch(model_path, output_path, opset, **kwargs)
    elif model_type.lower() == 'tensorflow':
        return _convert_tensorflow(model_path, output_path, opset, **kwargs)
    else:
        raise ValueError(f"Unsupported model type: {model_type}")

def _convert_pytorch(
    model_path: Path,
    output_path: Path,
    opset: int,
    input_names: Optional[list] = None,
    output_names: Optional[list] = None,
    dynamic_axes: Optional[Dict[str, Dict[int, str]]] = None,
    **kwargs
) -> Path:
    """Convert a PyTorch model to ONNX format."""
    try:
        import torch
        from torch import nn
    except ImportError:
        raise ImportError("PyTorch is required for converting PyTorch models. Install with: pip install torch")
    
    # Default input/output names
    if input_names is None:
        input_names = ["input"]
    if output_names is None:
        output_names = ["output"]
    
    # Default dynamic axes
    if dynamic_axes is None:
        dynamic_axes = {
            input_names[0]: {0: 'batch_size'},
            output_names[0]: {0: 'batch_size'}
        }
    
    # Load the model
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    model = torch.load(model_path, map_location=device)
    model.eval()
    
    # Create dummy input
    dummy_input = torch.randn(1, 3, 224, 224, device=device)
    
    # Export the model
    torch.onnx.export(
        model,
        dummy_input,
        str(output_path),
        input_names=input_names,
        output_names=output_names,
        dynamic_axes=dynamic_axes,
        opset_version=opset,
        **kwargs
    )
    
    return output_path

def _convert_tensorflow(
    model_path: Path,
    output_path: Path,
    opset: int,
    **kwargs
) -> Path:
    """Convert a TensorFlow model to ONNX format."""
    try:
        import tensorflow as tf
        import tf2onnx
    except ImportError:
        raise ImportError(
            "TensorFlow and tf2onnx are required for converting TensorFlow models. "
            "Install with: pip install tensorflow tf2onnx"
        )
    
    # Load the model
    model = tf.keras.models.load_model(model_path)
    
    # Convert the model
    model_proto, _ = tf2onnx.convert.from_keras(
        model,
        input_signature=None,
        opset=opset,
        output_path=str(output_path),
        **kwargs
    )
    
    return output_path

# Add these functions to the module's namespace
__all__ = ['convert_model', '_convert_pytorch', '_convert_tensorflow']
