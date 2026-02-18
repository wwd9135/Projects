# ===============================
# Trig – Endpoint Triage Tool
# Author: William Richardson
# ===============================

$ErrorActionPreference = 'SilentlyContinue'

# --- Privilege Check ---
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    throw "TRIDENT must be run with administrative privileges"
}

# --- Metadata ---
$Meta = [PSCustomObject]@{
    ComputerName = $env:COMPUTERNAME
    Username     = $env:USERNAME
    Domain       = $env:USERDOMAIN
    TimestampUtc = (Get-Date).ToUniversalTime().ToString("o")
    Script       = "Triage_Collector2.ps1"
    Version      = "1.0.0"
    IsAdmin      = $isAdmin
}


# --- General System Info ---
$System = Get-ComputerInfo |
    Select-Object `
        CsDNSHostName, CsDomain, OsName, OsVersion, OsBuildNumber,
        OsArchitecture, OsUptime, TimeZone, OsSerialNumber,
        CsManufacturer, CsModel, BiosBIOSVersion

# --- Network ---
$Network = [PSCustomObject]@{
    Interfaces = Get-NetIPAddress |
        Select-Object InterfaceAlias, IPAddress, AddressFamily, PrefixOrigin

    Connections = Get-NetTCPConnection |
        Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess

    DnsCache = Get-DnsClientCache |
        Select-Object Entry, Data
}

# --- Processes ---
$Processes = Get-Process -IncludeUserName |
    Select-Object `
        Name, Id, Path, Company, CPU, StartTime, UserName

# --- Persistence ---
$Persistence = [PSCustomObject]@{
    StartupCommands = Get-CimInstance Win32_StartupCommand |
        Select-Object Name, Command, Location, User

    ScheduledTasks = Get-ScheduledTask |
        Where-Object State -ne 'Disabled' |
        Select-Object TaskName, TaskPath, State

    Services = Get-CimInstance Win32_Service |
        Select-Object Name, PathName, StartMode, State, ProcessId
}

# --- User Activity ---
$UserActivity = [PSCustomObject]@{
    UsbDevices = Get-ItemProperty `
        'HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR\*\*' |
        Select-Object FriendlyName

    PowerShellHistory = Get-History |
        Select-Object Id, CommandLine, StartExecutionTime
}

# --- Advanced Forensics ---
$Advanced = [PSCustomObject]@{
    Prefetch = Get-ChildItem C:\Windows\Prefetch\ |
        Select-Object Name, CreationTime, LastWriteTime

    WmiSubscriptions = Get-WmiObject `
        -Namespace root\subscription `
        -Class __FilterToConsumerBinding |
        Select-Object Filter, Consumer

    DefenderExclusions = Get-ChildItem `
        'HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions' |
        Select-Object Name
}

# --- Final Report Object ---
$Payload = [PSCustomObject]@{
    System       = $System
    Network      = $Network
    Processes    = $Processes
    Persistence  = $Persistence
    UserActivity = $UserActivity
    Advanced     = $Advanced
}

$PayloadHash = [System.BitConverter]::ToString(
    (New-Object System.Security.Cryptography.SHA256Managed).ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes(
            ($Payload | ConvertTo-Json -Depth 10)
        )
    )
).Replace("-", "")

$TriageReport = [PSCustomObject]@{
    Meta      = $Meta
    Payload   = $Payload
    Integrity = @{
        PayloadSHA256 = $PayloadHash
        Algorithm     = "SHA-256"
        Scope         = "Payload"
    }
}
# --- Export ---
$OutputPath = Join-Path $PWD "Trig.json"
$TriageReport |
    ConvertTo-Json -Depth 6 |
    Out-File -Encoding UTF8 $OutputPath

Write-Host "Triage collection saved to $OutputPath" -ForegroundColor Green
