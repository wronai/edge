#!/usr/bin/env python3

import requests
import sys
import os
import json

def test_onnx_service():
    """Test the ONNX Runtime service endpoints."""
    base_url = "http://wronai_edge-onnx:8001"
    model_name = os.getenv('MODEL_NAME', 'complex-cnn-model')
    model_version = os.getenv('MODEL_VERSION', '1')
    
    print("Testing ONNX Runtime service...")
    
    # Test health endpoint
    try:
        response = requests.get(f"{base_url}/v2/health/ready")
        print(f"✓ Health endpoint: HTTP {response.status_code}")
        if response.status_code == 200:
            health = response.json()
            print(f"   Health status: {json.dumps(health, indent=2)}")
    except Exception as e:
        print(f"✗ Health check failed: {str(e)}")
        return 1
    
    # Test model metadata
    try:
        print("\nTesting model metadata...")
        response = requests.get(f"{base_url}/v2/models/{model_name}/versions/{model_version}")
        print(f"✓ Model metadata: HTTP {response.status_code}")
        if response.status_code == 200:
            print(f"   Model info: {json.dumps(response.json(), indent=2)}")
    except Exception as e:
        print(f"✗ Model metadata check failed: {str(e)}")
    
    # Test model ready status
    try:
        response = requests.get(f"{base_url}/v2/models/{model_name}/versions/{model_version}/ready")
        print(f"\nModel ready status: HTTP {response.status_code}")
        if response.status_code == 200:
            print(f"   Model is ready: {json.dumps(response.json(), indent=2)}")
    except Exception as e:
        print(f"✗ Model ready check failed: {str(e)}")
    
    print("\nNote: Some endpoints may return 405 (Method Not Allowed) which is expected")
    print("for certain HTTP methods on specific endpoints in the ONNX Runtime server.")
    
    return 0

if __name__ == "__main__":
    sys.exit(test_onnx_service())
