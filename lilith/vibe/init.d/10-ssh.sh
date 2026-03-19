#!/bin/bash
# SSH server — container-own keys, key-only auth
set -e

apt-get update -qq && apt-get install -y -qq --no-install-recommends \
    openssh-server > /dev/null 2>&1 && rm -rf /var/lib/apt/lists/*

USER_NAME="${VIBE_USER:-vibecoder}"
USER_HOME=$(eval echo "~$USER_NAME")
SSH_DIR="$USER_HOME/.ssh"

mkdir -p /run/sshd "$SSH_DIR"

# ── Generate container-specific host keys (persist in .data/ssh) ──────────────
if [ ! -f "$SSH_DIR/host_ed25519_key" ]; then
    ssh-keygen -t ed25519 -f "$SSH_DIR/host_ed25519_key" -N "" -q
    ssh-keygen -t rsa -b 4096 -f "$SSH_DIR/host_rsa_key" -N "" -q
fi

# ── Configure sshd ───────────────────────────────────────────────────────────
cat > /etc/ssh/sshd_config.d/vibe.conf <<SSHD
HostKey $SSH_DIR/host_ed25519_key
HostKey $SSH_DIR/host_rsa_key
PasswordAuthentication no
PermitRootLogin no
AllowUsers $USER_NAME
SSHD

# ── Generate git deploy key (if not exists) ───────────────────────────────────
if [ ! -f "$SSH_DIR/id_ed25519" ]; then
    echo ">>> [ssh] Generating git deploy key..."
    ssh-keygen -t ed25519 -f "$SSH_DIR/id_ed25519" -N "" -C "vibe-deploy-key" -q
    echo ">>> [ssh] Deploy key public:"
    cat "$SSH_DIR/id_ed25519.pub"
fi

chown -R "$USER_NAME:$USER_NAME" "$SSH_DIR"
chmod 700 "$SSH_DIR"
chmod 600 "$SSH_DIR"/authorized_keys 2>/dev/null || true
chmod 600 "$SSH_DIR"/host_*_key "$SSH_DIR"/id_ed25519 2>/dev/null || true

/usr/sbin/sshd
echo ">>> [ssh] sshd running on port 22"
