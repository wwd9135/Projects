# TODO- Convert this initital scrapbook style script into JSON data so python can parse it and generate a report. This is just a quick way to collect data for the parsing script development.

<#
.SYNOPSIS
    Generates a forensics report for a specific windows device, as part of a triage process.
.DESCRIPTION
    Using windows built-in tools, this script collects various system information such as running processes, network connections, installed software, and more. The collected data is then compiled into a report for analysis.
    The main goal is to identify IOC (indicators of compromise) and gather evidence for further investigation.
    This data is to be fed into a python parsing script that will extract relevant information and generate a comprehensive report.
.PARAMETER ListPath
    #
.NOTES
    Author: William Richardson
    Date: 16/02/2026
    Required Permissions: System admin access
#>

# --- Environment Validation ---

$ErrorActionPreference= 'silentlycontinue'
# Check for Admin Rights
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Host 'You must run TRIDENT using elevated privileges session...'
    Exit 1
}
$ip = ((ipconfig | findstr [0-9].\.)[0]).Split()[-1]
$cname = (gi env:\Computername).Value
Write-Host "Collecting data for $cname ($ip) | $(Get-Date -Format dd/MM/yyyy-H:mm:ss)"


"==== GENERAL INFORMATION ===="
GeneralData = Get-ComputerInfo | Format-List -Property CsDNSHostName, CsDomain, OsName, OsVersion, OsBuildNumber, OsArchitecture, OsUptime, OsLocalDateTime, TimeZone, OsSerialNumber, OsMuiLanguages, OsHotFixes, WindowsRegisteredOrganization, WindowsRegisteredOwner, WindowsSystemRoot, OsPagingFiles, CsManufacturer, CsModel, CsName, CsProcessors, CsNetworkAdapters, BiosBIOSVersion, BiosSeralNumber, BiosFirmwareType, CsDomainRole, OsStatus, OsSuites, LogonServer, DeviceGuardSmartStatus, DeviceGuardRequiredSecurityProperties, DeviceGuardAvailableSecurityProperties, DeviceGuardSecurityServicesConfigured, DeviceGuardSecurityServicesRunning, DeviceGuardCodeIntegrityPolicyEnforcementStatus, DeviceGuardUserModeCodeIntegrityPolicyEnforcementStatus, systeminfo
"----------------------------------------
"

"--- Group policy settings ---"
GroupPolicy_settings = gpresult.exe -z
"----------------------------------------
"

"--- Encryption information ---"
BitLocker_FDE = manage-bde.exe -status
"----------------------------------------
"

"==== NETWORK INFORMATION ===="
"--- Active Network Interfaces ---"
Network_Interfaces = Get-NetAdapter | ? status -eq "up" |  Get-NetIPAddress | Select IPAddress,InterfaceIndex, InterfaceAlias, AddressFamily,PrefixOrigin |Sort InterfaceAlias | Format-Table -Wrap
"----------------------------------------
"

"--- DNS Cache ---"
DNS_Cache = Get-DnsClientCache -Status 'Success' | Select Name, Data
"----------------------------------------
"

"--- Shared folders ---"
SharedFolders = net use
"----------------------------------------
"

"--- Process Connections ---"
$nets = netstat -bano|select-string 'TCP|UDP'; 
foreach ($n in $nets)    
{
$p = $n -replace ' +',' ';
$nar = $p.Split(' ');
$pname = $(Get-Process -id $nar[-1]).Path;
$n -replace "$($nar[-1])","$($ppath) $($pname)";
}
"----------------------------------------
"

"==== PROCESS INFORMATION ===="
"--- Running processes ---"
tasklist /v /fo table /fi "STATUS ne Unknown"
"----------------------------------------
"

"--- Process List ---"
ProcessList = Get-Process -IncludeUserName | Format-Table -Property Name, Id, Path, UserName, Company, Handles, StartTime, HasExited -Wrap
"----------------------------------------
"

"--- Process Commandline ---"
Get-WmiObject Win32_Process | Select-Object Name,  ProcessId, CommandLine | Sort Name | Format-Table -Wrap
"----------------------------------------
"

"==== PERSISTENCE ===="
"--- Commands on Startup ---"
StartUpCommands = Get-CimInstance -Class Win32_StartupCommand | Format-Table -Property Name, Command, User, Location -Wrap
"----------------------------------------
"

"--- Scheduled Tasks ---"
ScheduledTasks = (Get-ScheduledTask).Where({$_.State -ne "Disabled"}) | Sort TaskPath | Format-Table -Wrap
"----------------------------------------
"

"--- Services ---"
Services = Get-WmiObject win32_service | Select-Object Name, PathName, StartName, StartMode, State, ProcessId | Sort PathName| Format-Table -Wrap
ServicesExtra = Get-CimInstance -Class Win32_Service -Filter "Caption LIKE '%'" | Select-Object Name, PathName, ProcessId, StartMode, State | Format-Table
"----------------------------------------
"

"==== USER ACTIVITY ===="
"--- Recently used USB devices ---"
USBdevices = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR\*\* | Select FriendlyName
"----------------------------------------
"

"--- Recently modified files ---"
$RecentFiles = Get-ChildItem -Path $env:USERPROFILE -Recurse -File
$RecentFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 50 FullName, LastWriteTime
"----------------------------------------
"

"--- PowerShell history ---"
PsHistory = Get-history
"----------------------------------------
"

"--- Kerberos sessions ---"
Kerberos = klist sessions
"----------------------------------------
"

"--- SMB sessions ---"
SMB = Get-SmbSession
"----------------------------------------
"

"--- RDP sessions ---"
qwinsta /server:localhost
"----------------------------------------
"

"==== ADVANCED INVESTIGATION ===="
"--- Total Process Instances ---"
ProcessInstanceTotal = Get-Process | Group-Object ProcessName | Select Count, Name | Sort Count -Descending
"----------------------------------------
"

"--- Prefetch files ---"
PrefetchFiles = gci C:\Windows\Prefetch\ | Sort Name | Format-Table Name,CreationTime,LastWriteTime,LastAccessTime
"----------------------------------------
"

"--- DLL List ---"
DllList = gps | Format-List ProcessName, @{l="Modules";e={$_.Modules|Out-String}}
"----------------------------------------
"

"--- WMI ---"
WMI = Get-WmiObject -Class __FilterToConsumerBinding -Namespace root\subscription | FT Consumer,Filter,__SERVER -wrap
"----------------------------------------
"

"--- WMI Filters ---"
WMI_Filters = Get-WmiObject -Class __EventFilter -Namespace root\subscription | FT Name, Query, PSComputerName -wrap
"----------------------------------------
"

"--- WMI Consumers ---"
WMI_Consumers = Get-WmiObject -Class __EventConsumer -Namespace root\subscription | FT Name,ScriptingEngine,ScriptText -wrap
"----------------------------------------
"

"--- Windows Defender Exclusions ---"
 DefenderExclusions = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions'
"----------------------------------------
"

"--- Named Pipes List ---"
NamedPipes = Get-ChildItem -Path '\\.\pipe\' |  Sort Length | Format-Table FullName, Length, IsReadOnly, Exists, CreationTime, LastAccessTime
"----------------------------------------
"

# --- THE NEW WAY (Objects for JSON) ---
$ProcessData = Get-Process | Select-Object Name, Id, Path, Company, CPU

$TriageReport = @{
    Processes = $ProcessData
    Network   = Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, State, OwningProcess
    a = @{
        ComputerName = $env:COMPUTERNAME
        Timestamp    = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        User         = $env:USERNAME
    }
}

$TriageReport | ConvertTo-Json -Depth 10 | Out-File "Triage.json"
Write-Host "Collection saved in $pwd\Triage.json" -ForegroundColor Green