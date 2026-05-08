<#
.SYNOPSIS
    Detection validation simulation — T1546.003 WMI Event Subscription
.DESCRIPTION
    Creates a benign WMI event filter, CommandLineEventConsumer, and
    filter-to-consumer binding to validate that the WFTAF WMI collector
    surfaces the subscription and the Sigma rule fires at critical severity.

    Cleans up all WMI objects automatically after confirmation.
.PARAMETER FilterName
    The name for the test WMI event filter.
.PARAMETER ConsumerName
    The name for the test CommandLineEventConsumer.
.NOTES
    Author  : William Richardson
    ATT&CK  : T1546.003
    ART Test: T1546.003-1

    Requires: Administrative privileges (root\subscription namespace access)
    IMPORTANT: Run in an isolated lab environment only.
               Do not run in production.
#>
param(
    [string]$FilterName   = 'WFTAF_Test_Filter',
    [string]$ConsumerName = 'WFTAF_Test_Consumer'
)

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) { throw 'Administrative privileges are required for WMI subscription access.' }

Write-Host ''
Write-Host '[WFTAF Lab] T1546.003 — WMI Event Subscription simulation' -ForegroundColor Yellow
Write-Host "            Filter   : $FilterName"
Write-Host "            Consumer : $ConsumerName"
Write-Host ''

try {
    # Create event filter — triggers on any new process creation
    $Filter                = ([wmiclass]'root\subscription:__EventFilter').CreateInstance()
    $Filter.Name           = $FilterName
    $Filter.QueryLanguage  = 'WQL'
    $Filter.Query          = "SELECT * FROM __InstanceCreationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_Process'"
    $Filter.Put() | Out-Null

    # Create CommandLine consumer — benign echo command
    $Consumer                        = ([wmiclass]'root\subscription:CommandLineEventConsumer').CreateInstance()
    $Consumer.Name                   = $ConsumerName
    $Consumer.CommandLineTemplate    = 'cmd.exe /c echo WFTAF_Test > NUL'
    $Consumer.Put() | Out-Null

    # Bind filter to consumer
    $Binding          = ([wmiclass]'root\subscription:__FilterToConsumerBinding').CreateInstance()
    $Binding.Filter   = $Filter.Path_.Path
    $Binding.Consumer = $Consumer.Path_.Path
    $Binding.Put() | Out-Null

    Write-Host '[+] WMI filter, consumer, and binding created.' -ForegroundColor Green
    Write-Host ''
    Write-Host '    Run the collector now to validate detection:' -ForegroundColor Cyan
    Write-Host '    > .\Modules\collector_main.ps1'
    Write-Host '    > python main.py'
    Write-Host ''
    Read-Host '[>] Press Enter to clean up all WMI objects'
} finally {
    Get-WmiObject -Namespace 'root\subscription' -Class __FilterToConsumerBinding -ErrorAction SilentlyContinue |
        Where-Object { $_.Filter -like "*$FilterName*" } | Remove-WmiObject
    Get-WmiObject -Namespace 'root\subscription' -Class CommandLineEventConsumer -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq $ConsumerName } | Remove-WmiObject
    Get-WmiObject -Namespace 'root\subscription' -Class __EventFilter -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq $FilterName } | Remove-WmiObject

    Write-Host '[+] Cleaned up — all WMI subscription objects removed.' -ForegroundColor Cyan
    Write-Host ''
}
