<#
.SYNOPSIS
    Windows Forensic Triage Collector
.DESCRIPTION
    Collects system, network, process, persistence, user activity, and advanced
    forensic artefacts and outputs structured JSON for offline analysis.
.NOTES
    Author: William Richardson
    Version: 1.0.0
    Requires: Administrative privileges
#>

$ErrorActionPreference = 'SilentlyContinue'

# =========================
# Privilege Check
# =========================
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    throw "Administrative privileges are required."
}

# =========================
# Output Paths
# =========================
$BaseDir = Get-Location
$OutDir  = Join-Path $BaseDir "Output_folder"

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir | Out-Null
}
$JsonPath = "$OutDir\Trig.json"
$HashPath = "$OutDir\Trig_Hash.log"

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir | Out-Null
}

# =========================
# Metadata
# =========================
$Meta = [PSCustomObject]@{
    ComputerName = $env:COMPUTERNAME
    Username     = $env:USERNAME
    Domain       = $env:USERDOMAIN
    TimestampUtc = (Get-Date).ToUniversalTime().ToString("o")
    Script       = "Triage_Collector.ps1"
    Version      = "1.0.0"
    IsAdmin      = $isAdmin
}

# =========================
# System
# =========================
try {
    $System = @(
        Get-ComputerInfo |
        Select-Object CsDNSHostName, CsDomain, OsName, OsVersion,
                      OsBuildNumber, OsArchitecture, OsUptime,
                      TimeZone, OsSerialNumber, CsManufacturer,
                      CsModel, BiosBIOSVersion
    )
} catch { $System = @() }

# =========================
# Network
# =========================
try {
    $Interfaces  = @(Get-NetIPAddress | Select-Object InterfaceAlias, IPAddress, AddressFamily, PrefixOrigin)
    $Connections = @(Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess)
    $DnsCache    = @(Get-DnsClientCache | Select-Object Entry, Data)
} catch {
    $Interfaces=@(); $Connections=@(); $DnsCache=@()
}

$ConnectionsSummary = [PSCustomObject]@{
    Total = $Connections.Count
    StateCounts = $Connections | Group-Object State | ForEach-Object {
        [PSCustomObject]@{
            State = $_.Name
            Count = $_.Count
        }
    }
    UniqueLocalPorts = $Connections | Select-Object -ExpandProperty LocalPort -Unique
}

$Network = [PSCustomObject]@{
    Interfaces         = $Interfaces
    Connections        = $Connections
    ConnectionsSummary = $ConnectionsSummary
    DnsCache           = $DnsCache
}

# =========================
# Processes
# =========================
try {
    $Processes = @(Get-Process -IncludeUserName |
        Select-Object Name, Id, Path, Company, CPU, StartTime, UserName)
} catch { $Processes=@() }

# =========================
# Persistence
# =========================
try {
    $StartupCommands = @(Get-CimInstance Win32_StartupCommand |
        Select-Object Name, Command, Location, User)
    $ScheduledTasks = @(Get-ScheduledTask |
        Where-Object State -ne 'Disabled' |
        Select-Object TaskName, TaskPath, State)
    $Services = @(Get-CimInstance Win32_Service |
        Select-Object Name, PathName, StartMode, State, ProcessId)
} catch {
    $StartupCommands=@(); $ScheduledTasks=@(); $Services=@()
}

$Persistence = [PSCustomObject]@{
    StartupCommands = $StartupCommands
    ScheduledTasks = $ScheduledTasks
    Services       = $Services
}

# =========================
# User Activity
# =========================
try {
    $UsbDevices = @(Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR\*\*' |
        Select-Object FriendlyName)
} catch { $UsbDevices=@() }

try {
    $PowerShellHistory = @(Get-History |
        Select-Object Id, CommandLine, StartExecutionTime)
} catch { $PowerShellHistory=@() }

$UserActivity = [PSCustomObject]@{
    UsbDevices         = $UsbDevices
    PowerShellHistory  = $PowerShellHistory
}

# =========================
# Advanced Forensics
# =========================
try {
    $Prefetch = @(Get-ChildItem C:\Windows\Prefetch |
        Select-Object Name, CreationTime, LastWriteTime)
} catch { $Prefetch=@() }

try {
    $WmiSubscriptions = @(Get-WmiObject -Namespace root\subscription `
        -Class __FilterToConsumerBinding |
        Select-Object Filter, Consumer)
} catch { $WmiSubscriptions=@() }

# Defender Exclusions
$ExclusionRoot = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions"

$DefenderExclusions = @()

foreach ($Category in Get-ChildItem $ExclusionRoot -ErrorAction SilentlyContinue) {
    try {
        $Key = Get-Item $Category.PSPath
        $ValueNames = $Key.GetValueNames()

        foreach ($Value in $ValueNames) {
            $DefenderExclusions += [PSCustomObject]@{
                Category     = $Category.PSChildName
                Value        = $Value
                RegistryPath = $Category.PSPath
            }
        }
    } catch {
        continue
    }
}

# --- Explicit NULL marker if no exclusions exist ---
if (-not $DefenderExclusions -or $DefenderExclusions.Count -eq 0) {
    $DefenderExclusions = @(
        [PSCustomObject]@{
            Category     = "NONE"
            Value        = $null
            RegistryPath = $ExclusionRoot
            Note         = "No Defender exclusions present"
        }
    )
}

$Advanced = [PSCustomObject]@{
    Prefetch           = $Prefetch
    WmiSubscriptions   = $WmiSubscriptions
    DefenderExclusions = $DefenderExclusions
}

# =========================
# Final Payload
# =========================
$Payload = [ordered]@{
    System       = $System
    Network      = $Network
    Processes    = $Processes
    Persistence  = $Persistence
    UserActivity = $UserActivity
    Advanced     = $Advanced
}

$TriageReport = [PSCustomObject]@{
    Meta    = $Meta
    Payload = $Payload
}

# =========================
# Write JSON
# =========================
[System.IO.File]::WriteAllText(
    $JsonPath,
    ($TriageReport | ConvertTo-Json -Depth 100 -Compress),
    [System.Text.UTF8Encoding]::new($false)
)

# =========================
# Hash Integrity
# =========================
$FileHash = Get-FileHash $JsonPath -Algorithm SHA256 |
            Select-Object -ExpandProperty Hash

$HashLog = [PSCustomObject]@{
    PayloadSHA256 = $FileHash
    Algorithm     = "SHA-256"
    Scope         = "Trig.json"
}

[System.IO.File]::WriteAllText(
    $HashPath,
    ($HashLog | ConvertTo-Json -Compress),
    [System.Text.UTF8Encoding]::new($false)
)