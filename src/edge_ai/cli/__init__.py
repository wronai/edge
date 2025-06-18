"""Edge AI command line interface."""

import click
from .main import cli
from .benchmark import benchmark

# Register commands
cli.add_command(benchmark)

__all__ = ['cli']
