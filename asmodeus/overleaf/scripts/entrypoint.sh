#!/bin/bash

TEXLIVE_FULL="${TEXLIVE_FULL:-false}"

if [[ "$TEXLIVE_FULL" == "true" ]]; then
    echo "[entrypoint] TEXLIVE_FULL=true, installing TexLive full..."
    /usr/local/bin/texlive-install.sh
fi

exec /sbin/my_init
