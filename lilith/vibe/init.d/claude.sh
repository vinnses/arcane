#!/bin/bash
# Claude Code CLI — https://docs.anthropic.com/en/docs/claude-code
set -e

if command -v claude &>/dev/null; then
    echo "  Claude Code already installed: $(claude --version 2>/dev/null || echo 'unknown')"
    return 0 2>/dev/null || exit 0
fi

echo "  Installing Claude Code CLI..."
npm install -g @anthropic-ai/claude-code > /dev/null 2>&1

echo "  Claude Code installed: $(claude --version 2>/dev/null || echo 'ok')"
echo "  Login with: claude login"
