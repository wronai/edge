"""Edge AI command line interface."""

import click
from wronai_edge.cli.main import cli
from wronai_edge.cli.benchmark import benchmark

# Register commands
cli.add_command(benchmark)

__all__ = ['cli']
