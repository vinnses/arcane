#!/bin/bash
set -euo pipefail

CONTAINER="sharelatex"

if ! docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -q true; then
    echo "ERROR: Container '$CONTAINER' is not running."
    echo "Start the stack first: docker compose up -d"
    exit 1
fi

echo "Installing TexLive full in '$CONTAINER'..."
echo "This will download ~5GB and take 30-60+ minutes."
echo ""

docker exec "$CONTAINER" tlmgr install scheme-full

echo ""
echo "Done. TexLive full is now installed and persisted in the 'texlive' volume."
echo "It will survive container restarts and rebuilds."
