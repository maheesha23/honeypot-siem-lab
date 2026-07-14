#!/usr/bin/env bash
# Provisions the attacker VM with common offensive tooling.
# All tools here are free/open-source and available via apt.
set -e

echo "==> Updating package lists"
apt-get update -y

echo "==> Installing attack tooling"
apt-get install -y \
    nmap \
    hydra \
    nikto \
    sqlmap \
    netcat-openbsd \
    curl \
    python3 \
    python3-pip \
    git

echo "==> Installing python packages used by attack-scripts/"
pip3 install requests

echo "==> Attacker VM provisioning complete"
echo "    Honeypot target IP: 192.168.56.20"
echo "    Monitoring VM IP:   192.168.56.30"
echo ""
echo "    Test connectivity with: ping -c 3 192.168.56.20"
