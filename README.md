# Industrial Honeypot Lab (Offline / VM-Isolated)

A fully self-contained honeypot and SIEM lab built entirely with **free and open-source tools**, designed to run inside isolated virtual machines on a single host — **no real internet exposure required**.

This project simulates an industrial-style security operations setup: multiple honeypot services, centralized log aggregation, threat intelligence enrichment, and attacker behavior mapped to the **MITRE ATT&CK** framework — all reproducible from a single `vagrant up`.

> **Status:** Work in progress. This repository is currently private during development and will be made public once the lab is fully tested and documented.

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
- [Roadmap](#roadmap)
- [Ethical Use Statement](#ethical-use-statement)
- [License](#license)

---

## Overview

This lab deploys a network of honeypot services inside an isolated virtual network, generates realistic attacker traffic from a dedicated attacker VM, and feeds all captured activity into a SIEM pipeline for analysis and visualization.

**Key goals:**
- Demonstrate a multi-service honeypot deployment (SSH/Telnet, web, malware capture, ICS/SCADA)
- Centralize and correlate logs through an open-source SIEM
- Enrich captured indicators (IPs, hashes) using free threat intelligence feeds
- Map observed attacker behavior to MITRE ATT&CK techniques
- Keep the entire lab reproducible, offline, and free to run

**Tech stack:**

| Component | Tool |
|---|---|
| Honeypot suite | T-Pot (Cowrie, Dionaea, Glastopf, Conpot, Suricata) |
| SIEM / log pipeline | ELK Stack / OpenSearch + Wazuh |
| Threat intel enrichment | AbuseIPDB, AlienVault OTX, VirusTotal (free tiers) |
| Attack simulation | Kali Linux, Hydra, Nmap, Nikto, SQLmap, MITRE Caldera |
| Environment automation | Vagrant + VirtualBox |
| Technique mapping | MITRE ATT&CK Navigator |

---

## Architecture

```
                     ┌────────────────────────┐
                     │   Attacker VM (Kali)   │
                     └───────────┬────────────┘
                                 │  (Internal Network only)
                     ┌───────────▼────────────┐
                     │   Honeypot VM (T-Pot)  │
                     │  Cowrie / Dionaea /    │
                     │  Glastopf / Conpot /   │
                     │      Suricata          │
                     └───────────┬────────────┘
                                 │  logs
                     ┌───────────▼────────────┐
                     │  Monitoring VM         │
                     │  ELK / Wazuh SIEM      │
                     │  + Threat Intel Enrich │
                     └───────────┬────────────┘
                                 │
                     ┌───────────▼────────────┐
                     │ Dashboards + MITRE     │
                     │ ATT&CK Mapping         │
                     └────────────────────────┘
```

All VMs communicate over a VirtualBox **Internal Network** (`honeynet`) with no route to the host's real LAN or the internet. See [`docs/architecture.md`](docs/architecture.md) for full network diagrams and design rationale.

---

## Prerequisites

- [VirtualBox](https://www.virtualbox.org/) (free) or VMware Workstation Player (free for personal use)
- [Vagrant](https://www.vagrantup.com/) (free)
- Host machine: 16GB+ RAM recommended (8GB minimum with a slimmed-down honeypot profile)
- ~60GB free disk space across all VMs

---

## Quickstart

```bash
git clone https://github.com/<your-username>/honeypot-siem-lab.git
cd honeypot-siem-lab/vagrant

# Bring up all three VMs (attacker, honeypot, monitoring)
vagrant up

# SSH into the attacker VM to run a scenario
vagrant ssh attacker
cd /vagrant/attack-scripts
./brute_force.sh

# View the SIEM dashboard
# (Kibana/Wazuh URL and default credentials printed at end of provisioning)
```

Full step-by-step instructions: [`docs/setup-guide.md`](docs/setup-guide.md)

---

## Repository Structure

```
honeypot-siem-lab/
├── README.md
├── LICENSE
├── .gitignore
├── docs/
│   ├── architecture.md       # Network design and diagrams
│   ├── setup-guide.md        # Full setup walkthrough
│   ├── attack-scenarios.md   # Scripted attacks and expected results
│   └── mitre-mapping.md      # ATT&CK technique mapping table
├── vagrant/
│   ├── Vagrantfile
│   └── provision/
│       ├── honeypot.sh       # Installs T-Pot / Cowrie / Dionaea
│       ├── monitoring.sh     # Installs ELK / Wazuh
│       └── attacker.sh       # Installs Kali attack tooling
├── configs/
│   ├── cowrie.cfg
│   ├── suricata.yaml
│   └── wazuh-rules/
├── attack-scripts/
│   ├── brute_force.sh
│   ├── port_scan.sh
│   └── sqli_test.py
├── sample-logs/               # Sanitized example output
└── screenshots/               # Dashboard and result screenshots
```

---

## Attack Scenarios

Each scenario is scripted and repeatable, so results are consistent for anyone running the lab. See [`docs/attack-scenarios.md`](docs/attack-scenarios.md) for full details.

| Scenario | Script | Target Honeypot | Technique |
|---|---|---|---|
| SSH brute force | `attack-scripts/brute_force.sh` | Cowrie | Credential Access |
| Network/service scan | `attack-scripts/port_scan.sh` | All | Discovery |
| Web SQL injection | `attack-scripts/sqli_test.py` | Glastopf | Initial Access |
| Malware drop simulation | (Caldera profile) | Dionaea | Execution |

---

## MITRE ATT&CK Mapping

Captured behaviors are tagged against MITRE ATT&CK techniques to give the raw logs security context. Full table in [`docs/mitre-mapping.md`](docs/mitre-mapping.md).

| Observed Behavior | Technique ID | Tactic |
|---|---|---|
| SSH credential brute forcing | T1110 | Credential Access |
| Network service scanning | T1046 | Discovery |
| Exploitation of web application | T1190 | Initial Access |
| Command execution post-compromise | T1059 | Execution |

---

## Sample Findings

Dashboard screenshots and sanitized log excerpts are available in [`screenshots/`](screenshots/) and [`sample-logs/`](sample-logs/) once the lab has been run through its first full scenario pass.

---

## Roadmap

- [ ] Finalize Vagrant provisioning scripts
- [ ] Complete Wazuh rule tuning for honeypot log sources
- [ ] Integrate free threat intel enrichment script
- [ ] Run full attack scenario pass and capture sample logs
- [ ] Write up MITRE ATT&CK mapping results
- [ ] Record demo walkthrough
- [ ] Make repository public

---

## Ethical Use Statement

This lab is built for **educational and defensive security research purposes only**. All attack simulations are run against isolated, self-owned virtual machines with no route to the internet or any third-party system. Do not point any tools or techniques referenced in this repository at systems you do not own or have explicit authorization to test.

---

## License

This project is licensed under the [MIT License](LICENSE).
