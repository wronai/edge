#!/bin/bash

# ONNX Runtime API Example with curl
# This script demonstrates how to interact with the ONNX Runtime server using curl

# Configuration
ONNX_SERVER="http://localhost:8001"
MODEL_NAME="your-model-name"  # Replace with your actual model name

# Function to print section headers
section() {
    echo -e "\n=== $1 ==="
}

# 1. Check server status
section "Checking server status"
curl -s "$ONNX_SERVER/v1/" | jq . || echo "Note: Install 'jq' for pretty-printed JSON output"

# 2. List available models (if supported)
section "Listing available models"
curl -s "$ONNX_SERVER/v1/" | jq '.models // "Model listing not supported by this server"' || \
    echo "Failed to list models. The server might not support this feature."

# 3. Get model metadata (if model exists)
section "Getting model metadata for $MODEL_NAME"
curl -s "$ONNX_SERVER/v1/models/$MODEL_NAME" 2>/dev/null | jq . || \
    echo "Model '$MODEL_NAME' not found or metadata not available"

# 4. Make a prediction (example with dummy data)
section "Making a prediction with $MODEL_NAME"

# Create a temporary file for the request payload
PREDICT_PAYLOAD=$(mktemp)
cat > "$PREDICT_PAYLOAD" << 'EOF'
{
  "instances": [
    {
      "input_1": [0.1, 0.2, 0.3, 0.4, 0.5]
    }
  ]
}
EOF

echo "Sending prediction request with data:"
cat "$PREDICT_PAYLOAD" | jq .

# Make the prediction request
PREDICTION_URL="$ONNX_SERVER/v1/models/$MODEL_NAME:predict"
response=$(curl -s -X POST "$PREDICTION_URL" \
    -H "Content-Type: application/json" \
    -d "@$PREDICT_PAYLOAD" \
    -w "\n%{http_code}" 2>/dev/null)

# Extract status code and response body
status_code=$(echo "$response" | tail -n1)
response_body=$(echo "$response" | sed '$d')

# Clean up the temporary file
rm -f "$PREDICT_PAYLOAD"

echo -e "\nResponse (Status: $status_code):"
echo "$response_body" | jq . 2>/dev/null || echo "$response_body"

# 5. Example of checking server health (if endpoint exists)
section "Checking server health"
curl -s -o /dev/null -w "Health check status: %{http_code}\n" "$ONNX_SERVER/v1/health" || \
    echo "Health check endpoint not available"

echo -e "\n=== Example Complete ==="
