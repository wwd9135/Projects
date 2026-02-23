            <#
            .SYNOPSIS
                A PowerShell script that collects comprehensive system information for triage purposes, 
                including system details, network connections, running processes, persistence mechanisms, 
                user activity, and advanced forensic artifacts.
            .DESCRIPTION
                Trig is designed to gather a wide range of data from a Windows endpoint to assist in incident response and forensic investigations. 
                The script collects information about the system, network, processes, persistence mechanisms, user activity, and advanced forensic artifacts. 
                The collected data is structured into a JSON format for easy analysis and reporting.
            .NOTES
                Author: William Richardson
                Date: 18/02/2026
                Version: 1.0.0
                Required Permissions: System admin privileges to run the script and access system information.
                Output: A JSON file named Trig.json containing the collected triage data.
            #>
            $ErrorActionPreference = 'SilentlyContinue'

            # --- Privilege Check ---
            $isAdmin = ([Security.Principal.WindowsPrincipal] `
                [Security.Principal.WindowsIdentity]::GetCurrent()
            ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

            if (-not $isAdmin) {
                throw "Trig must be run with administrative privileges"
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

            # --- Safe System Info ---
            try {
                $System = @(
                    Get-ComputerInfo |
                    Select-Object CsDNSHostName, CsDomain, OsName, OsVersion, OsBuildNumber,
                                OsArchitecture, OsUptime, TimeZone, OsSerialNumber,
                                CsManufacturer, CsModel, BiosBIOSVersion
                )
            } catch { $System = @() }

            # --- Safe Network Info ---
            try {
                $Interfaces = @($(Get-NetIPAddress | Select-Object InterfaceAlias, IPAddress, AddressFamily, PrefixOrigin))
                $Connections = @($(Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess))
                $DnsCache = @($(Get-DnsClientCache | Select-Object Entry, Data))
            } catch { 
                $Interfaces = @(); $Connections = @(); $DnsCache = @() 
            }

            # Summarize connections for LLM agent
            $ConnectionsSummary = @{
                Total = $Connections.Count
                StateCounts = $Connections | Group-Object State | ForEach-Object { 
                    [PSCustomObject]@{State=$_.Name; Count=$_.Count} 
                }
                UniqueLocalPorts = $Connections | Select-Object -ExpandProperty LocalPort -Unique
            }

            $Network = [PSCustomObject]@{
                Interfaces = $Interfaces
                Connections = $Connections
                ConnectionsSummary = $ConnectionsSummary
                DnsCache = $DnsCache
            }

            # --- Processes ---
            try {
                $Processes = @($(Get-Process -IncludeUserName | Select-Object Name, Id, Path, Company, CPU, StartTime, UserName))
            } catch { $Processes = @() }

            # --- Persistence ---
            try {
                $StartupCommands = @($(Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User))
                $ScheduledTasks = @($(Get-ScheduledTask | Where-Object State -ne 'Disabled' | Select-Object TaskName, TaskPath, State))
                $Services = @($(Get-CimInstance Win32_Service | Select-Object Name, PathName, StartMode, State, ProcessId))
            } catch { $StartupCommands=@(); $ScheduledTasks=@(); $Services=@() }

            $Persistence = [PSCustomObject]@{
                StartupCommands = $StartupCommands
                ScheduledTasks  = $ScheduledTasks
                Services        = $Services
            }

            # --- User Activity ---
            try {
                $UsbDevices = @($(Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR\*\*' | Select-Object FriendlyName))
            } catch { $UsbDevices = @() }

            try {
                $PowerShellHistory = @($(Get-History | Select-Object Id, CommandLine, StartExecutionTime))
            } catch { $PowerShellHistory = @() }

            $UserActivity = [PSCustomObject]@{
                UsbDevices = $UsbDevices
                PowerShellHistory = $PowerShellHistory
            }

            # --- Advanced Forensics ---
            try {
                $Prefetch = @($(Get-ChildItem C:\Windows\Prefetch\ | Select-Object Name, CreationTime, LastWriteTime))
            } catch { $Prefetch = @() }

            try {
                $WmiSubscriptions = @($(Get-WmiObject -Namespace root\subscription -Class __FilterToConsumerBinding | Select-Object Filter, Consumer))
            } catch { $WmiSubscriptions = @() }

            try {
                $DefenderExclusions = @($(Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions' | Select-Object Name))
            } catch { $DefenderExclusions = @() }

            $Advanced = [PSCustomObject]@{
                Prefetch          = $Prefetch
                WmiSubscriptions  = $WmiSubscriptions
                DefenderExclusions = $DefenderExclusions
            }

                # --- Final Payload ---
            $Payload = [ordered]@{
                System       = $System
                Network      = $Network
                Processes    = $Processes
                Persistence  = $Persistence
                UserActivity = $UserActivity
                Advanced     = $Advanced
            }

        $PayloadJson = $Payload | ConvertTo-Json -Depth 100 -Compress -EscapeHandling None
        $PayloadHash = [Convert]::ToHexString(
            [System.Security.Cryptography.SHA256]::Create().ComputeHash(
                [System.Text.Encoding]::UTF8.GetBytes($PayloadJson)
            )
        )

        $TriageReport = [PSCustomObject]@{
            Meta      = $Meta
            Payload   = $Payload
            Integrity = @{
                PayloadSHA256 = $PayloadHash
                Algorithm     = "SHA-256"
                Scope         = "PayloadJsonCompressed"
            }
        }

        [System.IO.File]::WriteAllText(
        "Trig.json",
        ($TriageReport | ConvertTo-Json -Depth 100 -Compress),
        [System.Text.UTF8Encoding]::new($false) # UTF-8, no BOM
    )
