# n00b_hunter 🎯

> **Red & Blue Team Field Notes** — An interactive terminal reference for offensive and defensive security operations.

[![Python](https://img.shields.io/badge/Python-3.8%2B-blue?style=flat-square&logo=python)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey?style=flat-square)]()
[![Version](https://img.shields.io/badge/Version-3.5-red?style=flat-square)]()
[![Community](https://img.shields.io/badge/For-Pentesters%20%7C%20Red%20Teams%20%7C%20Blue%20Teams%20%7C%20CTF-orange?style=flat-square)]()

```
  ███╗   ██╗ ██████╗  ██████╗ ██████╗     ██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗
  ████╗  ██║██╔═████╗██╔═████╗██╔══██╗    ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗
  ██╔██╗ ██║██║██╔██║██║██╔██║██████╔╝    ███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝
  ██║╚██╗██║████╔╝██║████╔╝██║██╔══██╗    ██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗
  ██║ ╚████║╚██████╔╝╚██████╔╝██████╔╝    ██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║
  ╚═╝  ╚═══╝ ╚═════╝  ╚═════╝ ╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
```

---

## 📖 What is n00b_hunter?

**n00b_hunter** is a terminal-based, interactive field reference tool built for penetration testers, red teamers, blue teamers, and security analysts. It puts thousands of attack techniques, defensive detections, and methodology checklists at your fingertips — organized, searchable, and tied to real engagement sessions.

Whether you're mid-engagement and need the exact syntax for a Kerberoasting command, hunting for a Sysmon detection rule, or working through a red team methodology checklist — n00b_hunter keeps you moving without breaking your flow.

It is **not** an automated attack tool. It is a **knowledge base and workflow companion**.

---

## ✨ Features

### 🔴 Offensive TTP Library

Browse and search **2,257 commands** across **18 attack modules**, each with MITRE ATT&CK IDs:

| Module | Sections | Commands | Coverage |
|--------|----------|----------|----------|
| `Active Directory` | 32 | 193 | Kerberoasting, AS-REP roasting, DCSync, ACL abuse, Golden/Silver Ticket, AD CS (ESC1–8), RBCD, ADIDNS takeover, BloodHound, LAPS, Trust attacks |
| `Web Application` | 36 | 189 | SQLi, XSS, SSRF, XXE, SSTI, deserialization, HTTP smuggling, WAF bypass, broken access control, auth bypass, CMS exploitation |
| `Android` | 29 | 160 | APK reversing, ADB exploitation, Frida hooking, backup abuse, deep link URI attacks, certificate pinning bypass, intent hijacking |
| `Social Media Offensive` | 19 | 140 | LinkedIn recon, Twitter/X OSINT, Discord/Telegram C2, Slack/Teams corporate messaging, AI deepfake social engineering |
| `Linux Systems` | 20 | 133 | SUID/SGID, kernel exploits, polkit/D-Bus abuse, cloud IMDS exploitation, credential hunting, container breakout |
| `Evasion` | 22 | 121 | AMSI bypass, ETW patching, EDR unhooking, direct syscalls, process injection, credential guard bypass, opsec tradecraft |
| `Windows Systems` | 16 | 118 | Privesc, LSASS evasion, browser credential extraction, service misconfiguration, WMI persistence, COM hijacking |
| `Amazon Web Services` | 21 | 107 | IAM privesc paths, GuardDuty evasion, Lambda Function URL abuse, S3, EC2, CloudTrail evasion |
| `Containers & Kubernetes` | 18 | 98 | Docker escape, K8s RBAC escalation, image supply chain attacks, etcd extraction, Helm secrets |
| `Database Attacks` | 18 | 98 | MSSQL, MySQL, PostgreSQL, cloud managed DB attacks, credential exfiltration, Redis, MongoDB |
| `Google Cloud` | 19 | 96 | IAM, service account impersonation, compute metadata exploitation, GKE, Cloud Run, BigQuery |
| `Network Infrastructure` | 14 | 91 | NTLM relay, LLMNR/NBT-NS poisoning, ARP MITM, VLAN hopping, DNS attacks, wireless, IPv6 |
| `Artificial Intelligence` | 20 | 90 | Prompt injection, RAG poisoning, function calling abuse, LLM API key exposure, agent hijacking, supply chain ML |
| `Microsoft Azure` | 17 | 86 | AAD, conditional access bypass, managed identity abuse, Azure OpenAI abuse, DevOps pipelines, Key Vault |
| `Social Engineering` | 13 | 74 | BEC, callback phishing (TOAD), phishing, spear phishing, vishing, watering hole, physical access |
| `Cobalt Strike C2` | 14 | 152 | Beacon configuration, malleable profiles, lateral movement, persistence, OPSEC settings, evasion |
| `Sliver C2` | 14 | 167 | Implant generation, multiplayer ops, armory extensions, lateral movement, traffic manipulation |
| `Havoc C2` | 14 | 144 | Demon agent, team server setup, post-exploitation modules, evasion, lateral movement |

---

### 🔵 Defensive Detection Library

**2,024 detection queries** across two libraries — SOC SIEM and Threat Hunting — each covering five platforms. All detection categories are mapped to MITRE ATT&CK technique IDs.

#### SOC SIEM — Alert detection and triage queries

| Platform | Sections | Commands | Coverage |
|----------|----------|----------|----------|
| **Wireshark / TCPDump** | 55 | 263 | Packet capture filters — Discord/Telegram C2, AI API exfil, 34 attack patterns |
| **Splunk (SPL)** | 46 | 207 | RBCD, PwnKit/IMDS, BEC/M365, AI service abuse, Windows Security, Sysmon |
| **Azure KQL (Sentinel)** | 51 | 218 | ESC8, ADIDNS, managed identity IMDS abuse, Azure AD, Windows, cloud threats |
| **Elastic (KQL/EQL)** | 43 | 177 | GCP threats, RBCD/ADIDNS, AI/LLM abuse, BEC/M365, full ECS-mapped queries |
| **PowerShell** | 10 | 126 | RBCD/ADCS detection, BEC/M365 inbox rules, `Get-WinEvent` cheat sheet |
| **Total** | **205** | **991** | |

#### Threat Hunting — Proactive hunt query library

| Platform | Sections | Commands | Coverage |
|----------|----------|----------|----------|
| **Splunk (SPL)** | 38 | 438 | RBCD chains, PwnKit, GuardDuty/Lambda abuse, full-spectrum statistical hunts |
| **Elastic (KQL)** | 42 | 195 | RBCD/ADIDNS, PwnKit/polkit, Discord/Telegram C2, ECS-mapped Sysmon fields |
| **PowerShell** | 36 | 160 | ADIDNS wildcard hunting, IMDS/cloud credential hunting, `Get-WinEvent` scripts |
| **Wireshark / TCPDump** | 26 | 126 | Discord/Telegram C2, AI API exfil traffic, network-level threat hunts |
| **Azure Sentinel (KQL)** | 32 | 114 | RBCD/delegation, AWS GuardDuty/Lambda, TOAD/callback phishing, Sysmon coverage |
| **Total** | **170** | **1,033** | |

Full Sysmon event ID coverage across all platforms:

> `Sysmon 1` (Process Create) · `3` (Network) · `6` (Driver Load/BYOVD) · `7` (Image Load/DLL hijack) · `8` (CreateRemoteThread) · `10` (ProcessAccess/LSASS) · `11` (FileCreate) · `13` (Registry) · `15` (ADS) · `17/18` (Named Pipe/C2) · `19/20/21` (WMI persistence) · `22` (DNS Query) · `25` (Process Tampering)

---

### 🟡 Methodology Checklists

Interactive, trackable checklists with per-step toggle, progress counters, and engagement persistence:

#### Offensive / Pentest Methodologies (8)

| Checklist | Coverage |
|-----------|----------|
| **Red Team Operations** | 7 phases — RoE → infra → initial access → post-ex → cleanup |
| **Purple Team Validation** | 10 phases — planning → TTP execution → gap remediation → reporting |
| **Active Directory** | Full AD attack chain — recon → kerberos → privesc → DA |
| **Web App & API** | Full OWASP-aligned methodology |
| **Internal Network** | Pivot → recon → VLAN → infrastructure → lateral movement |
| **Cloud** | AWS/Azure/GCP unified methodology |
| **Mobile (Android & iOS)** | Static + dynamic + network testing (51 steps) |
| **Systems** | Windows/Linux internal attack methodology |

#### Defensive Methodologies (5)

| Checklist | Coverage |
|-----------|----------|
| **SOC Tier 1** | Alert triage, initial classification, escalation decision tree |
| **SOC Tier 2** | Incident investigation, containment, evidence collection |
| **Threat Hunting** | 8-phase hunt methodology — hypothesis → data collection → active hunting → closure |
| **Incident Response** | IR playbooks and structured report template |
| **Purple Team** | Blue-side TTP validation and detection gap remediation |

Every step can be toggled complete, progress auto-saves to your engagement file, and can be exported to a Markdown report.

---

### 🔍 Search — Global and Section-Scoped

v3.2 introduces **multi-level search** with AND logic and keyword highlighting at every menu depth:

| Search Level | How to Access | Scope |
|---|---|---|
| **Global** | `[4]` from main menu, or `./n00b_hunter.py <term>` | All offensive + all SIEM + all hunt |
| **Defensive (combined)** | `[s]` in Defensive menu | SOC SIEM + Threat Hunting combined |
| **SOC SIEM (cross-platform)** | `[s]` in SOC SIEM platform list | All 5 SIEM platforms at once |
| **Threat Hunting (cross-platform)** | `[s]` in Threat Hunting platform list | All 5 hunt platforms at once |
| **Offensive (cross-module)** | `[s]` in Offensive module list | All 15 offensive modules |
| **Per-platform** | `[s]` in any technique list | Within that single platform file |
| **Per-module** | `[s]` in any offensive category | Within that single module |

**Multi-keyword AND logic** — all space-separated keywords must appear in the result:

```
lsass sysmon           → entries containing BOTH "lsass" AND "sysmon"
4769 kerberoast        → Kerberoasting detection entries
EventCode=10 lsass     → LSASS access queries by EventCode
named pipe cobalt      → Cobalt Strike named pipe C2 detections
```

EventID and EventCode search works natively in all modes — no special syntax required.

---

### 📋 Engagement Manager

- Create named engagements (e.g. `ClientName_Internal_2025`)
- All progress, notes, and search history auto-persist per engagement file
- Switch between active engagements instantly
- Most recent engagement auto-loads on startup

### 📝 Per-Technique Notes

- Attach notes to any offensive or defensive technique
- Notes display inline when viewing that technique
- Note count indicators on module and category menus

### 📄 Export

- **Markdown report**: notes by technique + completed checklist steps + search history
- **Notes TXT**: plain-text dump of all engagement notes
- Export to `engagements/` folder for sharing or archiving

---

## 🚀 Quick Start

### Requirements

- Python 3.8+
- No external dependencies — pure standard library

### Installation

```bash
git clone https://github.com/yourusername/n00b_hunter.git
cd n00b_hunter
python3 n00b_hunter.py
```

### CLI Quick-Search

Jump straight to global search results without entering the menu:

```bash
python3 n00b_hunter.py lsass
python3 n00b_hunter.py kerberoast 4769
python3 n00b_hunter.py named pipe cobalt
```

### CLI Flags

**`--list`** — Dump all offensive techniques as TSV (scriptable, pipeable):

```bash
# List all techniques
python3 n00b_hunter.py --list

# Filter by keyword or MITRE ID
python3 n00b_hunter.py --list kerberos
python3 n00b_hunter.py --list T1558

# Pipe into grep/fzf/cut
python3 n00b_hunter.py --list | grep 'ACTIVE DIRECTORY'
python3 n00b_hunter.py --list | fzf
```

Output columns: `technique_name  mitre_id  method  module`

**`--export-json`** — Export current engagement data as JSON:

```bash
python3 n00b_hunter.py --export-json
python3 n00b_hunter.py --export-json /tmp/my_engagement.json
```

---

### Directory Structure

```
n00b_hunter/
│
├── n00b_hunter.py                      ← Main script (v3.5)
├── ReamMe.md
│
├── db_offensive/                       ← 18 offensive TTP modules
│   ├── active_directory.json
│   ├── amazon_web_service.json
│   ├── android.json
│   ├── artificial_intelligence.json
│   ├── cobalt_strike_c2.json
│   ├── containers_kubernetes.json
│   ├── database_attacks.json
│   ├── evasion.json
│   ├── google_cloud.json
│   ├── havoc_c2.json
│   ├── linux_systems.json
│   ├── microsoft_azure.json
│   ├── network_infrastructure.json
│   ├── sliver_c2.json
│   ├── social_engineering.json
│   ├── social_media_offensive.json
│   ├── web_application.json
│   └── windows_systems.json
│
├── db_defensive/
│   ├── SOC SIEM/                       ← 5 platform files — detection & alert queries
│   │   ├── Azure KQL.json
│   │   ├── Elastic.json
│   │   ├── powershell.json
│   │   ├── Splunk.json
│   │   └── Wireshark_TCPDump_.json
│   └── Threat Hunting/                 ← 5 platform files — proactive hunt queries
│       ├── Azure Sentinel.json
│       ├── Elastic.json
│       ├── powershell.json
│       ├── Splunk.json
│       └── Wireshark-tcpdump.json
│
├── db_methodology/
│   ├── offensive/                      ← 8 pentest/red team checklists
│   │   ├── _pentest_report_template.json
│   │   ├── ad_methodology.json
│   │   ├── cloud_methodology.json
│   │   ├── internal_network_methodology.json
│   │   ├── mobile_methodology.json
│   │   ├── red_team_methodology.json
│   │   ├── systems_methodology.json
│   │   └── webapp_api_methodology.json
│   └── defensive/                      ← 5 blue team checklists
│       ├── IR_report_template.json
│       ├── purple_team_methodology.json
│       ├── soc_tier1.json
│       ├── soc_tier2.json
│       └── threat_hunting.json
│
└── engagements/                        ← Auto-created — session files and reports
    ├── ClientName_2025.json
    └── ClientName_2025_report_20250101_120000.md
```

---

## 🎮 Usage

### Navigation

```
Main Menu:
  [1]  Offensive    — Browse attack TTP modules
  [2]  Defensive    — SOC SIEM & Threat Hunting
  [3]  Methodology  — Interactive checklists
  [4]  Search       — Global keyword search  (tip: ./n00b_hunter.py <term>)
  [5]  Engagement   — Manage sessions & notes
  [6]  Export       — Generate Markdown/TXT report
  [0]  Exit

[s] is available at every menu level:
  Offensive module list        → search across ALL 15 offensive modules
  Offensive technique list     → search within that single module
  Defensive menu               → search across SOC SIEM + Threat Hunting combined
  SOC SIEM platform list       → search across ALL 5 SIEM platforms
  Threat Hunting platform list → search across ALL 5 hunt platforms
  Platform technique list      → search within that single platform file
```

### Typical Red Team Workflow

```
1. [5]  Create engagement → "ClientX_External_2025"
2. [3]  Open Red Team Methodology → work through phases as you go
3. [1]  Browse ACTIVE DIRECTORY → [s] "asrep roasting" → find technique
4. [n]  Add note: "Found DA via Kerberoast — hash cracked in 4h"
5. [4]  Search "lsass 4624" to cross-reference with defensive detections
6. [6]  Export Markdown report at engagement end
```

### Typical Blue Team / SOC Workflow

```
1. [2]  Defensive → [s] "dcsync 4662" across all platforms at once
2. [2]  SOC SIEM → Elastic → browse detection categories
3. [3]  Open Threat Hunting methodology → work 8-phase hunt
4. [2]  Threat Hunting → Splunk → [s] "sysmon 17 named pipe"
5. [n]  Note detections that fired / detection gaps found
6. [6]  Export gap report
```

### Typical Threat Hunt Workflow

```
1. [2]  Defensive → Threat Hunting → [s] "BYOVD sysmon 6"
2. [2]  Defensive → [s] "EventCode=10 lsass" across all platforms
3. [3]  Threat Hunting Methodology → Phase 4 Endpoint → Sysmon steps
4. [n]  Note IOCs found per hunt hypothesis
```

---

## 📐 Adding Your Own Modules

Every module is a plain JSON file. Drop a `.json` into the appropriate `db_*` folder and it appears automatically on next launch — no code changes needed.

### Offensive TTP Format

```json
{
  "technique_name": {
    "description": "What this technique does and when to use it.",
    "mitre": "T1003.001",
    "prerequisites": "Access level, tools, or conditions required before using this technique.",
    "opsec": "Noise level, detection risk, and recommendations to reduce footprint.",
    "detection_ref": "Key event IDs, log sources, or detection tools that catch this technique.",
    "commands": [
      {
        "description": "Human-readable description of what this command does.",
        "method": "tool_name",
        "command": "actual_command_with_{placeholders}"
      }
    ]
  }
}
```

### Defensive Detection Format (SOC SIEM / Threat Hunting)

```json
{
  "Detection Category Name": {
    "description": "What this detects and why it matters.",
    "mitre": "T1558.003",
    "tuning": "Practical notes for reducing false positives — thresholds to adjust, accounts to whitelist, correlated data sources.",
    "commands": [
      {
        "description": "What this query catches.",
        "method": "Splunk SPL",
        "command": "index=wineventlog EventCode=4769 | stats count by IpAddress | where count > 5"
      }
    ]
  }
}
```

### Methodology Checklist Format

```json
{
  "checklist_name": {
    "description": "What this checklist covers.",
    "mitre": "TA0001,TA0004,TA0006,TA0008",
    "phases": [
      {
        "phase": "1. Phase Name",
        "mitre": "TA0043",
        "steps": [
          { "step": "1.1", "status": "[ ]", "task": "Detailed task description" }
        ]
      }
    ]
  }
}
```

---

## 🗂️ Database Stats

| Category | Sections | Commands |
|----------|----------|----------|
| Active Directory | 32 | 193 |
| Web Application | 36 | 189 |
| Android | 29 | 160 |
| Sliver C2 | 14 | 167 |
| Social Media Offensive | 19 | 140 |
| Cobalt Strike C2 | 14 | 152 |
| Linux Systems | 20 | 133 |
| Havoc C2 | 14 | 144 |
| Evasion | 22 | 121 |
| Windows Systems | 16 | 118 |
| Amazon Web Services | 21 | 107 |
| Containers & Kubernetes | 18 | 98 |
| Database Attacks | 18 | 98 |
| Google Cloud | 19 | 96 |
| Network Infrastructure | 14 | 91 |
| Artificial Intelligence | 20 | 90 |
| Microsoft Azure | 17 | 86 |
| Social Engineering | 13 | 74 |
| **Offensive Total** | **356** | **2,257** |
| | | |
| SOC SIEM — Wireshark/TCPDump | 55 | 263 |
| SOC SIEM — Azure KQL | 51 | 218 |
| SOC SIEM — Splunk | 46 | 207 |
| SOC SIEM — Elastic | 43 | 177 |
| SOC SIEM — PowerShell | 10 | 126 |
| **SOC SIEM Total** | **205** | **991** |
| | | |
| Threat Hunting — Splunk | 38 | 438 |
| Threat Hunting — Elastic | 38 | 195 |
| Threat Hunting — PowerShell | 36 | 160 |
| Threat Hunting — Wireshark/TCPDump | 26 | 126 |
| Threat Hunting — Azure Sentinel | 32 | 114 |
| **Threat Hunting Total** | **170** | **1,033** |
| | | |
| Methodology Checklists | 13 checklists | — |
| **GRAND TOTAL** | **731 sections** | **4,281 commands** |

---

## 🛡️ Legal & Ethical Disclaimer

> **This tool is intended for authorized security testing, penetration testing engagements, CTF competitions, and educational purposes only.**

By using n00b_hunter you agree that:

- You have **explicit written authorization** for any systems you test against
- You will not use this tool against systems, networks, or infrastructure you do not own or have permission to test
- The authors are **not responsible** for any misuse, damage, or illegal activity resulting from use of this tool
- All techniques are documented for **educational and defensive awareness purposes**

This tool aggregates publicly documented attack techniques from sources including MITRE ATT&CK, HackTricks, PayloadsAllTheThings, and security research papers. It does not contain exploit code or generate payloads.

**Always get written authorization before testing. Unauthorized access to computer systems is illegal.**

---

## 🤝 Contributing

Contributions are welcome and encouraged. The security community grows stronger through shared knowledge.

### How to Contribute

1. **Fork** the repository
2. **Create a branch**: `git checkout -b feature/new-module-name`
3. **Add your JSON** to the appropriate `db_*` folder
4. **Validate your JSON** before submitting:
   ```bash
   python3 -m json.tool db_offensive/your_module.json
   ```
5. **Submit a Pull Request** with a description of what you added

### Contribution Ideas

- New offensive technique modules (IoT, OT/ICS, macOS, firmware)
- Additional SIEM platform files (QRadar, Chronicle, Sumo Logic)
- Methodology checklists (cloud IR, ransomware response)
- New Windows Event ID or Sysmon detection coverage
- Bug fixes and UX improvements

### Code Style

- Python 3.8+ compatible, zero external dependencies
- Max line length 99 (banner lines suppressed with `# noqa: E501`)
- Follow the existing JSON schema for compatibility
- MITRE ATT&CK IDs required for all techniques — offensive, defensive, and methodology

---

## 📜 Changelog

### v3.5 — Current
- **Full MITRE ATT&CK coverage** — added `"mitre"` field to every technique across all 44 JSON files:
  - **Defensive SOC SIEM** (205 detections): all Splunk, Azure KQL, Elastic, PowerShell, and Wireshark/TCPDump detection categories now carry the ATT&CK technique ID of the threat being detected
  - **Defensive Threat Hunting** (170 hunts): all Splunk, Elastic, PowerShell, Azure Sentinel, and Wireshark hunt queries mapped to ATT&CK technique IDs
  - **Methodology checklists** (13 files): top-level `"mitre"` tactic bundles (e.g. `TA0001,TA0004,TA0006`) added to every checklist; per-phase `"mitre"` tactic IDs added to all phase objects
  - Corrected several incorrect mobile ATT&CK IDs in `android.json` (e.g. SSL pinning → T1553.002, deep links → T1635, Frida → T1625)
  - Corrected BEC and TOAD mapping in `social_engineering.json` (BEC → T1534, callback phishing → T1566.004)
- **C2 Framework modules documented** — added 3 missing modules to README and directory structure:
  - `cobalt_strike_c2.json` — 14 sections, 152 commands
  - `sliver_c2.json` — 14 sections, 167 commands
  - `havoc_c2.json` — 14 sections, 144 commands
- **Defensive format updated** — `"mitre"` field now part of the official defensive JSON schema
- **Methodology format updated** — `"mitre"` field now part of the official checklist JSON schema (checklist-level and phase-level)
- **Stats corrected** — Threat Hunting sections: 174 → 170 (actual file count); grand total updated to 731 sections

### v3.4
- **Methodology review & refinement** — audited all 13 methodology checklists, added targeted steps for modern attack gaps
- **Cloud Methodology** (+5 steps): Lambda Function URL enumeration, AI/ML service enumeration (Bedrock/Azure OpenAI/Vertex), GuardDuty evasion steps, Lambda URL C2 abuse, Azure Defender disable
- **AD Methodology** (+4 steps): ESC2/ESC3 certificate template abuse, Certifried (CVE-2022-26923) domain takeover, RBCD attack via machine account quota
- **Systems Methodology** (+8 steps): Linux — PwnKit/pkexec (CVE-2021-4034), polkit D-Bus rules, Cloud IMDS credential theft, hardcoded cloud key search; Windows — browser credential extraction (SharpChrome/HackBrowserData), Credential Manager dump, service DACL misconfiguration, token privilege abuse
- **Mobile Methodology** (+4 steps): Deep link/URI scheme parameter injection + OAuth redirect hijacking, Fragment injection via exported Activities, ADB backup abuse (Android Backup Extractor), Content Provider SQL injection + path traversal
- **Web App Methodology** (+11 steps): Phase 9 added — full AI/LLM Security Testing (OWASP LLM Top 10): prompt injection, prompt leaking, insecure output handling, tool/function calling abuse, RAG poisoning, LLM API key exposure, vector DB access, model DoS; WAF fingerprinting and bypass techniques
- **Red Team Methodology** (+4 steps): Discord/Telegram social media C2 infrastructure consideration, cloud storage C2 (GitHub/S3/Azure Blob), EDR telemetry OPSEC, API call pattern discipline
- **Purple Team Methodology** (+6 steps): TOAD/callback phishing simulation, BEC executive impersonation, RBCD attack with Event 5136 detection, ADIDNS wildcard injection (Event 5137), GuardDuty filter suppression test, Discord/Telegram C2 network detection test
- **SOC Tier 1 Methodology** (+4 steps): Cloud alert triage (CloudTrail/IMDS/GuardDuty), cloud logging integrity check, BEC/DMARC/inbox rule triage

### v3.3
- **Offensive module review** — audited all 15 modules, removed outdated/impractical techniques, added 40 new sections
- **Active Directory** (+4): RBCD attack, AD CS ESC8 HTTP relay, machine account manipulation, ADIDNS wildcard takeover
- **Windows Systems** (+3): LSASS evasion techniques, browser credential extraction, service misconfiguration privesc
- **Linux Systems** (+3): Polkit/D-Bus abuse (PwnKit), cloud IMDS exploitation (AWS/Azure/GCP), Linux credential hunting
- **Evasion** (+3, -1): EDR unhooking (SysWhispers/Hell's Gate), credential guard bypass, opsec tradecraft; removed `hardware_attacks`
- **Web Application** (+4): Broken access control (IDOR/JWT), authentication bypass (SQLi/MFA/JWT-none), WAF bypass, CMS exploitation
- **Network Infrastructure** (+2): NTLM relay attacks, LLMNR/NBT-NS/mitm6 poisoning
- **AWS** (+3): GuardDuty evasion, Lambda Function URL abuse, IAM privilege escalation paths
- **Azure** (+3): Conditional access bypass (AiTM/legacy auth/device code), managed identity IMDS abuse, Azure OpenAI service abuse
- **Google Cloud** (+2): Service account impersonation (actAs), compute metadata exploitation
- **Containers/K8s** (+2): Kubernetes RBAC escalation, container image supply chain attacks
- **Database** (+2): Cloud managed database attacks (RDS/Azure SQL/GCP), credential exfiltration
- **AI/ML** (+3): LLM API key exposure, function calling tool abuse (indirect injection), RAG pipeline poisoning
- **Android** (+2): ADB backup exploitation, deep link/URI scheme attacks
- **Social Engineering** (+2): BEC attack chain (Evilginx2/o365spray), callback phishing TOAD/BazaCall
- **Social Media** (+1): Discord/Telegram C2 and DM phishing
- **Grand total offensive**: 356 sections, 2,257 commands
- **Defensive audit** — reviewed all 10 defensive files, added 23 new sections covering modern gaps:
  - **Azure KQL SOC** (+3): AD CS ESC8 detection, ADIDNS wildcard injection, managed identity IMDS token abuse
  - **Elastic SOC** (+4): GCP threats (critical gap filled), RBCD/ADIDNS detection, AI/LLM API abuse, BEC/M365 inbox rules
  - **Splunk SOC** (+4): RBCD/Kerberos delegation, Linux IMDS/PwnKit, AI service abuse, BEC/email forwarding
  - **Wireshark SOC** (+2): Discord/Telegram C2 traffic, AI API data exfiltration patterns
  - **PowerShell SOC** (+2): RBCD/AD CS detection (Event 5136/4887), BEC/M365 inbox rules via Exchange Online PS
  - **Azure Sentinel Hunt** (+3): RBCD/delegation attack chains, AWS GuardDuty/Lambda abuse, TOAD/callback phishing
  - **Elastic Hunt** (+3): RBCD/ADIDNS wildcard injection, PwnKit/polkit exploitation, Discord/Telegram C2
  - **Splunk Hunt** (+3): RBCD kill chain, PwnKit/Linux privesc, AWS GuardDuty evasion/Lambda Function URL
  - **Wireshark Hunt** (+2): Discord/Telegram C2 hunt, AI API exfiltration traffic hunt
  - **PowerShell Hunt** (+2): ADIDNS wildcard injection hunting, Cloud IMDS/credential theft hunting
- **Grand total**: 379 defensive sections, 2,024 detection commands; ~4,281 total commands across all modules

### v3.2
- **Section-scoped search** — `[s]` available at every menu level (per-module, per-platform, cross-section)
- **Multi-keyword AND logic** — space-separated terms all must match (e.g. `lsass sysmon 4769`)
- **CLI quick-search** — `./n00b_hunter.py <term>` jumps directly to global results and exits
- **Defensive combined search** — `[s]` in Defensive menu searches SOC SIEM + Threat Hunting together
- **Command match hints** — results show `[N cmd matches]` to prioritize precision hits
- **Keyword highlighting** in `display_def_ttp` — search terms highlighted in commands and descriptions
- **Command count column** added to all technique listing menus
- **Full Sysmon event ID coverage** (1–25) added to Elastic, Splunk, Azure Sentinel Threat Hunting files
- **Windows Event ID reinforcement** — added 4648, 4672, 4673, 4697, 4700, 4702, 4726, 4738, 4778, 5156, 6005/6006, Task Scheduler 106/141/200 across all defensive platforms
- **Social Media Offensive module** added — 18 sections, 135 commands (LinkedIn, Slack/Teams, AI deepfake SE)
- Zero lint errors (PEP8 E302, E501, F541 all resolved)

### v3.1
- Defensive submenu restructure — SOC SIEM and Threat Hunting as separate submenus
- Wireshark & TCPDump module added to both SOC SIEM and Threat Hunting
- Minor UX fixes

### v3.0
- Complete script rewrite
- Engagement management system with session persistence
- Global search across all offensive + defensive modules
- Per-technique notes with inline display
- Markdown/TXT export system
- 6 new offensive modules: Evasion, Containers/K8s, Network, Databases, Social Engineering, AI
- 4 new methodology checklists: Red Team, Purple Team, Internal Network, Mobile
- MITRE ATT&CK IDs added across all techniques
- Defensive expansion: 19 detection categories across Elastic, Splunk, Azure Sentinel

### v2.0
- Dual offensive/defensive mode
- Linux/Windows system TTPs
- Expanded Active Directory techniques
- 5 methodology checklists with interactive progress tracking

### v1.0
- Initial release
- Core Active Directory, Web, Cloud modules
- Basic menu navigation

---

## 📚 Resources & Inspiration

This tool draws from and references the following community resources:

- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [HackTricks](https://book.hacktricks.xyz/)
- [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)
- [GTFOBins](https://gtfobins.github.io/)
- [LOLBAS](https://lolbas-project.github.io/)
- [BloodHound](https://github.com/BloodHoundAD/BloodHound)
- [Impacket](https://github.com/fortra/impacket)
- [The Hacker Recipes](https://www.thehacker.recipes/)
- [ired.team](https://www.ired.team/)
- [Red Team Notes](https://www.redteamnotes.com/)

---

## ⭐ Support the Project

If n00b_hunter helps you in your work or learning, consider:

- ⭐ **Starring** the repository
- 🐛 **Reporting bugs** via Issues
- 📝 **Contributing** new modules or detections
- 📢 **Sharing** with your security community

---

## 📄 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <i>Built for the security community, by the security community.</i><br>
  <i>Hack responsibly. Defend proactively.</i>
</p>
