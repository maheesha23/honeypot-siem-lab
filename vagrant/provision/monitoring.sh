#!/usr/bin/env bash
# Provisions the monitoring VM with the Wazuh all-in-one stack:
# indexer + manager + dashboard, all on a single node.
# This is the SIEM that receives logs from the honeypot VM's Wazuh agent.
set -e

echo "==> Updating package lists"
apt-get update -y
apt-get install -y curl

echo "==> Downloading Wazuh installer"
cd /root
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh

echo "==> Running Wazuh all-in-one install (this takes a while, be patient)"
bash wazuh-install.sh --all-in-one --ignore-check

echo ""
echo "==> Wazuh installation complete"
echo "    Dashboard URL: https://192.168.56.30/"
echo "    (self-signed certificate - your browser will warn, that's expected)"
echo ""
echo "    Admin credentials were generated during install and saved to:"
echo "    /root/wazuh-install-files.tar"
echo ""
echo "    To view them:"
echo "    tar -xf /root/wazuh-install-files.tar"
echo "    cat wazuh-install-files/wazuh-passwords.txt"
