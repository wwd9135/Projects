$defService = Get-Service -Name "WinDefend" -ErrorAction SilentlyContinue

if ($null -eq $defService) {
    Write-Output "WinDefend service missing"
    exit 1
}

if ($defService.Status -ne 'Running') {
    Write-Output "WinDefend service not running"
    exit 1
}

Write-Output "WinDefend service running"
exit 0
