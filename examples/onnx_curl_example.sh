#!/bin/bash

# ONNX Runtime API Example with curl
# This script demonstrates how to interact with the ONNX Runtime server using curl

# Configuration
ONNX_SERVER="http://localhost:8001"
MODEL_NAME="your-model-name"  # Replace with your actual model name

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Warning: 'jq' is not installed. JSON responses won't be pretty-printed.
      Install with: sudo apt-get install jq
"
    JQ_CMD="cat"
else
    JQ_CMD="jq ."
fi

# Function to print section headers
section() {
    echo -e "\n=== $1 ==="
}

# 1. Check server status
section "Checking server status"
curl -s "$ONNX_SERVER/v1/" | $JQ_CMD || echo "Server returned an error. This is expected for GET on /v1/"

# 2. List available models (not supported by ONNX Runtime server)
section "Listing available models"
echo "Note: ONNX Runtime server doesn't support listing models via API."
echo "      Models should be placed in the 'models' directory before starting the server."

# 3. Check if model is loaded
section "Checking if model is loaded"
# ONNX Runtime doesn't have a direct endpoint to check loaded models
# We'll try to make a prediction and check the response
echo "Attempting to detect loaded models by checking prediction endpoint..."

# 4. Make a prediction (example with dummy data)
section "Making a prediction with $MODEL_NAME"

# Create a temporary file for the request payload
PREDICT_PAYLOAD=$(mktemp)
cat > "$PREDICT_PAYLOAD" << 'EOF'
{
  "inputs": {
    "input_1": {
      "name": "input_1",
      "shape": [1, 5],
      "datatype": "FP32",
      "data": [0.1, 0.2, 0.3, 0.4, 0.5]
    }
  },
  "outputs": [
    {"name": "output_1"}
  ]
}
EOF

echo "Sending prediction request with data:"
cat "$PREDICT_PAYLOAD" | $JQ_CMD

# Make the prediction request
PREDICTION_URL="$ONNX_SERVER/v1/models/$MODEL_NAME/versions/1/infer"
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
echo "$response_body" | $JQ_CMD 2>/dev/null || echo "$response_body"

# 5. Show how to check server health
section "Server Health Check"
echo "ONNX Runtime server doesn't have a standard health check endpoint."
echo "You can check if the server is running by making a request to the root endpoint:"
echo "  curl -i $ONNX_SERVER/v1/"

# 6. Show how to check server version
section "Server Version"
echo "To check the server version, look at the HTTP headers in the response:"
curl -I "$ONNX_SERVER/v1/" | grep -i "server\|version" || echo "Could not determine server version"

# 5. Example of checking server health (if endpoint exists)
section "Checking server health"
curl -s -o /dev/null -w "Health check status: %{http_code}\n" "$ONNX_SERVER/v1/health" || \
    echo "Health check endpoint not available"

echo -e "\n=== Example Complete ==="
