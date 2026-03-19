#!/bin/bash
set -e

USER_NAME="${VIBE_USER:-vibecoder}"

# ── Create non-root user matching host UID ────────────────────────────────────
if ! id "$USER_NAME" &>/dev/null; then
    echo ">>> [init] Creating user $USER_NAME (${PUID:-1000}:${PGID:-1000})..."
    groupadd -g "${PGID:-1000}" "$USER_NAME" 2>/dev/null || true
    useradd -m -u "${PUID:-1000}" -g "${PGID:-1000}" -s /bin/bash "$USER_NAME"
fi

USER_HOME=$(eval echo "~$USER_NAME")

# ── Install base dependencies ─────────────────────────────────────────────────
echo ">>> [init] Installing system dependencies..."
apt-get update -qq && apt-get install -y -qq --no-install-recommends \
    python3 python3-pip python3-venv \
    git curl ca-certificates \
    tmux jq make build-essential \
    > /dev/null 2>&1 && rm -rf /var/lib/apt/lists/*

# ── Apply user configs from /opt/vibe/user ────────────────────────────────────
if [ -d /opt/vibe/user ]; then
    for f in /opt/vibe/user/*; do
        [ -f "$f" ] || continue
        target="$USER_HOME/.$(basename "$f")"
        # Only copy if target doesn't exist (preserve user changes in volume)
        [ -f "$target" ] || cp "$f" "$target"
    done
    chown -R "$USER_NAME:$USER_NAME" "$USER_HOME"
fi

# ── Fix ownership ─────────────────────────────────────────────────────────────
chown "$USER_NAME:$USER_NAME" /codes 2>/dev/null || true
