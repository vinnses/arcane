#!/bin/bash
set -euo pipefail

# CTAN mirror list (geographically diverse)
MIRRORS=(
    "https://ctan.dcc.uchile.cl/systems/texlive/tlnet"
    "https://mirrors.mit.edu/CTAN/systems/texlive/tlnet"
    "https://tug.ctan.org/systems/texlive/tlnet"
    "https://mirrors.dotsrc.org/ctan/systems/texlive/tlnet"
    "https://ftp.jaist.ac.jp/pub/CTAN/systems/texlive/tlnet"
)

# If TEXLIVE_MIRROR is set, use it directly (manual override)
if [[ -n "${TEXLIVE_MIRROR:-}" ]]; then
    echo "[mirror] Using user-specified mirror: ${TEXLIVE_MIRROR}" >&2
    echo "${TEXLIVE_MIRROR}"
    exit 0
fi

echo "[mirror] Testing ${#MIRRORS[@]} CTAN mirrors..." >&2

best_mirror=""
best_time=""
results=()

for mirror in "${MIRRORS[@]}"; do
    url="${mirror}/tlpkg/texlive.tlpdb"
    result=$(curl -s -o /dev/null -w "%{time_total} %{http_code}" --max-time 10 "$url" 2>/dev/null) || result="99.999 000"
    time_total=$(echo "$result" | awk '{print $1}')
    http_code=$(echo "$result" | awk '{print $2}')

    if [[ "$http_code" == "200" ]]; then
        results+=("${time_total} ${mirror}")
        echo "[mirror] ${time_total}s ${mirror}" >&2

        if [[ -z "$best_time" ]] || awk "BEGIN{exit !(${time_total} < ${best_time})}"; then
            best_time="$time_total"
            best_mirror="$mirror"
        fi
    else
        echo "[mirror] FAILED (HTTP ${http_code}) ${mirror}" >&2
    fi
done

if [[ -z "$best_mirror" ]]; then
    echo "[mirror] ERROR: All mirrors failed" >&2
    exit 1
fi

echo "[mirror] Selected: ${best_mirror} (${best_time}s)" >&2
echo "${best_mirror}"
