<#
.SYNOPSIS
    Detection validation simulation — T1547.001 Registry Run Key persistence
.DESCRIPTION
    Creates a benign test registry entry under the current user's Run key to
    validate that the WFTAF registry collector detects and normalises the
    artefact correctly, and that the Sigma rule fires as expected.

    Cleans up the test entry automatically after confirmation.
.PARAMETER TestPayload
    The value to write as the run key data. Defaults to calc.exe (benign).
.PARAMETER ValueName
    The registry value name used for the test entry.
.NOTES
    Author  : William Richardson
    ATT&CK  : T1547.001
    ART Test: T1547.001-1 (Reg Key Run)

    IMPORTANT: Run in an isolated lab environment only.
               Do not run in production.
#>
param(
    [string]$TestPayload = 'C:\Windows\System32\calc.exe',
    [string]$ValueName   = 'WFTAF_Test_T1547_001'
)

$RunKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'

Write-Host ''
Write-Host '[WFTAF Lab] T1547.001 — Registry Run Key simulation' -ForegroundColor Yellow
Write-Host "            Key   : $RunKey"
Write-Host "            Value : $ValueName = $TestPayload"
Write-Host ''

try {
    Set-ItemProperty -Path $RunKey -Name $ValueName -Value $TestPayload -ErrorAction Stop
    Write-Host '[+] Run key created.' -ForegroundColor Green
    Write-Host ''
    Write-Host '    Run the collector now to validate detection:' -ForegroundColor Cyan
    Write-Host '    > .\Modules\collector_main.ps1'
    Write-Host '    > python main.py'
    Write-Host ''
    Read-Host '[>] Press Enter to clean up and remove the test entry'
} finally {
    Remove-ItemProperty -Path $RunKey -Name $ValueName -ErrorAction SilentlyContinue
    Write-Host '[+] Cleaned up — test entry removed.' -ForegroundColor Cyan
    Write-Host ''
}
