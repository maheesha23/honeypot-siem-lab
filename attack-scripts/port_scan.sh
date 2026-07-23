#!/usr/bin/env bash
# Network/service scan scenario against the honeypot VM.
#
# Target: honeypot VM (192.168.56.20)
# MITRE ATT&CK: T1046 - Network Service Discovery
#
# Usage:
#   ./port_scan.sh [target_ip]
#   Defaults to the honeypot VM if no argument is given.

set -e

TARGET_IP="${1:-192.168.56.20}"

echo "==> Network/service scan scenario"
echo "    Target: ${TARGET_IP}"
echo "    MITRE ATT&CK: T1046 (Network Service Discovery)"
echo ""

echo "==> Checking connectivity to target"
if ! ping -c 2 -W 2 "$TARGET_IP" >/dev/null 2>&1; then
    echo "ERROR: Cannot reach ${TARGET_IP}. Confirm the honeypot VM is up (vagrant status)."
    exit 1
fi

echo "==> Running service/version detection scan"
nmap -sV -sC "$TARGET_IP"

echo ""
echo "==> Scenario complete."
echo "    Check Suricata's IDS log on the honeypot VM for this scan:"
echo "      vagrant ssh honeypot"
echo "      sudo grep '\"alert\"' /var/log/suricata/eve.json | tail -10"
echo ""
echo "    Or search the Wazuh dashboard (https://192.168.56.30/) for:"
echo "      agent.name: \"honeypot\" AND rule.groups: \"suricata\""
