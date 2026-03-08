#!/usr/bin/env bash
set -euo pipefail

# Egress firewall for devcontainers running Claude Code.
# Uses tinyproxy for domain-based HTTP/HTTPS filtering.
# All outbound 80/443 is blocked except from tinyproxy itself;
# tools reach the internet via HTTP_PROXY/HTTPS_PROXY env vars.

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: init-firewall.sh must be run as root" >&2
    exit 1
fi

PROXY_PORT=3128
PROXY_USER="tinyproxy"
ENV_FILE="/tmp/proxy.env"

# --- Build allowed domains list ---

allowed_domains=(
    # Claude Code / Anthropic
    api.anthropic.com
    sentry.io
    statsig.anthropic.com
    statsig.com
    # npm registry
    registry.npmjs.org
    # GitHub
    github.com
    api.github.com
    raw.githubusercontent.com
    objects.githubusercontent.com
    gist.githubusercontent.com
    codeload.github.com
)

# Load project-specific domains
if allowed_file="/workspace/.devcontainer/allowed-domains.txt"; [ -r "$allowed_file" ]; then
    echo "Loading project-specific allowed domains..."
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%%#*}"                # strip comments
        line="${line#"${line%%[! ]*}"}"   # strip leading spaces
        line="${line%"${line##*[! ]}"}"   # strip trailing spaces
        [ -z "$line" ] && continue
        allowed_domains+=("$line")
    done < "$allowed_file"
fi

# --- Configure tinyproxy ---

# Build filter file (extended regex, one pattern per line)
filter_file="/etc/tinyproxy/filter"
mkdir -p /etc/tinyproxy
: > "$filter_file"
for domain in "${allowed_domains[@]}"; do
    # Escape dots for regex and anchor the match
    escaped="${domain//./\\.}"
    echo "^${escaped}$" >> "$filter_file"
done

cat > /etc/tinyproxy/tinyproxy.conf <<EOF
User $PROXY_USER
Group $PROXY_USER
Port $PROXY_PORT
Listen 127.0.0.1
Timeout 600
MaxClients 100
Filter "$filter_file"
FilterURLs Off
FilterExtended On
FilterCaseSensitive Off
FilterDefaultDeny Yes
ConnectPort 443
ConnectPort 80
LogLevel Error
EOF

echo "Starting tinyproxy..."
tinyproxy -c /etc/tinyproxy/tinyproxy.conf
sleep 1

# --- Write proxy env vars for the user session ---

cat > "$ENV_FILE" <<EOF
export HTTP_PROXY=http://127.0.0.1:${PROXY_PORT}
export HTTPS_PROXY=http://127.0.0.1:${PROXY_PORT}
export http_proxy=http://127.0.0.1:${PROXY_PORT}
export https_proxy=http://127.0.0.1:${PROXY_PORT}
export NO_PROXY=localhost,127.0.0.1
export no_proxy=localhost,127.0.0.1
export JAVA_TOOL_OPTIONS="-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=${PROXY_PORT} -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=${PROXY_PORT} -Dhttp.nonProxyHosts=localhost|127.0.0.1"
EOF
chmod 644 "$ENV_FILE"

# --- iptables ---

# Flush existing rules
iptables -F OUTPUT
iptables -F INPUT
iptables -F FORWARD

# Allow loopback
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow DNS (UDP 53)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT

# Allow SSH (TCP 22)
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT

# Allow Docker host gateway
host_gateway="$(ip route | awk '/default/ {print $3}')"
if [ -n "$host_gateway" ]; then
    iptables -A OUTPUT -d "$host_gateway" -j ACCEPT
fi

# Allow host.docker.internal (Docker Desktop resolves this to a different IP than the gateway)
# Filter to IPv4 only since iptables can't handle IPv6 addresses
host_internal="$(getent ahostsv4 host.docker.internal 2>/dev/null | awk 'NR==1{print $1}')"
if [ -n "$host_internal" ] && [ "$host_internal" != "$host_gateway" ]; then
    iptables -A OUTPUT -d "$host_internal" -j ACCEPT
fi

# Allow tinyproxy direct outbound on 80/443
proxy_uid="$(id -u "$PROXY_USER")"
iptables -A OUTPUT -m owner --uid-owner "$proxy_uid" -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -m owner --uid-owner "$proxy_uid" -p tcp --dport 443 -j ACCEPT

# Block all other direct outbound 80/443
iptables -A OUTPUT -p tcp --dport 80 -j REJECT --reject-with icmp-port-unreachable
iptables -A OUTPUT -p tcp --dport 443 -j REJECT --reject-with icmp-port-unreachable

# Drop everything else
iptables -A OUTPUT -p tcp -j REJECT --reject-with icmp-port-unreachable
iptables -A OUTPUT -j DROP

echo "Firewall initialized with tinyproxy domain filter."
echo "Allowed domains: ${#allowed_domains[@]}"

# --- Verification ---

# Source proxy env for verification commands
. "$ENV_FILE"

if curl -sf --connect-timeout 3 https://example.com >/dev/null 2>&1; then
    echo "WARNING: example.com is reachable — proxy filter may not be working"
else
    echo "Verified: example.com is blocked"
fi

if curl -sf --connect-timeout 5 https://api.github.com/zen >/dev/null 2>&1; then
    echo "Verified: api.github.com is reachable"
else
    echo "WARNING: api.github.com is not reachable — proxy may be misconfigured"
fi
