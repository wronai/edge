#!/usr/bin/env python3

import time
import requests
import statistics
import json
import os
import sys

def run_benchmark():
    model_name = os.getenv('MODEL_NAME', 'complex-cnn-model')
    model_version = os.getenv('MODEL_VERSION', '1')
    
    times = []
    success = 0
    
    try:
        # First check if model is ready
        status_url = f'http://localhost:8001/v1/{model_name}/versions/{model_version}'
        try:
            status_response = requests.get(status_url, timeout=5)
            if status_response.status_code != 200:
                print(f'Error: Model is not ready (HTTP {status_response.status_code}): {status_response.text}')
                sys.exit(1)
        except requests.RequestException as e:
            print(f'Error checking model status: {str(e)}')
            sys.exit(1)
                
        # Run benchmark
        print(f'Running benchmark with model {model_name}, version {model_version}...')
        predict_url = f'http://localhost:8001/v1/{model_name}/versions/{model_version}:predict'
        
        for i in range(100):
            try:
                start = time.time()
                response = requests.post(
                    predict_url,
                    json={"instances": [{"data": [1.0, 2.0, 3.0, 4.0]}]},
                    timeout=5
                )
                if response.status_code == 200:
                    times.append((time.time() - start) * 1000)  # Convert to ms
                    success += 1
                else:
                    print(f'Request failed ({response.status_code}):', response.text)
            except Exception as e:
                print(f'Request error: {str(e)}')
                continue
        
        # Print results
        if times:
            print(f'\nSuccess rate: {success}/100 ({success}%)')
            print(f'Average latency: {statistics.mean(times):.2f}ms')
            print(f'Min latency: {min(times):.2f}ms')
            print(f'Max latency: {max(times):.2f}ms')
            print(f'P50 latency: {statistics.median(times):.2f}ms')
            print(f'P95 latency: {sorted(times)[int(len(times)*0.95)]:.2f}ms')
            return 0
        else:
            print('Error: No successful requests to measure')
            return 1
            
    except Exception as e:
        print(f'Error during benchmark: {str(e)}')
        return 1

if __name__ == "__main__":
    sys.exit(run_benchmark())
