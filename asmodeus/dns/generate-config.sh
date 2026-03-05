#!/bin/sh
# generate-config.sh — generate dnsmasq configs for .hell domain and upstream DNS
# Runs inside the taildns container. Writes /data/hell.conf and /data/upstream.conf.
# Usage: generate-config.sh

set -eu

HELL_CONF=/data/hell.conf
UPSTREAM_CONF=/data/upstream.conf

# Wait for tailscale to be online
until tailscale status > /dev/null 2>&1; do
    echo "[generate-config] Waiting for tailscale..."
    sleep 2
done

echo "[generate-config] Generating $HELL_CONF from tailscale status..."

# Parse text output of tailscale status:
#   <ip>  <hostname>  <user>  <status...>
# Skip header line and tagged devices (user == "tagged-devices")
tailscale status | awk '
    NR == 1 { next }
    /^#/ { next }
    { ip=$1; host=$2; user=$3 }
    user == "tagged-devices" { next }
    ip ~ /^[0-9]/ && host != "" {
        sub(/\.$/, "", host)
        split(host, parts, ".")
        name = parts[1]
        print "address=/" name ".hell/" ip
        print "address=/." name ".hell/" ip
    }
' > "$HELL_CONF"

count=$(grep -c "^address=" "$HELL_CONF" 2>/dev/null || echo 0)
echo "[generate-config] Wrote $((count / 2)) host record(s) to $HELL_CONF."

echo "[generate-config] Generating $UPSTREAM_CONF..."

cat > "$UPSTREAM_CONF" <<EOF
# Upstream from host DHCP (works on university/home/any network)
resolv-file=/upstream/nm-resolv.conf

# Fallback public DNS
server=1.1.1.1
server=8.8.8.8

# Tailscale MagicDNS
server=/${TS_MAGIC_DOMAIN}/100.100.100.100
EOF

echo "[generate-config] Done. Wrote $UPSTREAM_CONF."
echo "[generate-config] Note: restart dnsmasq to apply new records:"
echo "  docker compose restart dnsmasq"
