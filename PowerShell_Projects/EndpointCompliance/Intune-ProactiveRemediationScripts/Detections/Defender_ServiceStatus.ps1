# 1. Service Status
$defService = Get-Service -Name "WinDefend" -ErrorAction SilentlyContinue
if (-not $defService -or $defService.Status -ne 'Running') {
    # "WinDefend Service Stopped/Missing"
} else {
    exit 0 # COMPLIANT: Tells Intune everything is fine
}
exit 1 # CRITICAL: Triggers the Remediation script