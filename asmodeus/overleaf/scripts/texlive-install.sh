#!/bin/bash
set -euo pipefail

MARKER="/usr/local/texlive/.scheme-full-installed"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIRROR_SCRIPT="${SCRIPT_DIR}/texlive-mirror.sh"

log() {
    echo "[texlive] $(date '+%Y-%m-%d %H:%M:%S') $*"
}

if ! command -v tlmgr >/dev/null 2>&1; then
    log "ERROR: tlmgr not found. Is this running inside the sharelatex container?"
    exit 1
fi

if [[ ! -x "$MIRROR_SCRIPT" ]]; then
    log "ERROR: mirror script not found or not executable: ${MIRROR_SCRIPT}"
    exit 1
fi

# Check if already installed
if [[ -f "$MARKER" ]]; then
    log "TexLive full already installed (marker: ${MARKER})"
    exit 0
fi

log "Starting TexLive full installation..."
start_time=$(date +%s)

# Get best mirror
log "Selecting fastest CTAN mirror..."
mirror="$($MIRROR_SCRIPT)"

log "Using mirror: ${mirror}"
tlmgr option repository "${mirror}"

log "Updating tlmgr..."
tlmgr update --self

log "Installing scheme-full (this will take 30-60+ minutes)..."
tlmgr install scheme-full

# Mark as installed
touch "$MARKER"

end_time=$(date +%s)
duration=$(( end_time - start_time ))
minutes=$(( duration / 60 ))
seconds=$(( duration % 60 ))

log "TexLive full installation complete in ${minutes}m ${seconds}s"
