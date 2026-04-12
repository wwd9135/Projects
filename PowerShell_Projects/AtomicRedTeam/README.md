# Overview Atomic red team subdirectory
ART is a purple team tool used to test common MITRE ATT&CK mapped threat actor TTPs
I begun using it for my SC200 cert labs, I created an Azure tenant and within that a VM to run ART and generate a load of telematary to better understand the adversarial mindset and practice threat hunting/ writing detections (using KQL)

## Navigation
- AuditMode.ps1- this is a script to switch a windows endpoint into audit mode, preventing defender from stopping any threats, useful to carry out an entire attack chain and see what would have gotten through.
