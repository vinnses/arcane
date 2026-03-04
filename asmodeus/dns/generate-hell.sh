#!/bin/sh
# generate-hell.sh — generate dnsmasq address records for .hell domain
# Runs inside the taildns container. Writes /data/hell.conf.
# Usage: generate-hell.sh [--wait]

set -eu

OUTPUT=/data/hell.conf

# Wait for tailscale to be online
until tailscale status > /dev/null 2>&1; do
    echo "[generate-hell] Waiting for tailscale..."
    sleep 2
done

echo "[generate-hell] Generating $OUTPUT from tailscale status..."

# Parse tailscale status output:
#   <ip>  <hostname>  <user>  <status...>
# Skip header line and tagged devices (user == "tagged-devices")
tailscale status --json | \
    awk '
        /"TailscaleIPs"/ { in_peer = 1 }
        in_peer && /"TailscaleIPs"/ { ip_block = 1 }
    ' || true

# Use text output for simpler parsing
tailscale status | awk '
    NR == 1 { next }                        # skip header
    /^#/ { next }                           # skip comment lines
    { ip=$1; host=$2; user=$3 }
    user == "tagged-devices" { next }       # skip tagged devices
    ip ~ /^[0-9]/ && host != "" {
        # strip trailing dot from hostname if present
        sub(/\.$/, "", host)
        # take only the first label (strip .tail*.ts.net suffix if any)
        split(host, parts, ".")
        name = parts[1]
        print "address=/" name ".hell/" ip
        print "address=/." name ".hell/" ip
    }
' > "$OUTPUT"

count=$(grep -c "^address=" "$OUTPUT" 2>/dev/null || echo 0)
echo "[generate-hell] Done. Wrote $((count / 2)) host record(s) to $OUTPUT."

# If dnsmasq is running in the sibling container, it needs a restart to pick up changes.
echo "[generate-hell] Note: restart dnsmasq to apply new records:"
echo "  docker compose restart dnsmasq"
