#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
MODEL_NAME=${MODEL_NAME:-complex-cnn-model}
MODEL_VERSION=${MODEL_VERSION:-1}

list_models() {
    echo -e "${YELLOW}Available ONNX models:${NC}"
    if [ -d "models" ]; then
        find models -name "*.onnx" | sed 's/^/  /'
    else
        echo -e "  ${YELLOW}No models directory found${NC}"
    fi
}

load_model() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: MODEL and MODEL_SOURCE must be specified${NC}"
        echo "Usage: $0 load MODEL_NAME /path/to/model.onnx"
        return 1
    fi
    
    local model_name=$1
    local model_source=$2
    local target_file="models/$(basename "$model_name").onnx"
    
    echo -e "${YELLOW}Loading model $model_name from $model_source...${NC}"
    
    # Check if source file exists
    if [ ! -f "$model_source" ]; then
        echo -e "${RED}✗ Source file '$model_source' not found${NC}"
        return 1
    fi
    
    # Create models directory if it doesn't exist
    mkdir -p models || {
        echo -e "${RED}✗ Failed to create models directory${NC}"
        return 1
    }
    
    # Check if source and destination are the same file
    if [ "$(realpath "$model_source" 2>/dev/null || echo "$model_source")" = "$(realpath "$target_file" 2>/dev/null || echo "$target_file")" ]; then
        echo -e "${YELLOW}✓ Model is already in the correct location: $target_file${NC}"
        return 0
    fi
    
    # Copy the file
    if ! cp "$model_source" "$target_file"; then
        echo -e "${RED}✗ Failed to copy model to $target_file${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Model $model_name loaded to $target_file${NC}"
    return 0
}

test_model() {
    echo -e "${YELLOW}Testing ONNX Runtime inference...${NC}"
    
    if [ ! -d "models" ] || [ -z "$(ls -A models/)" ]; then
        echo -e "${YELLOW}No models found. Try loading a model first.${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Available models:${NC}"
    find models -name "*.onnx" | sed 's/^/  /'
    
    echo -e "\n${YELLOW}Example test commands:${NC}"
    echo "1. Basic test with curl (V1 API):"
    echo '  curl -X POST http://localhost:8001/v1/$(MODEL_NAME)/versions/$(MODEL_VERSION):predict \'
    echo '    -H "Content-Type: application/json" \'
    echo '    -d '\''{"instances": [{"data": [1.0, 2.0, 3.0, 4.0]}]}'
    
    echo -e "\n2. Test with Python (requires requests):"
    echo '  ```python'
    echo '  import requests'
    echo '  import json'
    echo '  '
    echo '  # V1 API (recommended)'
    echo '  response = requests.post('
    echo '      "http://localhost:8001/v1/$(MODEL_NAME)/versions/$(MODEL_VERSION):predict",'
    echo '      json={"instances": [{"data": [1.0, 2.0, 3.0, 4.0]}]}'
    echo '  )'
    echo '  print(json.dumps(response.json(), indent=2))'
    echo '  ```'
    
    echo -e "\n3. Check model status:"
    echo '  curl http://localhost:8001/v1/$(MODEL_NAME)/versions/$(MODEL_VERSION)'
    
    echo -e "\n4. Get model metadata:"
    echo '  curl http://localhost:8001/v1/$(MODEL_NAME)/versions/$(MODEL_VERSION)/metadata'
}

# Main command handler
case "$1" in
    list)
        list_models
        ;;
    load)
        load_model "$2" "$3"
        ;;
    test)
        test_model
        ;;
    *)
        echo "Usage: $0 {list|load|test}"
        echo "  list                  - List available models"
        echo "  load MODEL_NAME PATH  - Load a model"
        echo "  test                 - Show test commands"
        exit 1
        ;;
esac
