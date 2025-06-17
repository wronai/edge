import onnxruntime as ort
import numpy as np
import os

def test_onnx_model(model_path):
    try:
        print(f"\nTesting model: {model_path}")
        print(f"File size: {os.path.getsize(model_path) / 1024:.2f} KB")
        
        # Try to create an inference session with the model
        session = ort.InferenceSession(model_path)
        print("Model loaded successfully!")
        
        # Print input and output details
        print("\nInputs:")
        for i, input in enumerate(session.get_inputs()):
            print(f"  Input {i}: {input.name}, shape: {input.shape}, type: {input.type}")
        
        print("\nOutputs:")
        for i, output in enumerate(session.get_outputs()):
            print(f"  Output {i}: {output.name}, shape: {output.shape}, type: {output.type}")
            
        return True
    except Exception as e:
        print(f"Error loading model: {str(e)}")
        return False

if __name__ == "__main__":
    # Test all .onnx files in the models directory
    model_dir = "models"
    for filename in os.listdir(model_dir):
        if filename.endswith(".onnx"):
            model_path = os.path.join(model_dir, filename)
            test_onnx_model(model_path)
