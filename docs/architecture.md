# Architecture

## Topology

```
                     ┌───────────────────────┐
                     │   Attacker VM         │
                     │   192.168.56.10       │
                     │   (Hydra, Nmap)       │
                     └───────────┬───────────┘
                                 │  private network only
                     ┌───────────▼───────────┐
                     │   Honeypot VM         │
                     │   192.168.56.20       │
                     │   Cowrie (SSH/Telnet) │
                     │   Suricata (IDS)      │
                     │   Wazuh agent         │
                     └───────────┬───────────┘
                                 │  agent forwards logs
                     ┌───────────▼───────────┐
                     │  Monitoring VM        │
                     │  192.168.56.30        │
                     │  Wazuh indexer        │
                     │  Wazuh manager        │
                     │  Wazuh dashboard      │
                     └───────────────────────┘
```

## Network design

All three VMs sit on a Vagrant **private network** (`192.168.56.0/24`), configured via VirtualBox's private networking. This network:

- Is reachable between the three VMs and from the host machine
- Does **not** route to the host's real LAN
- Does **not** expose any honeypot service to the public internet

Each VM additionally keeps its default NAT adapter, but that adapter is used exclusively during provisioning (`apt-get`, `pip`, `curl`) to install software. No honeypot service is bound to or reachable via the NAT adapter.

This design was a deliberate choice: the lab is fully reproducible and safe to run on a personal laptop, with zero risk of exposing a real (if simulated) attack surface to the actual internet - at the cost of not seeing genuine, unsolicited internet attacker traffic. All attack traffic in this lab is generated intentionally by the `attacker` VM.

## Why Cowrie + Suricata instead of a full honeypot platform (e.g. T-Pot)

T-Pot bundles 20+ honeypot services but requires 16GB+ RAM, which is impractical for a reproducible Vagrant lab meant to run on a typical laptop. This lab instead runs Cowrie (a mature, widely-used SSH/Telnet honeypot) directly, alongside Suricata for network-layer detection. This keeps the resource footprint small (the honeypot VM runs comfortably in 3GB) while still producing realistic, richly-detailed attack data - Cowrie logs full session lifecycles, credential attempts, and even SSH client fingerprinting (hassh).

## Why Wazuh instead of a raw ELK stack

Wazuh bundles an OpenSearch-based indexer, a manager with built-in decoders/rules, and a dashboard into a single installer. This gets a functioning SIEM up in one script rather than manually wiring together Elasticsearch, Logstash, and Kibana separately. The trade-off is that Wazuh's default ruleset doesn't ship dedicated decoders for Cowrie's or Suricata's specific JSON schemas out of the box - logs are ingested and searchable, but won't generate polished, scored alerts without custom decoder/rule work (see `configs/wazuh-rules/` for where that would go).

## Data flow

1. `attacker` VM runs a scripted attack (SSH brute force via Hydra, or an Nmap service scan) against `honeypot`.
2. Cowrie logs the full SSH session lifecycle to `cowrie.json`; Suricata inspects the same traffic at the network layer and logs to `eve.json`.
3. The Wazuh agent on `honeypot` (configured via `<localfile>` blocks in `ossec.conf`) tails both log files and forwards new entries to the Wazuh manager on `monitoring`.
4. The manager indexes the data via the Wazuh indexer, making it searchable in the dashboard's Discover view.

## VM resource allocation

| VM | RAM | Reasoning |
|---|---|---|
| `attacker` | 2GB | Lightweight - just Hydra, Nmap, and supporting tools |
| `honeypot` | 3GB | Suricata's rule compilation (~52,000 rules) needs headroom; 2GB caused an out-of-memory crash during testing |
| `monitoring` | 4GB | Wazuh's indexer (OpenSearch-based) is the most memory-hungry component in the stack |
