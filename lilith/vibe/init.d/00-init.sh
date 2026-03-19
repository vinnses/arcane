#!/bin/bash
set -e

VIBE_USER="vibe"

# ── Create non-root user matching host UID ────────────────────────────────────
if ! id "$VIBE_USER" &>/dev/null; then
    echo ">>> [init] Creating user $VIBE_USER (${PUID:-1000}:${PGID:-1000})..."
    groupadd -g "${PGID:-1000}" "$VIBE_USER" 2>/dev/null || true
    useradd -m -u "${PUID:-1000}" -g "${PGID:-1000}" -s /bin/bash "$VIBE_USER"
fi

# ── Install base dependencies ─────────────────────────────────────────────────
echo ">>> [init] Installing system dependencies..."
apt-get update -qq && apt-get install -y -qq --no-install-recommends \
    python3 python3-pip python3-venv \
    git curl ca-certificates \
    openssh-server \
    > /dev/null 2>&1 && rm -rf /var/lib/apt/lists/*

# ── SSH for Antigravity ───────────────────────────────────────────────────────
mkdir -p /run/sshd
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

VIBE_SSH="/home/$VIBE_USER/.ssh"
if [ -d /opt/vibe/ssh ]; then
    mkdir -p "$VIBE_SSH"
    cp /opt/vibe/ssh/authorized_keys "$VIBE_SSH/authorized_keys" 2>/dev/null || true
    chown -R "$VIBE_USER:$VIBE_USER" "$VIBE_SSH"
    chmod 700 "$VIBE_SSH"
    chmod 600 "$VIBE_SSH/authorized_keys" 2>/dev/null || true
fi

/usr/sbin/sshd

# ── Fix ownership ─────────────────────────────────────────────────────────────
chown "$VIBE_USER:$VIBE_USER" /codes 2>/dev/null || true
