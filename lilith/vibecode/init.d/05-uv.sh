#!/bin/bash
# uv — fast Python package manager
set -e

if command -v uv &>/dev/null; then
    echo "  uv already installed: $(uv --version 2>/dev/null)"
    exit 0
fi

echo "  Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh > /dev/null 2>&1

# Make uv available system-wide
ln -sf /root/.local/bin/uv /usr/local/bin/uv 2>/dev/null || true
ln -sf /root/.local/bin/uvx /usr/local/bin/uvx 2>/dev/null || true

echo "  uv installed: $(uv --version 2>/dev/null || echo 'ok')"
