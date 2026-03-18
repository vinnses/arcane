#!/bin/bash
set -euo pipefail

MARKER="/usr/local/texlive/.scheme-full-installed"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIRROR_SCRIPT="${SCRIPT_DIR}/texlive-mirror.sh"

log() {
    echo "[texlive] $(date '+%Y-%m-%d %H:%M:%S') $*"
}

get_local_texlive_year() {
    local year

    # Strategy 1: year-named subdirectory under the TeX Live installation root
    year=$(ls /usr/local/texlive/ 2>/dev/null | grep -E '^[0-9]{4}$' | sort -n | tail -n1)
    if [[ -n "$year" ]]; then echo "$year"; return 0; fi

    # Strategy 2: parse "version YYYY" from tlmgr --version output
    year=$(tlmgr --version 2>/dev/null | grep -oE 'version [0-9]{4}' | awk '{print $2}' | head -n1)
    if [[ -n "$year" ]]; then echo "$year"; return 0; fi

    # Strategy 3: parse installation path "texlive/YYYY" from tlmgr --version output
    year=$(tlmgr --version 2>/dev/null | grep -oE 'texlive/[0-9]{4}' | grep -oE '[0-9]{4}' | head -n1)
    echo "$year"
}

set_historic_repository() {
    local local_year
    local_year="$(get_local_texlive_year)"

    if [[ -z "$local_year" ]]; then
        log "ERROR: unable to detect local TeX Live year from tlmgr --version"
        return 1
    fi

    local historic_repo="https://ftp.math.utah.edu/pub/tex/historic/systems/texlive/${local_year}/tlnet-final"
    log "Detected cross-release repository mismatch. Switching to compatible historic repo: ${historic_repo}"
    tlmgr option repository "${historic_repo}"
}

run_tlmgr_update_self() {
    set +e
    update_output="$(tlmgr update --self 2>&1)"
    update_status=$?
    set -e

    echo "$update_output"

    if [[ $update_status -eq 0 ]]; then
        return 0
    fi

    if grep -q "Local TeX Live .* is older than remote repository" <<< "$update_output"; then
        set_historic_repository || return 1
        tlmgr update --self
        return 0
    fi

    return $update_status
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
run_tlmgr_update_self

log "Installing scheme-full (this will take 30-60+ minutes)..."
tlmgr install scheme-full

# Mark as installed
touch "$MARKER"

end_time=$(date +%s)
duration=$(( end_time - start_time ))
minutes=$(( duration / 60 ))
seconds=$(( duration % 60 ))

log "TexLive full installation complete in ${minutes}m ${seconds}s"
