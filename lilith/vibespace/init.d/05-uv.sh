#!/bin/bash
# uv — fast Python package manager
set -e

if command -v uv &>/dev/null; then
    echo "  uv already installed: $(uv --version 2>/dev/null)"
    exit 0
fi

echo "  Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh > /dev/null 2>&1

echo "  uv installed: $(uv --version 2>/dev/null || echo 'ok')"
