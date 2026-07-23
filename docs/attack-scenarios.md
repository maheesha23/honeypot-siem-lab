# Attack Scenarios

Two scripted, repeatable scenarios are included. Both are run from the `attacker` VM against the `honeypot` VM.

---

## Scenario 1: SSH Brute Force

**Script:** `attack-scripts/brute_force.sh`
**MITRE ATT&CK:** [T1110 - Brute Force](https://attack.mitre.org/techniques/T1110/)
**Target:** Cowrie, listening on port 2222

### Run it

```bash
vagrant ssh attacker
cd /vagrant/attack-scripts
./brute_force.sh
```

### What it does

Runs Hydra against the `root` account on Cowrie's SSH listener using a small built-in wordlist of common weak passwords.

### Expected result

Cowrie logs the full session lifecycle for each connection attempt to `/home/cowrie/cowrie/var/log/cowrie/cowrie.json`, including:

- `cowrie.session.connect` - new TCP connection from the attacker
- `cowrie.client.version` - the SSH client's version string
- `cowrie.client.kex` - key exchange details, including a hassh fingerprint of the client
- `cowrie.login.failed` / `cowrie.login.success` - each credential attempt, with the exact username/password tried
- `cowrie.session.closed` - session teardown, with duration

Example (real, sanitized output from a test run - see `sample-logs/cowrie-sample.json` for the full excerpt):

```json
{"session":"1959ce0399dc","protocol":"ssh","src_ip":"192.168.56.10","dst_ip":"192.168.56.20","dst_port":2222,"username":"root","password":"admin","eventid":"cowrie.login.success","message":"login attempt [root/admin] succeeded"}
```

Cowrie's default configuration accepts a subset of credentials as "successful" logins by design - this lets it capture what an attacker does *after* gaining access, which is valuable additional signal for a real honeypot deployment.

### Verify in the SIEM

In the Wazuh dashboard (`https://192.168.56.30/`), Discover view:
```
agent.name: "honeypot" AND data.eventid: "cowrie.login.success"
```

---

## Scenario 2: Network/Service Scan

**Script:** `attack-scripts/port_scan.sh`
**MITRE ATT&CK:** [T1046 - Network Service Discovery](https://attack.mitre.org/techniques/T1046/)
**Target:** Honeypot VM, all open ports

### Run it

```bash
vagrant ssh attacker
cd /vagrant/attack-scripts
./port_scan.sh
```

### What it does

Runs an Nmap service/version detection scan (`-sV -sC`) against the honeypot VM, identifying open ports and attempting to fingerprint the services running on them.

### Expected result

Nmap should report at least two open ports:
- `22/tcp` - the honeypot VM's real management SSH (used by Vagrant, not part of the decoy)
- `2222/tcp` - Cowrie's decoy SSH service

Suricata inspects this traffic at the network layer and logs to `/var/log/suricata/eve.json`. Whether a specific alert fires depends on which Emerging Threats Open signatures match the scan's exact timing and packet characteristics - a quiet `-sV -sC` scan may not always trip a dedicated "port scan" signature, but the traffic itself (`event_type: flow` and `event_type: stats` entries) is captured either way.

### Verify in the SIEM

In the Wazuh dashboard, Discover view:
```
agent.name: "honeypot" AND rule.groups: "suricata"
```

---

## A note on scope

This lab currently demonstrates two scenarios against a single honeypot service (Cowrie/SSH). Earlier planning considered a broader set (web application attacks against Glastopf, malware capture via Dionaea, ICS/SCADA via Conpot) - these were intentionally left out of this version to keep the lab's resource footprint and complexity manageable. Extending the lab with an additional honeypot service (e.g. a lightweight web honeypot) would be a reasonable next step and would follow the same pattern: add the service to `honeypot.sh`, add a corresponding script to `attack-scripts/`, and document the scenario here.
