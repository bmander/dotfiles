#!/usr/bin/env bash
set -euo pipefail

# Egress firewall for devcontainers running Claude Code.
# Adapted from https://github.com/anthropics/claude-code/blob/main/.devcontainer/init-firewall.sh
#
# Allows: DNS, SSH, localhost, Docker host gateway, GitHub, npm registry,
#         Anthropic API, Sentry, Statsig.
# Blocks everything else.

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: init-firewall.sh must be run as root" >&2
    exit 1
fi

resolve() {
    dig +short "$1" | grep -E '^[0-9]+\.' || true
}

# Preserve Docker DNS NAT rules before flushing
iptables-save -t nat > /tmp/docker-nat-rules.txt

# Flush existing filter rules
iptables -F OUTPUT
iptables -F INPUT
iptables -F FORWARD

# Restore NAT rules
iptables-restore --noflush < /tmp/docker-nat-rules.txt
rm -f /tmp/docker-nat-rules.txt

# Create ipset for allowed destinations
ipset create allowed_hosts hash:net -exist
ipset flush allowed_hosts

# GitHub IP ranges
echo "Fetching GitHub IP ranges..."
gh_meta="$(curl -sf https://api.github.com/meta || true)"
if [ -n "$gh_meta" ]; then
    for key in web api git; do
        while IFS= read -r cidr; do
            # Skip IPv6
            [[ "$cidr" == *:* ]] && continue
            ipset add allowed_hosts "$cidr" -exist
        done < <(echo "$gh_meta" | jq -r ".${key}[]" 2>/dev/null || true)
    done
fi

# DNS-resolved hosts
allowed_domains=(
    registry.npmjs.org
    api.anthropic.com
    sentry.io
    statsig.anthropic.com
    statsig.com
)

for domain in "${allowed_domains[@]}"; do
    for ip in $(resolve "$domain"); do
        ipset add allowed_hosts "$ip/32" -exist
    done
done

# Allow loopback
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow DNS (UDP 53)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT

# Allow SSH (TCP 22)
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT

# Allow Docker host gateway (for Docker-in-Docker, host services)
host_gateway="$(ip route | awk '/default/ {print $3}')"
if [ -n "$host_gateway" ]; then
    iptables -A OUTPUT -d "$host_gateway" -j ACCEPT
fi

# Allow ipset destinations (HTTPS)
iptables -A OUTPUT -p tcp --dport 443 -m set --match-set allowed_hosts dst -j ACCEPT

# Default: reject with icmp-admin-prohibited, then drop
iptables -A OUTPUT -p tcp -j REJECT --reject-with icmp-port-unreachable
iptables -A OUTPUT -j DROP

echo "Firewall initialized."

# Verification (non-fatal)
if curl -sf --connect-timeout 3 https://example.com >/dev/null 2>&1; then
    echo "WARNING: example.com is reachable — firewall may not be working"
else
    echo "Verified: example.com is blocked"
fi

if curl -sf --connect-timeout 5 https://api.github.com/zen >/dev/null 2>&1; then
    echo "Verified: api.github.com is reachable"
else
    echo "WARNING: api.github.com is not reachable — GitHub access may be broken"
fi
