# Edge AI Model Tools

A Python package for testing and building machine learning models for edge deployment.

## Features

- Model validation and testing
- PyTorch to ONNX conversion
- Model performance testing
- Rich CLI interface

## Installation

1. Install Poetry if you haven't already:
   ```bash
   curl -sSL https://install.python-poetry.org | python3 -
   ```

2. Clone this repository and install dependencies:
   ```bash
   cd edge_ai
   poetry install
   ```

3. Install the package in development mode:
   ```bash
   poetry install
   ```

## Usage

### Testing a Model

```bash
# Test an ONNX model
poetry run edge-ai test-model --model-path path/to/your/model.onnx
```

### Converting a PyTorch Model to ONNX

```bash
# Convert a PyTorch model to ONNX
poetry run edge-ai convert-model \
    --model-path path/to/your/model.pt \
    --output-path path/to/output/model.onnx \
    --input-shape 3,224,224
```

## Development

### Running Tests

```bash
poetry run pytest
```

### Building the Package

```bash
poetry build
```

## License

MIT
