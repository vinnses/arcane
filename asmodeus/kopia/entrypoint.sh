#!/bin/sh

set -e

REPO_PATH="/app/repository"
CONFIG_FILE="/app/config/repository.config"
SOURCES_FILE="/app/sources.conf"

# --- Repository init or connect ---
if [ ! -f "$REPO_PATH/kopia.repository.f" ]; then
  echo "[kopia] Creating new repository at $REPO_PATH"
  kopia repository create filesystem \
    --path="$REPO_PATH" \
    --config-file="$CONFIG_FILE" \
    --password="$KOPIA_PASSWORD"
else
  echo "[kopia] Connecting to existing repository at $REPO_PATH"
  kopia repository connect filesystem \
    --path="$REPO_PATH" \
    --config-file="$CONFIG_FILE" \
    --password="$KOPIA_PASSWORD"
fi

# --- Apply policies from sources.conf ---
if [ -f "$SOURCES_FILE" ]; then
  grep -v '^\s*#' "$SOURCES_FILE" | grep -v '^\s*$' | while IFS='|' read -r src_path interval keep_latest keep_hourly keep_daily keep_weekly keep_monthly keep_annual compression; do
    if [ -d "$src_path" ]; then
      echo "[kopia] Applying policy for $src_path (interval=$interval, compression=$compression)"
      kopia policy set "$src_path" \
        --config-file="$CONFIG_FILE" \
        --snapshot-interval="$interval" \
        --keep-latest="$keep_latest" \
        --keep-hourly="$keep_hourly" \
        --keep-daily="$keep_daily" \
        --keep-weekly="$keep_weekly" \
        --keep-monthly="$keep_monthly" \
        --keep-annual="$keep_annual" \
        --compression="$compression"

      SNAP_COUNT=$(kopia snapshot list "$src_path" --config-file="$CONFIG_FILE" --json 2>/dev/null | grep -c '"id"' || true)
      if [ "$SNAP_COUNT" -eq 0 ]; then
        echo "[kopia] Taking initial snapshot of $src_path"
        kopia snapshot create "$src_path" --config-file="$CONFIG_FILE"
      fi
    else
      echo "[kopia] WARNING: source path $src_path does not exist, skipping"
    fi
  done
else
  echo "[kopia] WARNING: $SOURCES_FILE not found, no policies applied"
fi

# --- Start server ---
echo "[kopia] Starting server"
exec kopia server start \
  --config-file="$CONFIG_FILE" \
  --address=0.0.0.0:${KOPIA_PORT} \
  --insecure \
  --server-username="$KOPIA_SERVER_USERNAME" \
  --server-password="$KOPIA_SERVER_PASSWORD" \
  --without-password
