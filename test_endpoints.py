import requests
import json
import sys

def test_ollama_endpoint():
    """Test the Ollama API endpoint."""
    try:
        url = "http://localhost:11435/api/tags"
        response = requests.get(url, timeout=10)
        print(f"Ollama API Status: {response.status_code}")
        print(f"Response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"Error testing Ollama endpoint: {e}")
        return False

def test_onnx_endpoint():
    """Test the ONNX Runtime endpoint."""
    try:
        url = "http://localhost:8001/v1/"
        response = requests.get(url, timeout=10)
        print(f"ONNX Runtime Status: {response.status_code}")
        print(f"Response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"Error testing ONNX Runtime endpoint: {e}")
        return False

def test_nginx_gateway():
    """Test the Nginx gateway."""
    try:
        # Test Ollama through Nginx
        url = "http://localhost:30080/api/tags"
        response = requests.get(url, timeout=10)
        print(f"Nginx -> Ollama Status: {response.status_code}")
        
        # Test ONNX Runtime through Nginx
        url = "http://localhost:30080/v1/"
        response = requests.get(url, timeout=10)
        print(f"Nginx -> ONNX Runtime Status: {response.status_code}")
        
        return True
    except Exception as e:
        print(f"Error testing Nginx gateway: {e}")
        return False

def test_services():
    """Run all service tests."""
    print("=== Running Service Tests ===")
    
    # Test direct endpoints
    print("\nTesting direct endpoints:")
    ollama_ok = test_ollama_endpoint()
    onnx_ok = test_onnx_endpoint()
    
    # Test through Nginx
    print("\nTesting through Nginx gateway:")
    nginx_ok = test_nginx_gateway()
    
    # Print summary
    print("\n=== Test Summary ===")
    print(f"Ollama API: {'PASS' if ollama_ok else 'FAIL'}")
    print(f"ONNX Runtime: {'PASS' if onnx_ok else 'FAIL'}")
    print(f"Nginx Gateway: {'PASS' if nginx_ok else 'FAIL'}")
    
    return all([ollama_ok, onnx_ok, nginx_ok])

if __name__ == "__main__":
    success = test_services()
    sys.exit(0 if success else 1)
