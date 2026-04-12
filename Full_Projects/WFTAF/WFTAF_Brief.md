# WFTAF: Windows Forensic Triage & Analysis Framework

**Author:** William Richardson
**Status:** Active Development — Phase 2: Detection-as-Code & Sigma Integration
**Research Focus:** Detection Engineering, Hybrid-Cloud Security & Adversarial TTPs

---

## Overview

WFTAF is a modular **Detection-as-Code (DaC)** framework designed to bridge the gap between raw Windows forensic artefacts and automated, vendor-neutral threat detection.

Traditional triage tools aggregate data. WFTAF **detects intent** — normalising Windows telemetry into a Sigma-compatible schema and executing rule-based logic against it to surface adversarial TTPs with surgical precision, without requiring a full SIEM stack.

The framework is persistence-first, targeting **MITRE ATT&CK TA0003** — the tactic most commonly associated with long-dwell intrusions and the hardest to detect with out-of-the-box tooling.

---

## The Problem

Enterprise environments generate enormous volumes of Windows telemetry. Existing detection pipelines depend on:

- **Vendor lock-in** — rules written for Splunk, Sentinel, or Elastic rarely port cleanly
- **SIEM dependency** — full ingestion pipelines required before any detection logic can run
- **Low fidelity** — broad event log monitoring with high false-positive rates

WFTAF addresses this by decoupling **data collection**, **normalisation**, and **detection logic** into independent, interoperable modules — allowing detections to run directly against forensic artefacts, on-host or off.

---

## Detection Engineering Pipeline

```
┌─────────────────────┐
│  Modular Acquisition │  PowerShell collectors target high-value persistence
│  (PowerShell/JSON)  │  artefacts: Registry, Scheduled Tasks, WMI, Services
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  OSSEM Normalisation │  Raw telemetry mapped to OSSEM field standard —
│  (Python)           │  ensuring Sigma field-level compatibility
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  Sigma Match Engine  │  Python engine ingests .yml Sigma rules and executes
│  (Python/YAML)      │  detection logic against normalised JSON output
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  Validation          │  Atomic Red Team simulations verify detection recall
│  (Atomic Red Team)  │  and benchmark false-positive rates per TTP
└─────────────────────┘
```

---

## Core Features

**Persistence-First Detection Scope**
Deep analysis of TA0003 targeting stealthy entry points including WMI Event Subscriptions, Registry Run Keys, and Service manipulation — artefacts frequently missed by endpoint tooling configured for breadth over depth.

**Sigma-Ready Telemetry**
PowerShell collectors output JSON with field names pre-mapped to the Sigma standard (`Image`, `ParentCommandLine`, `CommandLine` etc.) — no post-processing required before rule execution.

**Vendor-Neutral by Design**
Detection logic is expressed entirely in Sigma YAML. New detections are added by dropping a rule file into `/rules` — no code changes, no proprietary query language, no SIEM dependency.

**Atomic Red Team Validated**
Each detection is benchmarked against the corresponding Atomic Red Team test case, providing measurable recall rates and ensuring detections hold against realistic adversary simulation — not just synthetic data.

**Enterprise-Scale Acquisition**
Collectors are designed for low-overhead deployment across large environments (~4,500+ endpoints), prioritising targeted artefact collection over full disk imaging.

---

## Project Structure

| Component | Description | Stack |
|---|---|---|
| `/Modules` | Artefact-specific collectors — Registry, Scheduled Tasks, WMI, Services, Process | PowerShell → JSON |
| `/Engine` | Normalisation layer and Sigma rule matching engine | Python (YAML/JSON) |
| `/Rules` | MITRE-mapped Sigma rule library, persistence-focused | YAML |
| `/Lab` | Atomic Red Team test cases and validation scripts | PowerShell / Bash |
| `/Docs` | Field mapping reference, OSSEM alignment documentation | Markdown |

---

## Detection Scope — Initial TTP Coverage

| Technique | Description |
|---|---|
| T1547.001 | Boot or Logon Autostart Execution — Registry Run Keys / Startup Folder |
| T1053.005 | Scheduled Task/Job — Scheduled Task creation and modification |
| T1543.003 | Create or Modify System Process — Windows Services |
| T1546.003 | Event Triggered Execution — WMI Event Subscription |

Each technique maps to one or more Sigma rules in `/rules` and a corresponding Atomic Red Team test case in `/lab` for end-to-end validation.

---

## Roadmap

- [x] **Phase 1** — Modular PowerShell collectors for core persistence artefacts
- [ ] **Phase 2** — Python normalisation layer with full OSSEM/Sigma field mapping
- [ ] **Phase 3** — Sigma match engine — ingest and execute YAML rule logic against normalised output
- [ ] **Phase 4** — Atomic Red Team validation suite — recall benchmarking per TTP
- [ ] **Phase 5** — Cross-platform expansion — AWS CloudTrail telemetry mapping and rule portability

---

## Design Principles

**Modularity over monolith** — each pipeline stage is independently executable and replaceable.

**Standards over proprietary formats** — OSSEM normalisation and Sigma rules ensure the framework's output is immediately useful in any downstream tooling.

**Evidence over noise** — artefact selection is deliberate. WFTAF collects what matters for persistence detection, not everything available.

**Validation as a first-class concern** — detection engineering without measured recall rates is guesswork. Atomic Red Team integration is a core requirement, not an afterthought.
