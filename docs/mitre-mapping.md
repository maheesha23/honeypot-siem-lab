# MITRE ATT&CK Mapping

This table maps behavior actually captured by this lab to MITRE ATT&CK techniques. Only techniques with real, reproducible evidence from `docs/attack-scenarios.md` are listed.

| Technique | ID | Tactic | Evidence Source | How it's captured |
|---|---|---|---|---|
| Brute Force | [T1110](https://attack.mitre.org/techniques/T1110/) | Credential Access | Cowrie (`cowrie.json`) | `cowrie.login.failed` / `cowrie.login.success` events log every credential pair attempted against the SSH honeypot |
| Network Service Discovery | [T1046](https://attack.mitre.org/techniques/T1046/) | Discovery | Suricata (`eve.json`) | Flow and stats events capture the scanning traffic pattern; specific Emerging Threats Open signatures may also fire depending on scan technique |

## Methodology

Mapping is done manually by cross-referencing:
1. The attack technique actually executed (e.g. `hydra` running an SSH credential-stuffing attack)
2. The corresponding MITRE ATT&CK technique ID and tactic from the [MITRE ATT&CK Enterprise Matrix](https://attack.mitre.org/matrices/enterprise/)
3. The specific log event(s) in this lab's captured data that evidence that technique

This is intentionally a small, honest table rather than an exhaustive one - every row here can be reproduced by running the corresponding script in `attack-scripts/` and inspecting the resulting logs.

## Extending this table

Adding a new mapped technique requires three things in place: a script in `attack-scripts/` that performs the technique, a corresponding entry in `docs/attack-scenarios.md` describing expected results, and a row here linking the two to the correct MITRE technique ID.
