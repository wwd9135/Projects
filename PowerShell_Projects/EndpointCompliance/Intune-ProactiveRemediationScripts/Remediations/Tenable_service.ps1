# 1. Attempt to start the service (May fail if tamper protection enabled)
$defService = Get-Service -Name 'Tenable Nessus Agent' -ErrorAction SilentlyContinue
if ($null -eq $defService) {
    exit 1 
    write-host "Service not found" -ForegroundColor Red
}
if ($defService.Status -ne 'Running') {
    Start-Service -Name 'Tenable Nessus Agent' -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5 # Wait for the service to attempt to start
    $defService.Refresh()
    if ($defService.Status -ne 'Running') {
        exit 1
        write-host "Failed to start Tenable Nessus Agent" -ForegroundColor Red
    }
}
exit 0
write-host "Tenable Nessus Agent is running" -ForegroundColor Green