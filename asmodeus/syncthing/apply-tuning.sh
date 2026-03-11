#!/bin/sh
# apply-tuning.sh — Apply Syncthing configuration tuning to an existing config.xml
#
# Usage:
#   ./apply-tuning.sh [/path/to/config.xml]
#
# Defaults to ${ARCANE}/syncthing/.data/config.xml if no argument is given.
#
# What this script changes:
#   In ALL <folder> blocks (including <defaults><folder>):
#     - rescanIntervalS       → 60
#     - fsWatcherDelayS       → 1
#     - <order>               → newestFirst
#     - <versioning>          → type="staggered" with <param key="maxAge" val="2592000">
#   In <options>:
#     - <reconnectionIntervalS> → 30
#     - <setLowPriority>        → false
#     - <startBrowser>          → false
#
# What this script does NOT change:
#   - Device identities, certificates, API keys, GUI config
#   - Folder paths, device entries, device IDs
#   - ignorePerms (stays false for Linux-only sync; set manually to true if
#     Android devices are added to a shared folder)
#
# The script is idempotent — running it twice produces the same result.

set -eu

CONFIG="${1:-${ARCANE:-}/syncthing/.data/config.xml}"

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: Config file not found: $CONFIG"
    echo "Usage: $0 [/path/to/config.xml]"
    exit 1
fi

if ! grep -q '<configuration' "$CONFIG"; then
    echo "ERROR: File does not appear to be a valid Syncthing config.xml (missing <configuration>)"
    exit 1
fi

echo "Applying Syncthing tuning to: $CONFIG"
echo ""

# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------

cp "$CONFIG" "${CONFIG}.bak"
echo "  Backup created: ${CONFIG}.bak"

# ---------------------------------------------------------------------------
# Folder attributes: rescanIntervalS and fsWatcherDelayS
# These attributes appear on the <folder ...> opening tag (single line).
# ---------------------------------------------------------------------------

sed -i 's/\(rescanIntervalS="\)[^"]*"/\160"/g' "$CONFIG"
echo "  [folder] rescanIntervalS → 60"

sed -i 's/\(fsWatcherDelayS="\)[^"]*"/\11"/g' "$CONFIG"
echo "  [folder] fsWatcherDelayS → 1"

# ---------------------------------------------------------------------------
# Folder element: <order>
# ---------------------------------------------------------------------------

sed -i 's|<order>[^<]*</order>|<order>newestFirst</order>|g' "$CONFIG"
echo "  [folder] <order> → newestFirst"

# ---------------------------------------------------------------------------
# Versioning block: set type="staggered" and ensure maxAge param exists
#
# Step 1: Normalize the type attribute on <versioning> tags.
#   - Remove any existing type attribute, then add type="staggered".
#   - Running twice: first sed converts type="staggered" → bare tag,
#     second sed adds it back. Net result is identical. Idempotent. ✓
# ---------------------------------------------------------------------------

sed -i 's|<versioning type="[^"]*">|<versioning>|g' "$CONFIG"
sed -i 's|<versioning>|<versioning type="staggered">|g' "$CONFIG"
echo "  [versioning] type → staggered"

# Step 2: Update <param key="maxAge"> value if it already exists.
sed -i 's|<param key="maxAge" val="[^"]*"></param>|<param key="maxAge" val="2592000"></param>|g' "$CONFIG"

# Step 3: Insert <param key="maxAge"> before </versioning> if not already present.
#   Uses awk to track whether we are inside a versioning block and whether the
#   param was already seen before the closing tag.
awk '
{
    if (/<versioning/) { in_v = 1; has_param = 0 }
    if (in_v && /param key="maxAge"/) { has_param = 1 }
    if (in_v && /<\/versioning>/ && !has_param) {
        match($0, /^[[:space:]]*/); indent = substr($0, 1, RLENGTH)
        print indent "    <param key=\"maxAge\" val=\"2592000\"></param>"
        has_param = 1
    }
    if (/<\/versioning>/) { in_v = 0 }
    print
}
' "$CONFIG" > "${CONFIG}.tmp" && mv "${CONFIG}.tmp" "$CONFIG"
echo "  [versioning] <param key=\"maxAge\" val=\"2592000\"> added/updated"

# ---------------------------------------------------------------------------
# Options block
# ---------------------------------------------------------------------------

sed -i 's|<reconnectionIntervalS>[^<]*</reconnectionIntervalS>|<reconnectionIntervalS>30</reconnectionIntervalS>|g' "$CONFIG"
echo "  [options] reconnectionIntervalS → 30"

sed -i 's|<setLowPriority>[^<]*</setLowPriority>|<setLowPriority>false</setLowPriority>|g' "$CONFIG"
echo "  [options] setLowPriority → false"

sed -i 's|<startBrowser>[^<]*</startBrowser>|<startBrowser>false</startBrowser>|g' "$CONFIG"
echo "  [options] startBrowser → false"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

echo ""
echo "Tuning complete. To apply changes, restart Syncthing:"
echo ""
echo "  docker compose -f syncthing/compose.yaml restart syncthing"
echo ""
