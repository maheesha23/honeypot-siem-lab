#!/usr/bin/env bash
# Provisions the honeypot VM with:
#   - Cowrie (SSH/Telnet honeypot)
#   - Suricata (IDS, logs to eve.json)
#   - Wazuh agent (forwards logs to the monitoring VM)
set -e

WAZUH_MANAGER_IP="${WAZUH_MANAGER_IP:-192.168.56.30}"

# Prevent apt/dpkg from ever waiting on interactive prompts (e.g. needrestart's
# "which services should restart" dialog) during unattended provisioning.
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

echo "==> Updating package lists"
apt-get update -y

# -----------------------------------------------------------------
# Cowrie
# -----------------------------------------------------------------
echo "==> Installing Cowrie dependencies"
apt-get install -y \
    git python3-venv python3-dev python3-pip \
    libssl-dev libffi-dev build-essential \
    authbind

echo "==> Creating cowrie user"
if ! id "cowrie" &>/dev/null; then
    adduser --disabled-password --gecos "" cowrie
fi

echo "==> Cloning Cowrie"
sudo -u cowrie bash <<'EOF'
cd /home/cowrie
if [ ! -d cowrie ]; then
    git clone https://github.com/cowrie/cowrie.git
fi
cd cowrie
python3 -m venv cowrie-env
source cowrie-env/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
# Newer Cowrie versions (3.x) install the 'cowrie' command as a proper
# package entry point via pip, rather than shipping a bin/cowrie script.
pip install -e .
EOF

echo "==> Applying Cowrie config"
if [ -s /vagrant_configs/cowrie.cfg ]; then
    cp /vagrant_configs/cowrie.cfg /home/cowrie/cowrie/etc/cowrie.cfg
    chown cowrie:cowrie /home/cowrie/cowrie/etc/cowrie.cfg
else
    echo "    configs/cowrie.cfg is empty, keeping Cowrie's packaged default (cowrie.cfg.dist)"
fi

echo "==> Starting Cowrie (listens on 2222/2223 by default)"
sudo -u cowrie bash <<'EOF'
cd /home/cowrie/cowrie
source cowrie-env/bin/activate
cowrie start
EOF

# -----------------------------------------------------------------
# Suricata
# -----------------------------------------------------------------
echo "==> Installing Suricata"
# Ensure no stale/empty config exists before install, so apt always lays
# down its real packaged default cleanly (avoids dpkg treating an empty
# placeholder as a "locally modified" conffile it refuses to overwrite).
apt-get purge -y suricata 2>/dev/null || true
rm -f /etc/suricata/suricata.yaml
apt-get install -y suricata

if [ -s /vagrant_configs/suricata.yaml ]; then
    echo "==> Applying custom suricata.yaml from configs/"
    cp /vagrant_configs/suricata.yaml /etc/suricata/suricata.yaml
else
    echo "==> configs/suricata.yaml is empty, keeping Suricata's packaged default"
fi

echo "==> Patching Suricata interface to match this VM's NIC (enp0s3)"
sed -i 's/interface: eth0/interface: enp0s3/' /etc/suricata/suricata.yaml

echo "==> Downloading Suricata detection rules (Emerging Threats Open)"
suricata-update

echo "==> Pointing Suricata at the suricata-update rule output path"
sed -i 's|default-rule-path: /etc/suricata/rules|default-rule-path: /var/lib/suricata/rules|' /etc/suricata/suricata.yaml

echo "==> Enabling and starting Suricata"
systemctl enable suricata
systemctl restart suricata

# -----------------------------------------------------------------
# Wazuh agent (forwards Cowrie + Suricata logs to the monitoring VM)
# -----------------------------------------------------------------
echo "==> Installing Wazuh agent"
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list
apt-get update -y

WAZUH_MANAGER="$WAZUH_MANAGER_IP" apt-get install -y wazuh-agent=4.9.2-1
apt-mark hold wazuh-agent

echo "==> Configuring Wazuh agent to monitor Cowrie and Suricata logs"
# Matches the placeholder OR any previously-set IP, so this stays correct
# even if this step runs again after a manual reinstall regenerates the
# default config (which happened during testing - apt reinstalling the
# package restores the MANAGER_IP placeholder, silently undoing this fix).
sed -i "s|<address>[^<]*</address>|<address>${WAZUH_MANAGER_IP}</address>|" /var/ossec/etc/ossec.conf

# Add localfile blocks for Cowrie's json log and Suricata's eve.json
# (idempotent-ish: only appends if not already present)
if ! grep -q "cowrie.json" /var/ossec/etc/ossec.conf; then
    sed -i '/<\/ossec_config>/i \
  <localfile>\
    <log_format>json</log_format>\
    <location>/home/cowrie/cowrie/var/log/cowrie/cowrie.json</location>\
  </localfile>\
  <localfile>\
    <log_format>json</log_format>\
    <location>/var/log/suricata/eve.json</location>\
  </localfile>' /var/ossec/etc/ossec.conf
fi

echo "==> Enrolling this agent with the Wazuh manager (${WAZUH_MANAGER_IP})"
# Requires the monitoring VM to already be up and wazuh-authd listening
# on port 1515. If monitoring isn't up yet, this is skipped with a warning
# rather than failing the whole provisioning run - re-run manually later:
#   sudo /var/ossec/bin/agent-auth -m <manager-ip>
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/${WAZUH_MANAGER_IP}/1515" 2>/dev/null; then
    /var/ossec/bin/agent-auth -m "${WAZUH_MANAGER_IP}"
else
    echo "    WARNING: Manager not reachable on port 1515 yet - skipping enrollment."
    echo "    Once the monitoring VM is up, run on this VM:"
    echo "      sudo /var/ossec/bin/agent-auth -m ${WAZUH_MANAGER_IP}"
    echo "      sudo systemctl restart wazuh-agent"
fi

echo "==> Enabling and starting Wazuh agent"
systemctl enable wazuh-agent
systemctl restart wazuh-agent

echo "==> Honeypot VM provisioning complete"
echo "    Cowrie SSH honeypot: port 2222  (Telnet: 2223)"
echo "    Suricata eve.json:   /var/log/suricata/eve.json"
echo "    Wazuh manager:       ${WAZUH_MANAGER_IP}"
