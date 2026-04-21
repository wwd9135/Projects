# 1. Attempt to start the service (May fail if tamper protection enabled)
$defService = Get-Service -Name 'WinDefend' -ErrorAction SilentlyContinue
if ($null -eq $defService) {
    exit 1 # Service not found
}
if ($defService.Status -ne 'Running') {
    Start-Service -Name 'WinDefend' -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5 # Wait for the service to attempt to start
    $defService.Refresh()
    if ($defService.Status -ne 'Running') { exit 1 }
}
exit 0