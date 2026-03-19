#!/bin/bash
set -e

# ── Install dependencies (idempotent) ────────────────────────────────────────
if ! command -v claude &>/dev/null; then
    echo ">>> [vibe-init] Installing system dependencies..."
    apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv \
        git curl ca-certificates \
        && rm -rf /var/lib/apt/lists/*

    echo ">>> [vibe-init] Installing Claude Code CLI..."
    npm install -g @anthropic-ai/claude-code
fi

# ── Create non-root user matching host UID ────────────────────────────────────
if ! id claude &>/dev/null; then
    groupadd -g "${PGID:-1000}" claude 2>/dev/null || true
    useradd -m -u "${PUID:-1000}" -g "${PGID:-1000}" -s /bin/bash claude 2>/dev/null || true
fi

chown claude:claude /projects/ClaudeData 2>/dev/null || true
chown -R claude:claude /home/claude/.sessions 2>/dev/null || true

echo ">>> [vibe-init] Ready. Use: docker exec -it vibe-code su - claude"
exec su - claude -c "cd /projects/ClaudeData && claude --dangerously-skip-permissions"
