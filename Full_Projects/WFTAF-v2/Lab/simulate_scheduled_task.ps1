<#
.SYNOPSIS
    Detection validation simulation — T1053.005 Scheduled Task persistence
.DESCRIPTION
    Registers a benign scheduled task with an at-logon trigger to validate
    that the WFTAF task collector detects it and the Sigma rule fires correctly.

    Cleans up the task automatically after confirmation.
.PARAMETER TaskName
    The name used for the test scheduled task.
.NOTES
    Author  : William Richardson
    ATT&CK  : T1053.005
    ART Test: T1053.005-1

    IMPORTANT: Run in an isolated lab environment only.
               Do not run in production.
#>
param(
    [string]$TaskName = 'WFTAF_Test_T1053_005'
)

Write-Host ''
Write-Host '[WFTAF Lab] T1053.005 — Scheduled Task simulation' -ForegroundColor Yellow
Write-Host "            Task  : $TaskName"
Write-Host ''

$Action  = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument '/c echo WFTAF_Test > NUL'
$Trigger = New-ScheduledTaskTrigger -AtLogon

try {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger `
        -RunLevel Highest -Force -ErrorAction Stop | Out-Null

    Write-Host '[+] Scheduled task created.' -ForegroundColor Green
    Write-Host ''
    Write-Host '    Run the collector now to validate detection:' -ForegroundColor Cyan
    Write-Host '    > .\Modules\collector_main.ps1'
    Write-Host '    > python main.py'
    Write-Host ''
    Read-Host '[>] Press Enter to clean up and remove the test task'
} finally {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host '[+] Cleaned up — test task removed.' -ForegroundColor Cyan
    Write-Host ''
}
