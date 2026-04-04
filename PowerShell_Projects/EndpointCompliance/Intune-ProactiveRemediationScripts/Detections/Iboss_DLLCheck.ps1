# Force 64-bit Program Files even when script runs in 32-bit Intune context
$ProgramFiles64 = ${env:ProgramW6432}

$IbsaDLL = "$ProgramFiles64\Phantom\IBSA\ibsa.dll"
$MinVersion = [version]'6.5.253.0'

if (Test-Path $IbsaDLL) {
    $CurrentVersion = [version](Get-Item $IbsaDLL).VersionInfo.FileVersionRaw
}
if ($CurrentVersion -lt $MinVersion) {
    Exit 1  # NON-compliant
} else {
    Exit 0  # Compliant
}