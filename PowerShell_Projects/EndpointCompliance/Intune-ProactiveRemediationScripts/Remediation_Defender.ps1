# 1. Fix Service

if ((Get-Service windefend).Status -ne 'Running') {
Set-Service windefend -StartupType Automatic -Status Running
}

# 2. Trigger Update (Fixes Signatures, Platform, and Engine)

& "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe" -SignatureUpdate

# 3. Note: Figure out how we can re-onboard the device.

# For now, we report it.

Write-Output "Remediation attempted: Service started and Updates triggered."