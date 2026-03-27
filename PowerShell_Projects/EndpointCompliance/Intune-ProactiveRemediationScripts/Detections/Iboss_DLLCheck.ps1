#### 2. DLL Version Check
$IbsaDLL = "$env:ProgramFiles\Phantom\IBSA\ibsa.dll"
$MinVersion = [version]'6.5.254.0'

if (Test-Path $IbsaDLL) {
$CurrentVersion = [version](Get-Item $IbsaDLL).VersionInfo.FileVersionRaw
}
if ($CurrentVersion -lt $MinVersion) {
exit 1 # Reports non-compliance for outdated version
} else {
exit 0 } # COMPLIANT: Tells Intune everything is fine
