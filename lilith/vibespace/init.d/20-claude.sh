#!/bin/bash
# Claude Code CLI — https://docs.anthropic.com/en/docs/claude-code
set -e

USER_NAME="${VIBE_USER:-vibecoder}"
USER_HOME=$(eval echo "~$USER_NAME")
AGENTS_DIR="$USER_HOME/.agents"

if command -v claude &>/dev/null; then
    echo "  Claude Code already installed: $(claude --version 2>/dev/null || echo 'unknown')"
    exit 0
fi

echo "  Installing Claude Code CLI..."
npm install -g @anthropic-ai/claude-code > /dev/null 2>&1

# ── Point Claude config to shared agents dir ──────────────────────────────────
mkdir -p "$AGENTS_DIR/claude"
cat >> "$USER_HOME/.bashrc.d/99-agents.sh" 2>/dev/null <<EOF
export CLAUDE_CONFIG_DIR="\$HOME/.agents/claude"
EOF

echo "  Claude Code installed: $(claude --version 2>/dev/null || echo 'ok')"
echo "  Login with: claude login"
