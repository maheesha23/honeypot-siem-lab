# Honeypot SIEM Lab (Offline / VM-Isolated)

A fully self-contained honeypot and SIEM lab built entirely with **free and open-source tools**, designed to run inside isolated virtual machines on a single host — **no real internet exposure required**.

This project deploys a working honeypot service, a network intrusion detection engine, and a SIEM pipeline that captures and displays attacker behavior — reproducible from a single `vagrant up`.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quickstart](#quickstart)
- [Repository Structure](#repository-structure)
- [Attack Scenarios](#attack-scenarios)
- [MITRE ATT&CK Mapping](#mitre-attck-mapping)
- [Sample Findings](#sample-findings)
- [Ethical Use Statement](#ethical-use-statement)
- [License](#license)

---

## Overview

This lab deploys a honeypot service inside an isolated virtual network, generates realistic attacker traffic from a dedicated attacker VM, and feeds all captured activity into a SIEM pipeline for analysis.

**Key goals:**
- Demonstrate a real SSH/Telnet honeypot deployment with full session logging
- Detect and log network-layer attack traffic with an IDS
- Centralize both into a SIEM with agent-based log forwarding
- Map observed attacker behavior to MITRE ATT&CK techniques
- Keep the entire lab reproducible, offline, and free to run

**Tech stack:**

| Component | Tool |
|---|---|
| Honeypot | Cowrie (SSH/Telnet), full session and credential logging |
| Network IDS | Suricata, running the Emerging Threats Open ruleset |
| SIEM | Wazuh (indexer + manager + dashboard, all-in-one) |
| Attack simulation | Hydra (brute force), Nmap (service/port scanning) |
| Environment automation | Vagrant + VirtualBox |
| Technique mapping | MITRE ATT&CK (manual mapping, see `docs/mitre-mapping.md`) |

---

## Architecture

```
                     ┌────────────────────────┐
                     │   Attacker VM          │
                     │   (Hydra, Nmap)        │
                     └───────────┬────────────┘
                                 │  (Internal Network only)
                     ┌───────────▼────────────┐
                     │   Honeypot VM          │
                     │   Cowrie (SSH/Telnet)  │
                     │   Suricata (IDS)       │
                     └───────────┬────────────┘
                                 │  logs (Wazuh agent)
                     ┌───────────▼────────────┐
                     │  Monitoring VM         │
                     │  Wazuh SIEM            │
                     │  (indexer/manager/     │
                     │   dashboard)           │
                     └────────────────────────┘
```

All VMs communicate over a Vagrant **private network** (`192.168.56.0/24`) that does not route to your real LAN or the internet. Each VM also keeps its default NAT adapter for provisioning-time internet access only (installing packages). See [`docs/architecture.md`](docs/architecture.md) for full design rationale.

---

## Prerequisites

- [VirtualBox](https://www.virtualbox.org/) (free)
- [Vagrant](https://www.vagrantup.com/) (free)
- Host machine: 12GB+ RAM recommended (the monitoring VM alone needs 4GB for Wazuh's indexer)
- ~40GB free disk space across all VMs

---

## Quickstart

```bash
git clone https://github.com/maheesha23/honeypot-siem-lab.git
cd honeypot-siem-lab/vagrant

# Bring up all three VMs (attacker, honeypot, monitoring)
vagrant up

# SSH into the attacker VM to run a scenario
vagrant ssh attacker
cd /vagrant/attack-scripts
./brute_force.sh

# View the SIEM dashboard at https://192.168.56.30/
# (self-signed certificate - browser warning is expected)
# Credentials: see the monitoring VM provisioning output, or:
#   sudo tar -xf /root/wazuh-install-files.tar -C /root/
#   sudo cat /root/wazuh-install-files/wazuh-passwords.txt
```

Full step-by-step instructions, including troubleshooting for common issues: [`docs/setup-guide.md`](docs/setup-guide.md)

---

## Repository Structure

```
honeypot-siem-lab/
├── README.md
├── LICENSE
├── .gitignore
├── .gitattributes
├── docs/
│   ├── architecture.md       # Network design and diagrams
│   ├── setup-guide.md        # Full setup walkthrough + troubleshooting
│   ├── attack-scenarios.md   # Scripted attacks and expected results
│   └── mitre-mapping.md      # ATT&CK technique mapping table
├── vagrant/
│   ├── Vagrantfile
│   └── provision/
│       ├── honeypot.sh       # Installs Cowrie + Suricata + Wazuh agent
│       ├── monitoring.sh     # Installs Wazuh all-in-one SIEM
│       └── attacker.sh       # Installs attack tooling
├── configs/
│   ├── cowrie.cfg            # Empty by design - see setup-guide.md
│   ├── suricata.yaml         # Empty by design - see setup-guide.md
│   └── wazuh-rules/
├── attack-scripts/
│   ├── brute_force.sh        # SSH brute force against Cowrie
│   └── port_scan.sh          # Nmap service scan against the honeypot
├── sample-logs/               # Sanitized example output
└── screenshots/               # Dashboard and result screenshots
```

---

## Attack Scenarios

Each scenario is scripted and repeatable. See [`docs/attack-scenarios.md`](docs/attack-scenarios.md) for full details and expected log output.

| Scenario | Script | Target | MITRE Technique |
|---|---|---|---|
| SSH brute force | `attack-scripts/brute_force.sh` | Cowrie (port 2222) | T1110 - Brute Force |
| Network/service scan | `attack-scripts/port_scan.sh` | Honeypot VM | T1046 - Network Service Discovery |

---

## MITRE ATT&CK Mapping

Captured behaviors are tagged against MITRE ATT&CK techniques to give the raw logs security context. Full table in [`docs/mitre-mapping.md`](docs/mitre-mapping.md).

| Observed Behavior | Technique ID | Tactic |
|---|---|---|
| SSH credential brute forcing | T1110 | Credential Access |
| Network service scanning | T1046 | Discovery |

---

## Sample Findings

Sanitized log excerpts from real attack runs are available in [`sample-logs/`](sample-logs/). Dashboard screenshots will be added to [`screenshots/`](screenshots/) as the lab is run through further scenarios.

---

## Ethical Use Statement

This lab is built for **educational and defensive security research purposes only**. All attack simulations are run against isolated, self-owned virtual machines with no route to the internet or any third-party system. Do not point any tools or techniques referenced in this repository at systems you do not own or have explicit authorization to test.

---

## License

This project is licensed under the [MIT License](LICENSE).
