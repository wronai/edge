# Development Guide

Welcome to the Edge AI platform development guide! This document will help you set up your development environment and understand the codebase structure.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Code Style](#code-style)
- [Testing](#testing)
- [Debugging](#debugging)
- [Contributing](#contributing)
- [Release Process](#release-process)

## Prerequisites

- Docker and Docker Compose
- Python 3.8+
- Git
- Make (optional, but recommended)

## Development Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/your-username/edge.git
   cd edge
   ```

2. **Set up Python virtual environment**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: .\venv\Scripts\activate
   pip install -r requirements-dev.txt
   ```

3. **Start development services**
   ```bash
   # Start all services in development mode
   docker-compose -f docker-compose.dev.yml up -d
   ```

4. **Verify the setup**
   ```bash
   # Run tests
   make test
   
   # Check code style
   make lint
   ```

## Project Structure

```
.
├── docker/                  # Docker-related files
│   ├── nginx/              # Nginx configuration
│   └── ollama/             # Custom Ollama Dockerfile
├── docs/                   # Documentation
├── models/                 # ONNX models directory
├── scripts/                # Utility scripts
├── src/                    # Source code
│   ├── api/                # API endpoints
│   ├── services/           # Business logic
│   └── utils/              # Utility functions
├── tests/                  # Test files
├── .env                    # Environment variables
├── .gitignore
├── docker-compose.yml      # Production compose file
├── docker-compose.dev.yml  # Development compose file
├── Makefile               # Common tasks
└── README.md
```

## Code Style

We follow the following code style guidelines:

- **Python**: PEP 8
- **YAML**: 2-space indentation
- **Shell scripts**: ShellCheck compliant

Run the linters:
```bash
make lint
```

## Testing

### Running Tests

```bash
# Run all tests
make test

# Run unit tests only
pytest tests/unit

# Run integration tests
pytest tests/integration

# Run a specific test file
pytest tests/unit/test_utils.py
```

### Writing Tests

- Place unit tests in `tests/unit/`
- Place integration tests in `tests/integration/`
- Use descriptive test function names
- Follow the "Arrange-Act-Assert" pattern
- Mock external dependencies

## Debugging

### Debugging Services

1. **View logs**
   ```bash
   # Follow logs for all services
   docker-compose logs -f
   
   # View logs for a specific service
   docker-compose logs -f [service_name]
   ```

2. **Access a shell in a running container**
   ```bash
   docker-compose exec [service_name] sh
   ```

3. **Debug Python code**
   Add `breakpoint()` in your code and run:
   ```bash
   python -m debugpy --listen 0.0.0.0:5678 --wait-for-client -m pytest tests/
   ```
   Then attach your IDE's debugger to port 5678.

## Contributing

1. Create a new branch for your feature or bugfix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commit them:
   ```bash
   git add .
   git commit -m "feat: add your feature"
   ```

3. Push your changes and create a pull request:
   ```bash
   git push origin feature/your-feature-name
   ```

### Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Example:
```
feat(api): add user authentication endpoint

- Add POST /auth/login endpoint
- Add JWT token generation
- Update documentation

Closes #123
```

## Release Process

1. Update version in `VERSION` file
2. Update `CHANGELOG.md` with release notes
3. Create a release tag:
   ```bash
   git tag v$(cat VERSION)
   git push origin v$(cat VERSION)
   ```
4. Create a new GitHub release with the same tag
5. Update documentation if needed

## Need Help?

- Check the [documentation](docs/)
- Open an [issue](https://github.com/wronai/edge/issues)
- Join our [community chat](https://your-community-chat.example.com)
