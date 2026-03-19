#!/bin/bash
set -e

VIBE_USER="vibe"
VIBE_HOME="/vibe/home"
VIBE_CODE="/vibe/code"

# ── Create non-root user matching host UID ────────────────────────────────────
if ! id "$VIBE_USER" &>/dev/null; then
    echo ">>> [vibe] Creating user $VIBE_USER (${PUID:-1000}:${PGID:-1000})..."
    groupadd -g "${PGID:-1000}" "$VIBE_USER" 2>/dev/null || true
    useradd -m -d "$VIBE_HOME" -u "${PUID:-1000}" -g "${PGID:-1000}" -s /bin/bash "$VIBE_USER"
fi

# ── Install base dependencies ─────────────────────────────────────────────────
echo ">>> [vibe] Installing system dependencies..."
apt-get update -qq && apt-get install -y -qq --no-install-recommends \
    python3 python3-pip python3-venv \
    git curl ca-certificates \
    > /dev/null 2>&1 && rm -rf /var/lib/apt/lists/*

# ── Fix ownership ─────────────────────────────────────────────────────────────
chown "$VIBE_USER:$VIBE_USER" "$VIBE_HOME" "$VIBE_CODE" 2>/dev/null || true

# ── Run tool init scripts ─────────────────────────────────────────────────────
for script in /opt/vibe/init.d/*.sh; do
    [ -f "$script" ] || continue
    echo ">>> [vibe] Running $(basename "$script")..."
    bash "$script"
done

echo ">>> [vibe] Ready."
echo ">>>   Enter:  docker exec -it vibe su - vibe"
echo ">>>   Or use an alias: alias vibe='docker exec -it vibe su - vibe'"

# ── Keep container alive ──────────────────────────────────────────────────────
exec sleep infinity
