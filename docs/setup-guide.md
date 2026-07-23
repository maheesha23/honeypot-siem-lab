# Setup Guide

Full walkthrough for standing up the lab from a clean clone, plus troubleshooting notes for issues encountered during real testing.

## 1. Prerequisites

- [VirtualBox](https://www.virtualbox.org/) installed
- [Vagrant](https://www.vagrantup.com/) installed (`vagrant --version` should return a version number)
- 12GB+ free RAM on the host (the monitoring VM alone is allocated 4GB)
- ~40GB free disk space

If your default drive is short on space, redirect both VirtualBox and Vagrant's storage before bringing up any VMs:

```powershell
# VirtualBox VM storage location
VBoxManage setproperty machinefolder "D:\path\to\storage"

# Vagrant box cache location
setx VAGRANT_HOME "D:\path\to\storage\VagrantHome"
```
(Restart your terminal after `setx` for it to take effect.)

## 2. Bring up the VMs

From the `vagrant/` directory:

```bash
cd vagrant
vagrant up honeypot
vagrant up monitoring
vagrant up attacker
```

Bringing them up one at a time (rather than all via a single `vagrant up`) makes it much easier to spot which VM has an issue if something goes wrong.

**Expect this to take a while.** `monitoring` in particular can take 15-20+ minutes (Wazuh's all-in-one installer sets up an indexer, manager, and dashboard sequentially). `honeypot` will also pause for several minutes while Suricata compiles its detection engine after `suricata-update` loads ~52,000 rules - this is normal, not a hang.

## 3. Verify each VM

**Honeypot:**
```bash
vagrant ssh honeypot
sudo -u cowrie -i
cd cowrie && source cowrie-env/bin/activate && cowrie status
exit
sudo systemctl status suricata
sudo systemctl status wazuh-agent
```

**Monitoring:**
```bash
vagrant ssh monitoring
sudo systemctl status wazuh-indexer wazuh-manager wazuh-dashboard
sudo /var/ossec/bin/agent_control -l
```
The second command should list `honeypot` as an `Active` agent, not `Never connected`.

## 4. Access the dashboard

Open `https://192.168.56.30/` in your host browser. You'll get a self-signed certificate warning - this is expected, click through it.

Retrieve the generated admin password:
```bash
vagrant ssh monitoring
sudo tar -xf /root/wazuh-install-files.tar -C /root/
sudo cat /root/wazuh-install-files/wazuh-passwords.txt
```
Log in as `admin` with the password shown.

## 5. Run an attack scenario

```bash
vagrant ssh attacker
cd /vagrant/attack-scripts
./brute_force.sh
```

Then check the results either directly on the honeypot VM (`cowrie.json`) or in the Wazuh dashboard's Discover view, filtered to `agent.name: "honeypot"`.

---

## Troubleshooting notes (from real testing)

These are genuine issues hit while building this lab, kept here so they don't have to be rediscovered.

### Cowrie: `bin/cowrie: No such file or directory`

Cowrie 3.x installs its CLI as a pip entry point rather than shipping a standalone `bin/cowrie` script. If you see this error, the fix is:
```bash
source cowrie-env/bin/activate
pip install -e .
cowrie start
```
This is already handled in `honeypot.sh`, but worth knowing if you ever run Cowrie's install steps manually.

### Cowrie doesn't survive a VM reboot

Cowrie is not a systemd-managed service - it's a background daemon that `cowrie start` launches manually. A `vagrant reload` or host reboot will leave it stopped. Check with `cowrie status` and restart with `cowrie start` if needed after any VM restart.

### Suricata: `rules_loaded: 0` despite rules downloading successfully

Ubuntu's packaged `suricata.yaml` defaults `default-rule-path` to `/etc/suricata/rules`, but `suricata-update` writes its compiled ruleset to `/var/lib/suricata/rules/suricata.rules`. If these don't match, Suricata starts cleanly but silently loads zero rules. `honeypot.sh` patches this path automatically; if you ever reset Suricata's config, re-apply it with:
```bash
sudo sed -i 's|default-rule-path: /etc/suricata/rules|default-rule-path: /var/lib/suricata/rules|' /etc/suricata/suricata.yaml
```

### Suricata rule compilation looks like a hang

After `suricata-update` loads ~52,000 rules, Suricata spends several minutes building its detection engine's internal pattern-matching structures at ~99% CPU on a single core. This is expected on a 2-vCPU VM and can take 5-15 minutes. Confirm it's progressing (not actually stuck) by checking for the `engine started` line:
```bash
sudo tail -5 /var/log/suricata/suricata.log
```

### Suricata rule compilation causes an out-of-memory crash

On a VM with only 2GB RAM, rule compilation can exhaust memory and crash the network adapter (visible as repeated `enp0s3: Reset Adapter` messages, followed by an unresponsive SSH session). The honeypot VM is allocated 3GB in the `Vagrantfile` specifically to avoid this - don't reduce it below that without testing.

### `configs/cowrie.cfg` and `configs/suricata.yaml` are intentionally empty

Both files are placeholders by design, not an oversight. `honeypot.sh` only copies them over the tool's packaged default if they're non-empty (`[ -s file ]`) - an earlier version of this script copied them unconditionally, and an empty scaffolded file silently overwrote Suricata's real config, breaking it entirely. If you want to customize either tool's config, put your real config content in these files; leaving them empty keeps the packaged defaults (patched only for the interface name and rule path, as noted above).

### Wazuh agent enrollment fails: "Agent version must be lower or equal to manager version"

The Wazuh agent apt repository serves whatever the latest release is, which can drift ahead of whatever version the manager was installed with. `honeypot.sh` pins the agent to `4.9.2-1` (matching `monitoring.sh`'s `4.9` installer line) and holds the package to prevent future drift. If you ever change the manager's version, update the pin in `honeypot.sh` to match.

### Wazuh agent shows registered but "Never connected"

Enrollment (`agent-auth`, which exchanges keys) and the ongoing connection (`wazuh-agentd`, which needs the manager's address in `ossec.conf`) are two separate steps. If enrollment succeeds but the agent won't connect, check:
```bash
grep -A 1 "<server>" /var/ossec/etc/ossec.conf
```
If `<address>` is empty or shows a placeholder, the agent's config wasn't patched correctly - re-run:
```bash
sudo sed -i "s|<address>[^<]*</address>|<address>192.168.56.30</address>|" /var/ossec/etc/ossec.conf
sudo systemctl restart wazuh-agent
```

### `wazuh-indexer` / `wazuh-manager` fail with `start operation timed out` after a VM restart

These services can be slow to initialize under host resource pressure (e.g. multiple VMs running simultaneously), and may exceed systemd's default start timeout on a restart even though they installed and ran correctly the first time. A plain restart usually resolves it:
```bash
sudo systemctl restart wazuh-indexer
sudo systemctl restart wazuh-manager
```

### PowerShell: `chmod` / scripts blocked from running

Windows PowerShell doesn't have `chmod` (that's a Unix permissions concept, not needed on Windows). If a downloaded `.ps1` script won't run due to execution policy:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Unblock-File -Path .\scriptname.ps1
```

### Git: CRLF/LF warnings on `.sh` files

Windows Git can silently convert Unix line endings (`LF`) to Windows line endings (`CRLF`), which breaks bash scripts inside the Linux VMs (`bad interpreter` errors). This repo's `.gitattributes` forces `.sh`, `Vagrantfile`, `.cfg`, and `.yaml` files to always use `LF` regardless of the developer's OS settings.
