<#
.SYNOPSIS
    WFTAF persistence collector — pipeline orchestrator
.DESCRIPTION
    Sources all persistence artefact modules, runs each collector, assembles
    a structured JSON payload, and seals it with a SHA-256 integrity hash.
    Output is consumed by the Python normalisation and detection pipeline.
.OUTPUTS
    Output\payload.json  — structured persistence artefact payload
    Output\payload.hash  — SHA-256 integrity seal
.NOTES
    Author  : William Richardson
    Version : 2.0.0
    Requires: Administrative privileges (#Requires directive enforced below)
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = 'SilentlyContinue'

# Source collector modules relative to this script's location
. "$PSScriptRoot\registry_collector.ps1"
. "$PSScriptRoot\scheduled_task_collector.ps1"
. "$PSScriptRoot\service_collector.ps1"
. "$PSScriptRoot\wmi_collector.ps1"

# =============================================================================
# Output paths
# =============================================================================
$OutDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'Output'
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

$PayloadPath = Join-Path $OutDir 'payload.json'
$HashPath    = Join-Path $OutDir 'payload.hash'

# =============================================================================
# Scan metadata
# =============================================================================
$Meta = [PSCustomObject]@{
    ComputerName     = $env:COMPUTERNAME
    Username         = $env:USERNAME
    Domain           = $env:USERDOMAIN
    TimestampUtc     = (Get-Date).ToUniversalTime().ToString('o')
    CollectorVersion = '2.0.0'
    IsAdmin          = $true
}

Write-Host ''
Write-Host '[WFTAF] Persistence Artefact Collection' -ForegroundColor Cyan
Write-Host "        Host    : $($Meta.ComputerName)"
Write-Host "        User    : $($Meta.Username)@$($Meta.Domain)"
Write-Host "        Started : $($Meta.TimestampUtc)"
Write-Host ''

# =============================================================================
# Collection
# =============================================================================
Write-Host '  [1/4] Registry run keys and autostart locations...' -ForegroundColor Gray
$RegistryRunKeys = Get-RegistryPersistence

Write-Host '  [2/4] Scheduled tasks...' -ForegroundColor Gray
$ScheduledTasks  = Get-ScheduledTaskPersistence

Write-Host '  [3/4] Auto-start Windows services...' -ForegroundColor Gray
$Services        = Get-ServicePersistence

Write-Host '  [4/4] WMI event subscriptions...' -ForegroundColor Gray
$WmiSubscriptions = Get-WmiPersistence

# =============================================================================
# Payload assembly
# =============================================================================
$Payload = [ordered]@{
    RegistryRunKeys  = $RegistryRunKeys
    ScheduledTasks   = $ScheduledTasks
    Services         = $Services
    WmiSubscriptions = $WmiSubscriptions
}

$Report = [PSCustomObject]@{
    Meta    = $Meta
    Payload = $Payload
}

# =============================================================================
# Write JSON (UTF-8 without BOM for Python compatibility)
# =============================================================================
[System.IO.File]::WriteAllText(
    $PayloadPath,
    ($Report | ConvertTo-Json -Depth 20 -Compress),
    [System.Text.UTF8Encoding]::new($false)
)

# =============================================================================
# SHA-256 integrity seal
# =============================================================================
$FileHash = (Get-FileHash -Path $PayloadPath -Algorithm SHA256).Hash

$HashLog = [PSCustomObject]@{
    PayloadSHA256 = $FileHash
    Algorithm     = 'SHA-256'
    Scope         = 'payload.json'
    SignedAt      = (Get-Date).ToUniversalTime().ToString('o')
}

[System.IO.File]::WriteAllText(
    $HashPath,
    ($HashLog | ConvertTo-Json -Compress),
    [System.Text.UTF8Encoding]::new($false)
)

# =============================================================================
# Summary
# =============================================================================
Write-Host ''
Write-Host '[WFTAF] Collection complete.' -ForegroundColor Green
Write-Host ''
Write-Host "        Registry run keys  : $($RegistryRunKeys.Count)"
Write-Host "        Scheduled tasks    : $($ScheduledTasks.Count)"
Write-Host "        Services           : $($Services.Count)"
Write-Host "        WMI subscriptions  : $($WmiSubscriptions.Count)"
Write-Host ''
Write-Host "        Payload : $PayloadPath"
Write-Host "        Hash    : $HashPath  ($FileHash)"
Write-Host ''
Write-Host "  Run 'python main.py' to start the detection pipeline." -ForegroundColor Cyan
Write-Host ''
