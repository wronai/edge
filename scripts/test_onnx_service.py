#!/usr/bin/env python3

import requests
import sys
import os

def test_onnx_service():
    """Test the ONNX Runtime service endpoints."""
    base_url = "http://localhost:8001"
    model_name = os.getenv('MODEL_NAME', 'complex-cnn-model')
    model_version = os.getenv('MODEL_VERSION', '1')
    
    print("Testing ONNX Runtime service...")
    
    # Test basic endpoint
    try:
        response = requests.get(f"{base_url}/v1/")
        print(f"✓ Basic endpoint: HTTP {response.status_code}")
    except Exception as e:
        print(f"✗ Basic endpoint failed: {str(e)}")
        return 1
    
    # Test model status
    try:
        response = requests.get(f"{base_url}/v1/{model_name}/versions/{model_version}")
        print(f"✓ Model status: HTTP {response.status_code}")
        if response.status_code == 200:
            print(f"   Model state: {response.json().get('state', 'unknown')}")
    except Exception as e:
        print(f"✗ Model status check failed: {str(e)}")
    
    # Test prediction
    try:
        response = requests.post(
            f"{base_url}/v1/{model_name}/versions/{model_version}:predict",
            json={"instances": [{"data": [1.0, 2.0, 3.0, 4.0]}]}
        )
        print(f"✓ Prediction: HTTP {response.status_code}")
    except Exception as e:
        print(f"✗ Prediction failed: {str(e)}")
    
    return 0

if __name__ == "__main__":
    sys.exit(test_onnx_service())
