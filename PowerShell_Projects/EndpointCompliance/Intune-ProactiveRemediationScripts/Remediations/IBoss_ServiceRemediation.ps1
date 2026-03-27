$ibossService = Get-Service -Name 'IBSA' -ErrorAction SilentlyContinue
Start-Service -Name 'IBSA' -ErrorAction Stop
# Checks if successful
if ($null -eq $ibossService -or $ibossService.Status -ne 'Running') {
    exit 1
} else {
    exit 0
}