# Overview
PowerShell scripts designed to gather windows forensic data
Designing output to be in JSON, so my python file can parse the data as a dict and feed it into an LLM for further analysis.
## How to use
- Activate admin privledges on a windows device.
- Run Triage_Collector2.ps1
- Output will be saved to your working directory as Trig.json
- Run Parsers/_main_.py ensuring Trig.json is in your working directory.
- Output will be saved to WD as "Trig_Report.md

## Navigation
- Heuristic triage: A comprehensive forensic report of a windows device

Following will be created to further refine the outputs
- Network_Triage: (In progress) A detailed network forensic analyis of a windows device
- Persistence_Triage: (In progress) A detailed persistence forensic analysis tool, checking for an attackers attempts to establish persistence and control over a windows device.
- C2_Triage: (In progress) A tool to scan for command and control server involvement on a device suspected to be compromised.