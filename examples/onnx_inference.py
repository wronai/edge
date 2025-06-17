#!/usr/bin/env python3
"""
ONNX Runtime Inference Example

This script demonstrates how to use the ONNX Runtime API for model inference.
It assumes you have a running ONNX Runtime server.
"""

import requests
import numpy as np
from typing import Dict, Any, List
import json

class ONNXClient:
    """Client for interacting with the ONNX Runtime server."""
    
    def __init__(self, base_url: str = "http://localhost:8001"):
        """Initialize the ONNX Runtime client.
        
        Args:
            base_url: Base URL of the ONNX Runtime server
        """
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
    
    def get_server_metadata(self) -> Dict[str, Any]:
        """Get server metadata."""
        response = self.session.get(f"{self.base_url}/v1/", timeout=10)
        response.raise_for_status()
        return response.json()
    
    def get_model_metadata(self, model_name: str) -> Dict[str, Any]:
        """Get metadata for a specific model."""
        response = self.session.get(f"{self.base_url}/v1/models/{model_name}", timeout=10)
        response.raise_for_status()
        return response.json()
    
    def predict(
        self, 
        model_name: str, 
        inputs: Dict[str, List[float]],
        model_version: str = None
    ) -> Dict[str, List[float]]:
        """Make a prediction using the specified model.
        
        Args:
            model_name: Name of the model to use for prediction
            inputs: Dictionary of input tensors
            model_version: Optional model version
            
        Returns:
            Dictionary of output tensors
        """
        url = f"{self.base_url}/v1/models/{model_name}"
        if model_version:
            url += f"/versions/{model_version}"
        url += ":predict"
        
        # Convert inputs to the expected format
        payload = {"instances": [inputs]}
        
        response = self.session.post(
            url,
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        response.raise_for_status()
        
        # Extract predictions from response
        result = response.json()
        return result.get("predictions", [{}])[0]  # Return first prediction

def main():
    """Run a simple example of using the ONNX Runtime client."""
    # Initialize client
    client = ONNXClient("http://localhost:8001")
    
    try:
        # Get server metadata
        print("\n=== Server Metadata ===")
        metadata = client.get_server_metadata()
        print(json.dumps(metadata, indent=2))
        
        # List available models (if supported)
        try:
            models = metadata.get("models", [])
            if models:
                print("\n=== Available Models ===")
                for model in models:
                    print(f"- {model}")
        except Exception as e:
            print(f"\nNote: Could not list models: {e}")
        
        print("\n=== Example Inference ===")
        print("Note: Replace 'your-model-name' with an actual model name")
        print("and provide appropriate input data for your model.\n")
        
        # Example: Make a prediction (with placeholder data)
        # Replace with actual model name and input data
        model_name = "your-model-name"
        
        # Example input (adjust based on your model's expected input)
        example_input = {
            "input_1": [0.1, 0.2, 0.3, 0.4],  # Replace with actual input tensor
            # Add more inputs if your model expects them
        }
        
        try:
            print(f"Making prediction with model: {model_name}")
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

if __name__ == "__main__":
    main()
