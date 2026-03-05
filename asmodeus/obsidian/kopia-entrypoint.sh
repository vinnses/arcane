#!/bin/sh
set -e

REPO_PATH="/app/repository"
SOURCE_PATH="/app/source"
CONFIG_PATH="/app/config"

# Initialize or connect to existing repository
if [ ! -f "$REPO_PATH/kopia.repository.f" ]; then
  echo "[init] Creating new repository at $REPO_PATH"
  kopia repository create filesystem \
    --path="$REPO_PATH" \
    --config-file="$CONFIG_PATH/repository.config" \
    --password="$KOPIA_PASSWORD"
else
  echo "[init] Connecting to existing repository at $REPO_PATH"
  kopia repository connect filesystem \
    --path="$REPO_PATH" \
    --config-file="$CONFIG_PATH/repository.config" \
    --password="$KOPIA_PASSWORD"
fi

# Set snapshot policy for the vault source
echo "[init] Applying snapshot policy for $SOURCE_PATH"
kopia policy set "$SOURCE_PATH" \
  --config-file="$CONFIG_PATH/repository.config" \
  --snapshot-interval=1m \
  --keep-latest=120 \
  --keep-hourly=48 \
  --keep-daily=14 \
  --keep-weekly=8 \
  --keep-monthly=6 \
  --keep-annual=2 \
  --compression=zstd

# Take an initial snapshot if none exists
SNAP_COUNT=$(kopia snapshot list "$SOURCE_PATH" --config-file="$CONFIG_PATH/repository.config" --json 2>/dev/null | grep -c '"id"' || true)
if [ "$SNAP_COUNT" -eq 0 ]; then
  echo "[init] Taking initial snapshot"
  kopia snapshot create "$SOURCE_PATH" \
    --config-file="$CONFIG_PATH/repository.config"
fi

echo "[init] Starting Kopia server"
exec kopia server start \
  --config-file="$CONFIG_PATH/repository.config" \
  --address=0.0.0.0:${KOPIA_PORT:-51515} \
  --insecure \
  --server-username="$KOPIA_SERVER_USERNAME" \
  --server-password="$KOPIA_SERVER_PASSWORD" \
  --without-password
