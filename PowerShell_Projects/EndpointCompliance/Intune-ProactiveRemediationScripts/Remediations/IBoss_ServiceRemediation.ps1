$ibossService = Get-Service -Name 'IBSA' -ErrorAction SilentlyContinue
if ($null -eq $ibossService) {
    exit 1 # Service not installed
}
if ($ibossService.Status -ne 'Running') {
    Start-Service -Name 'IBSA' -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
    $ibossService.Refresh()
}
if ($ibossService.Status -ne 'Running') {
    exit 1
}
exit 0