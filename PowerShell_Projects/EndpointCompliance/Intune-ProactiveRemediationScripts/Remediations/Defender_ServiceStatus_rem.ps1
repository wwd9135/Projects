# 1. Attempt to start the service (May fail if tamper protection enabled)
Start-Service windefend -ErrorAction SilentlyContinue
$defService = Get-Service windefend -ErrorAction SilentlyContinue
if ($defService -and $defService.Status -ne 'Running') {
    Write-Host 1 # If we can't start the service, exit with an error to trigger Intune alert
} else {
    Write-Host 0 # Service is running, exit with success
}
