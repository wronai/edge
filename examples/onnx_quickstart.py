"""
ONNX Runtime Quickstart Example

This script demonstrates how to use the ONNX Runtime server for model inference.
It includes examples for checking server status, listing models, and making predictions.
"""

import requests
import numpy as np
import json
from typing import Dict, Any, List, Optional

class ONNXClient:
    """Client for interacting with the ONNX Runtime server."""
    
    def __init__(self, base_url: str = "http://localhost:8001"):
        """Initialize the ONNX Runtime client.
        
        Args:
            base_url: Base URL of the ONNX Runtime server (default: http://localhost:8001)
        """
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
    
    def get_server_info(self) -> Dict[str, Any]:
        """Get server information and API version."""
        response = self.session.get(f"{self.base_url}/v1/", timeout=10)
        response.raise_for_status()
        return response.json()
    
    def list_models(self) -> List[str]:
        """List all available models on the server."""
        try:
            info = self.get_server_info()
            return info.get('models', [])
        except Exception as e:
            print(f"Warning: Could not list models - {e}")
            return []
    
    def get_model_metadata(self, model_name: str) -> Dict[str, Any]:
        """Get metadata for a specific model."""
        response = self.session.get(
            f"{self.base_url}/v1/models/{model_name}",
            timeout=10
        )
        response.raise_for_status()
        return response.json()
    
    def predict(
        self,
        model_name: str,
        inputs: Dict[str, List[float]],
        model_version: Optional[str] = None
    ) -> Dict[str, Any]:
        """Make a prediction using the specified model.
        
        Args:
            model_name: Name of the model to use for prediction
            inputs: Dictionary of input tensors (lists of numbers)
            model_version: Optional model version
            
        Returns:
            Dictionary containing the prediction results
        """
        url = f"{self.base_url}/v1/models/{model_name}"
        if model_version:
            url += f"/versions/{model_version}"
        url += ":predict"
        
        # Prepare the request payload
        payload = {
            "instances": [inputs]  # ONNX Runtime expects a list of instances
        }
        
        # Make the prediction request
        response = self.session.post(
            url,
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        response.raise_for_status()
        
        return response.json()

def main():
    """Run a complete example of using the ONNX Runtime client."""
    print("=== ONNX Runtime Quickstart Example ===\n")
    
    # Initialize the client
    client = ONNXClient("http://localhost:8001")
    
    try:
        # 1. Check server status
        print("1. Checking server status...")
        server_info = client.get_server_info()
        print(f"   Server version: {server_info.get('name', 'unknown')} {server_info.get('version', '')}")
        
        # 2. List available models
        print("\n2. Listing available models...")
        models = client.list_models()
        
        if not models:
            print("   No models found. Please load a model into the server.")
            print("   You can place ONNX model files in the 'models' directory and restart the container.")
            return
            
        print(f"   Available models: {', '.join(models) if models else 'None'}")
        
        # Use the first available model
        model_name = models[0] if models else None
        
        if not model_name:
            print("No models available for prediction.")
            return
            
        # 3. Get model metadata
        print(f"\n3. Getting metadata for model: {model_name}")
        try:
            model_meta = client.get_model_metadata(model_name)
            print(f"   Model metadata:")
            print(f"   - Platform: {model_meta.get('platform', 'unknown')}")
            print(f"   - Versions: {model_meta.get('versions', 'unknown')}")
        except Exception as e:
            print(f"   Could not get model metadata: {e}")
        
        # 4. Make a prediction (example with dummy data)
        print(f"\n4. Making a prediction with model: {model_name}")
        
        # Note: Replace this with actual input data matching your model's expected input
        # This is just an example with dummy data
        example_input = {
            # Example input for a simple model that expects a single input tensor
            # Adjust based on your model's expected input format
            "input_1": [0.1, 0.2, 0.3, 0.4, 0.5]
        }
        
        try:
            print(f"   Sending input: {example_input}")
            prediction = client.predict(model_name, example_input)
            
            print("\n=== Prediction Result ===")
            print(json.dumps(prediction, indent=2))
            
        except requests.exceptions.HTTPError as e:
            print(f"\nError making prediction: {e}")
            if e.response is not None:
                print(f"Response: {e.response.text}")
        
    except requests.exceptions.RequestException as e:
        print(f"Error connecting to ONNX Runtime server: {e}")
        print("Make sure the ONNX Runtime server is running and accessible.")
        print(f"Tried to connect to: {client.base_url}")

if __name__ == "__main__":
    main()
