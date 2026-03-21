#!/bin/bash
set -e

USER_NAME="${VIBE_USER:-vibecoder}"
USER_HOME=$(eval echo "~$USER_NAME")
INIT_DIR="$USER_HOME/init.d"

echo ">>> [vibe] Initializing..."

for script in "$INIT_DIR"/*.sh; do
    [ -f "$script" ] || continue
    echo ">>> [vibe] Running $(basename "$script")..."
    bash "$script"
done

echo ">>> [vibe] Ready."
exec sleep infinity
