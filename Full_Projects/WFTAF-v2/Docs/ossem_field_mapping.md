# OSSEM Field Mapping Reference

WFTAF normalises raw PowerShell collector output to the
[Open Source Security Events Metadata (OSSEM)](https://github.com/OTRF/OSSEM) field standard.
This ensures that Sigma rules referencing standard field names evaluate correctly
against WFTAF-normalised records without field remapping at rule level.

---

## Registry Run Key Artefacts

| PowerShell Field | OSSEM Field | Sigma Usage |
|---|---|---|
| `Hive + KeyPath + ValueName` | `TargetObject` | `TargetObject\|contains` |
| `ValueData` | `Details` | `Details\|startswith` |
| `ValueData` (image extracted) | `Image` | `Image\|endswith` |
| `ValueData` | `CommandLine` | `CommandLine\|contains` |

**Technique:** T1547.001 — Boot or Logon Autostart Execution: Registry Run Keys

---

## Scheduled Task Artefacts

| PowerShell Field | OSSEM Field | Sigma Usage |
|---|---|---|
| `ActionPath` | `Image` | `Image\|contains` |
| `ActionPath + ActionArguments` | `CommandLine` | `CommandLine\|contains` |
| `ActionHash` | `action_hash` | null check |

**Technique:** T1053.005 — Scheduled Task/Job

---

## Windows Service Artefacts

| PowerShell Field | OSSEM Field | Sigma Usage |
|---|---|---|
| `BinaryPath` (image extracted) | `Image` | `Image\|startswith` |
| `BinaryPath` | `CommandLine` | `CommandLine\|contains` |
| `BinaryHash` | `action_hash` | null check |

**Technique:** T1543.003 — Create or Modify System Process: Windows Service

---

## WMI Subscription Artefacts

| PowerShell Field | OSSEM Field | Sigma Usage |
|---|---|---|
| `ConsumerType` | `consumer_type` | `consumer_type\|contains` |
| `FilterQuery` | `filter_query` | `filter_query\|contains` |
| `ConsumerCommand / ConsumerScript` | `CommandLine` | `CommandLine\|contains` |

**Technique:** T1546.003 — Event Triggered Execution: WMI Event Subscription

---

## Notes

- `Image` extraction uses a regex pattern matching the first resolvable executable path
  in a command-line string, stripping surrounding quotes and flags.
- Fields not present in a given artefact type are set to `None` and excluded from
  Sigma field evaluation for that record.
- OSSEM reference: https://ossemproject.com/cdm/intro.html
