"""
Example script demonstrating TensorFlow model conversion to ONNX.

This script shows how to convert different types of TensorFlow models to ONNX format
using the wronai_edge package.
"""

import os
import numpy as np
import tensorflow as tf
from pathlib import Path

# Import the wronai_edge package
from wronai_edge.models import (
    convert_keras_model,
    convert_saved_model,
    convert_tf_function,
    get_model_signature
)

def create_sample_keras_model():
    """Create a simple Keras model for demonstration."""
    model = tf.keras.Sequential([
        tf.keras.layers.Dense(64, activation='relu', input_shape=(10,)),
        tf.keras.layers.Dense(32, activation='relu'),
        tf.keras.layers.Dense(1, activation='sigmoid')
    ])
    model.compile(optimizer='adam', loss='binary_crossentropy')
    return model

def save_keras_model(model, path):
    """Save a Keras model to the specified path."""
    model.save(path)
    print(f"Saved Keras model to {path}")

def convert_keras_model_example():
    """Example of converting a Keras model to ONNX."""
    print("\n=== Converting Keras Model to ONNX ===")
    
    # Create and save a sample Keras model
    model = create_sample_keras_model()
    keras_model_path = "models/sample_keras_model"
    save_keras_model(model, keras_model_path)
    
    # Convert to ONNX
    onnx_path = "models/keras_model.onnx"
    convert_keras_model(
        model_path=keras_model_path,
        output_path=onnx_path,
        opset=13
    )
    
    print(f"Successfully converted Keras model to ONNX: {onnx_path}")

def convert_saved_model_example():
    """Example of converting a SavedModel to ONNX."""
    print("\n=== Converting SavedModel to ONNX ===")
    
    # Create and save a sample Keras model as SavedModel
    model = create_sample_keras_model()
    saved_model_path = "models/saved_model"
    tf.saved_model.save(model, saved_model_path)
    
    # Get the model signature
    signature = get_model_signature(saved_model_path)
    print(f"Model signature: {signature}")
    
    # Convert to ONNX
    onnx_path = "models/saved_model.onnx"
    convert_saved_model(
        saved_model_dir=saved_model_path,
        output_path=onnx_path,
        opset=13
    )
    
    print(f"Successfully converted SavedModel to ONNX: {onnx_path}")

def convert_tf_function_example():
    """Example of converting a TensorFlow function to ONNX."""
    print("\n=== Converting TensorFlow Function to ONNX ===")
    
    # Define a simple TensorFlow function
    @tf.function
    def my_model(x):
        w = tf.constant([[1.0, 2.0], [3.0, 4.0]])
        b = tf.constant([1.0, 2.0])
        return tf.nn.relu(tf.matmul(x, w) + b)
    
    # Define input signature
    input_signature = [tf.TensorSpec(shape=(None, 2), dtype=tf.float32, name='input')]
    
    # Convert to ONNX
    onnx_path = "models/tf_function.onnx"
    convert_tf_function(
        func=my_model,
        output_path=onnx_path,
        input_signature=input_signature,
        opset=13
    )
    
    print(f"Successfully converted TensorFlow function to ONNX: {onnx_path}")

def main():
    """Run all conversion examples."""
    # Create models directory if it doesn't exist
    os.makedirs("models", exist_ok=True)
    
    # Run conversion examples
    try:
        convert_keras_model_example()
        convert_saved_model_example()
        convert_tf_function_example()
        print("\nAll conversions completed successfully!")
    except ImportError as e:
        print(f"\nError: {e}")
        print("Please install the required dependencies with:")
        print("pip install tensorflow tf2onnx")

if __name__ == "__main__":
    main()
