# WFTAF-v2: Windows Forensic Triage & Analysis Framework

**Author:** William Richardson
**Status:** Active Development — Phase 3: Sigma Detection Engine (In progress, fine details require attention its almost complete)
**Focus:** Detection-as-Code, Windows Persistence (MITRE ATT&CK TA0003), Vendor-Neutral Telemetry Analysis

---

## Overview

WFTAF-v2 is a modular **Detection-as-Code (DaC)** pipeline that bridges the gap between raw Windows host telemetry and structured, actionable threat detection — without requiring a SIEM or any proprietary tooling.

Where traditional triage tools aggregate data broadly, WFTAF targets **adversarial intent** — collecting and normalising only the artefacts most relevant to long-dwell persistence, then executing vendor-neutral Sigma rules against them to surface MITRE ATT&CK techniques with surgical precision.

---

## Pipeline Architecture

```
┌──────────────────────────┐
│         EXTRACT          │
│   Modules/*.ps1          │  Modular PowerShell collectors target high-value
│                          │  persistence artefacts: Registry, Scheduled Tasks,
│                          │  Services, WMI Event Subscriptions
└────────────┬─────────────┘
             │  Output/payload.json  +  SHA-256 integrity seal
             ▼
┌──────────────────────────┐
│        TRANSFORM         │
│   Engine/normalise.py    │  Raw JSON mapped to OSSEM-compatible field schema —
│                          │  Image, CommandLine, TargetObject, Details —
│                          │  ensuring Sigma field-level compatibility
└────────────┬─────────────┘
             │  list[OssemRecord]
             ▼
┌──────────────────────────┐
│          DETECT          │
│  Engine/sigma_engine.py  │  Sigma rule engine loads YAML rules from /Rules
│                          │  and evaluates detection logic against each
│                          │  normalised record
└────────────┬─────────────┘
             │  list[DetectionResult]
             ▼
┌──────────────────────────┐
│          REPORT          │
│        main.py           │  Timestamped JSON detection report written to
│                          │  Output/ with per-technique severity breakdown
└──────────────────────────┘
```

Each stage is independently executable and replaceable. New artefact collectors are added by writing a module and sourcing it in `collector_main.ps1`. New detections are added by dropping a Sigma rule into `/Rules` — no code changes required.

---

## Detection Scope

| Technique | Description | Collector | Rule |
|---|---|---|---|
| T1547.001 | Boot or Logon Autostart — Registry Run Keys | `registry_collector.ps1` | `t1547_001_run_keys.yml` |
| T1053.005 | Scheduled Task/Job | `scheduled_task_collector.ps1` | `t1053_005_scheduled_task.yml` |
| T1543.003 | Create or Modify System Process — Windows Service | `service_collector.ps1` | `t1543_003_services.yml` |
| T1546.003 | Event Triggered Execution — WMI Event Subscription | `wmi_collector.ps1` | `t1546_003_wmi_subscription.yml` |

Each technique maps to a dedicated PowerShell collector, a Sigma rule, and an [Atomic Red Team](https://github.com/redcanaryco/atomic-red-team)-aligned simulation in `/Lab` for end-to-end recall validation.

---

## Project Structure

```
WFTAF-v2/
├── Modules/                          PowerShell artefact collectors
│   ├── collector_main.ps1            Orchestrator — runs all modules, writes JSON + SHA-256
│   ├── registry_collector.ps1        T1547.001 — Run Keys, IFEO, AppInit_DLLs, LSA
│   ├── scheduled_task_collector.ps1  T1053.005 — Tasks with full action and trigger detail
│   ├── service_collector.ps1         T1543.003 — Auto-start services with DLL resolution
│   └── wmi_collector.ps1             T1546.003 — Event filters, consumers, bindings
│
├── Engine/                           Python normalisation and detection
│   ├── schema.py                     Dataclasses for artefact types and OSSEM output
│   ├── normalise.py                  Raw JSON → OSSEM field mapping (Transform)
│   └── sigma_engine.py               YAML rule loader and evaluation engine (Detect)
│
├── Rules/                            Sigma detection rules
│   ├── t1547_001_run_keys.yml
│   ├── t1053_005_scheduled_task.yml
│   ├── t1543_003_services.yml
│   └── t1546_003_wmi_subscription.yml
│
├── Lab/                              Detection validation — ART-aligned simulations
│   ├── simulate_run_key.ps1
│   ├── simulate_scheduled_task.ps1
│   └── simulate_wmi_subscription.ps1
│
├── Docs/
│   └── ossem_field_mapping.md        WFTAF field → OSSEM standard reference
│
├── Output/                           Collector output (gitignored)
└── main.py                           Pipeline entry point
```

---

## Quick Start

### 1. Collect persistence artefacts

```powershell
# Requires administrative privileges
.\Modules\collector_main.ps1
```

Output: `Output/payload.json` + `Output/payload.hash`

### 2. Run the detection pipeline

```bash
pip install -r requirements.txt
python main.py
```

Output: `Output/detections_<timestamp>.json`

### 3. Validate detection recall (lab only)

```powershell
# Simulate a persistence technique, then collect and detect while artefact is live
.\Lab\simulate_run_key.ps1
```

---

## Design Principles

**Extract → Transform → Detect** — each pipeline stage has a single responsibility and a defined interface, communicating via structured JSON. Stages can be swapped independently without modifying adjacent stages.

**Standards over proprietary formats** — OSSEM normalisation and Sigma rules ensure findings are immediately portable to any downstream tooling (Splunk, Sentinel, Elastic) without reprocessing or field remapping.

**Modular collection** — collectors are individual functions, each targeting one technique family. New artefact types are added by writing a new module and sourcing it in the orchestrator.

**Validation as a first-class concern** — detection engineering without measured recall rates is guesswork. Every detection has a corresponding Lab simulation for end-to-end validation. Atomic Red Team test alignment provides a reproducible benchmark.

---

## Roadmap

- [x] **Phase 1** — Modular PowerShell collectors targeting core persistence artefact types
- [x] **Phase 2** — Python normalisation layer with full OSSEM/Sigma field mapping
- [x] **Phase 3** — Sigma match engine — ingest and execute YAML rule logic against normalised output
- [ ] **Phase 4** — Per-technique detection recall report with false-positive benchmarking
