# Refactored the Triage_Collector.ps1 script to change all output to JSON format for better parsing and report generation. The new script is named Triage_Collector2.ps1 and includes the same data collection but outputs it in a structured JSON format. This will allow for easier integration with Python parsing scripts to generate comprehensive reports.

# Example code to copy for the 
<#
.SYNOPSIS
    Generates a heuristic compliance report for a specific list of Intune-managed devices.
.DESCRIPTION
    This script is a heuristic windows forensics tool, creating a device wide report, focusing on wider smoking guns and obvious signs of compromise.
    Output is intentionally all JSON objects, allowing python to digest this data and easily parse the data and feed it to a LLM if necessary.
.NOTES
    Author: William Richardson
    Date: 03/02/2026
    Required Permissions: System admin access. 
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


$data = {
"==== GENERAL INFORMATION ===="
Get-ComputerInfo | Format-List -Property CsDNSHostName, CsDomain, OsName, OsVersion, OsBuildNumber, OsArchitecture, OsUptime, OsLocalDateTime, TimeZone, OsSerialNumber, OsMuiLanguages, OsHotFixes, WindowsRegisteredOrganization, WindowsRegisteredOwner, WindowsSystemRoot, OsPagingFiles, CsManufacturer, CsModel, CsName, CsProcessors, CsNetworkAdapters, BiosBIOSVersion, BiosSeralNumber, BiosFirmwareType, CsDomainRole, OsStatus, OsSuites, LogonServer, DeviceGuardSmartStatus, DeviceGuardRequiredSecurityProperties, DeviceGuardAvailableSecurityProperties, DeviceGuardSecurityServicesConfigured, DeviceGuardSecurityServicesRunning, DeviceGuardCodeIntegrityPolicyEnforcementStatus, DeviceGuardUserModeCodeIntegrityPolicyEnforcementStatus
systeminfo
"----------------------------------------
"
}

& $data | Out-File -FilePath $pwd\TRIDENT_$cname.txt
Write-Host "Collection saved in $pwd\TRIDENT_$cname.txt" -ForegroundColor Green