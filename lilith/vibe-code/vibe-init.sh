#!/bin/bash
set -e

# ── Install dependencies (idempotent) ────────────────────────────────────────
if ! command -v ttyd &>/dev/null; then
    echo ">>> [vibe-init] Installing system dependencies..."
    apt-get update && apt-get install -y --no-install-recommends \
        ttyd python3 python3-pip python3-venv \
        git curl ca-certificates \
        && rm -rf /var/lib/apt/lists/*
fi

if ! command -v claude &>/dev/null; then
    echo ">>> [vibe-init] Installing Claude Code CLI..."
    npm install -g @anthropic-ai/claude-code
fi

# ── Create non-root user matching host UID ────────────────────────────────────
if ! id claude &>/dev/null; then
    groupadd -g "${PGID:-1000}" claude 2>/dev/null || true
    useradd -m -u "${PUID:-1000}" -g "${PGID:-1000}" -s /bin/bash claude 2>/dev/null || true
fi

chown claude:claude /projects /projects/ClaudeData 2>/dev/null || true
chown -R claude:claude /home/claude/.sessions 2>/dev/null || true

# ── Auth (basic auth via ttyd -c user:pass) ───────────────────────────────────
AUTH_ARGS=""
if [ -n "$VIBE_USER" ] && [ -n "$VIBE_PASSWORD" ]; then
    AUTH_ARGS="-c ${VIBE_USER}:${VIBE_PASSWORD}"
    echo ">>> [vibe-init] Basic auth enabled for user '${VIBE_USER}'."
else
    echo ">>> [vibe-init] WARNING: No auth configured (set VIBE_USER + VIBE_PASSWORD)."
fi

PORT="${VIBE_PORT:-7681}"
echo ">>> [vibe-init] Starting ttyd on port ${PORT}..."

exec ttyd \
    ${AUTH_ARGS} \
    -p "${PORT}" \
    -W \
    su - claude -c "cd /projects/ClaudeData && claude --dangerously-skip-permissions"
