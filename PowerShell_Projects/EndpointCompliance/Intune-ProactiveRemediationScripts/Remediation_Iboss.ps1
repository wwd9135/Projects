try {
$ibossService = Get-Service -Name 'IBSA' -ErrorAction SilentlyContinue

# 1. Attempt to start service if it exists but is stopped
$Point = "Service restart stage"
if ($null -ne $ibossService -and $ibossService.Status -ne 'Running') {
    Start-Service -Name 'IBSA' -ErrorAction Stop
    Write-Output "Action: Started IBSA Service"
}

# 2. Check for the Version/Missing issue
# We can't 'fix' a missing file here, but we can log that it needs an install.
$Point = "Version testing stage"
if (!(Test-Path "$env:ProgramFiles\\Phantom\\IBSA\\ibsa.dll")) {
    Write-Output "Action Required: iboss agent missing. Triggering Intune App Install may be needed."
}

exit 0

}
catch {
Write-Error "Remediation failed at: $Point 
Error raised:$($_.Exception.Message)"
exit 1
}