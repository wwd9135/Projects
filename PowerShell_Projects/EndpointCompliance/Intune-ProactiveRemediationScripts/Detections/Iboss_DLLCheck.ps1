#### 2. DLL Version Check
$IbsaDLL = "$env:ProgramFiles\Phantom\IBSA\ibsa.dll"
$MinVersion = [version]'6.5.253.0'

if (Test-Path $IbsaDLL) {
$CurrentVersion = [version](Get-Item $IbsaDLL).VersionInfo.FileVersionRaw
}
Write-Host $CurrentVersion
Write-Host $MinVersion
if ($CurrentVersion -lt $MinVersion) {
Write-Host 1 # Reports non-compliance for outdated version
} else {
Write-Host 0 } # COMPLIANT: Tells Intune everything is fine
