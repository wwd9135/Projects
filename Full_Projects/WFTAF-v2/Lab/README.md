# Lab — Detection Validation Simulations

Each script in this directory simulates the minimum viable artefact for its corresponding
MITRE ATT&CK technique. The intent is to validate that the WFTAF collector surfaces
the artefact and that the Sigma rule fires with the expected severity.

All simulations are modelled on [Atomic Red Team](https://github.com/redcanaryco/atomic-red-team)
test cases and clean up after themselves automatically.

---

## Usage

Run a simulation, then immediately execute the collector and pipeline:

```powershell
# Terminal 1 — run the simulation (pauses before cleanup)
.\Lab\simulate_run_key.ps1

# Terminal 2 — collect and detect while the artefact is live
.\Modules\collector_main.ps1
python main.py
```

---

## Simulations

| Script | Technique | Severity | Requires Admin |
|---|---|---|---|
| `simulate_run_key.ps1` | T1547.001 — Registry Run Key | Medium | No |
| `simulate_scheduled_task.ps1` | T1053.005 — Scheduled Task | High | No |
| `simulate_wmi_subscription.ps1` | T1546.003 — WMI Subscription | Critical | Yes |

---

## Expected Outcome

A detection recall rate of 100% against these simulations is the baseline validation bar.
False positives should be reviewed in the context of the filter conditions defined in each
Sigma rule under `/Rules`.
