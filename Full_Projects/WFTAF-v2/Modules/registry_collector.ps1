<#
.SYNOPSIS
    Registry persistence artefact collector — T1547.001
.DESCRIPTION
    Enumerates standard and non-standard autostart registry locations, extracting
    value names and data for downstream OSSEM normalisation. Covers Run Keys,
    Winlogon hooks, AppInit_DLLs, IFEO debugger hijacking, and LSA providers.
.OUTPUTS
    [PSCustomObject[]] Array of registry persistence artefact objects.
.NOTES
    Author  : William Richardson
    ATT&CK  : T1547.001
    Called by collector_main.ps1 — do not execute directly.
#>

function Get-RegistryPersistence {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()

    # Standard and extended autostart key paths
    $AutostartPaths = @(
        @{ Hive = 'HKLM'; Path = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Run'                        },
        @{ Hive = 'HKLM'; Path = 'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'                    },
        @{ Hive = 'HKLM'; Path = 'SOFTWARE\Microsoft\Windows\CurrentVersion\RunServices'                },
        @{ Hive = 'HKLM'; Path = 'SOFTWARE\Microsoft\Windows\CurrentVersion\RunServicesOnce'            },
        @{ Hive = 'HKCU'; Path = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Run'                        },
        @{ Hive = 'HKCU'; Path = 'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'                    },
        # 32-bit process autostart on 64-bit OS
        @{ Hive = 'HKLM'; Path = 'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'            },
        @{ Hive = 'HKLM'; Path = 'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce'        },
        # Winlogon hooks — high-value hijack targets
        @{ Hive = 'HKLM'; Path = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'                },
        # Active Setup — executes per-user on first logon
        @{ Hive = 'HKLM'; Path = 'SOFTWARE\Microsoft\Active Setup\Installed Components'                 },
        # Session Manager — controls early boot execution
        @{ Hive = 'HKLM'; Path = 'SYSTEM\CurrentControlSet\Control\Session Manager'                     },
    )

    $Results = [System.Collections.Generic.List[PSCustomObject]]::new()

    # --- Autostart key enumeration ---
    foreach ($Entry in $AutostartPaths) {
        $FullPath = "$($Entry.Hive):\$($Entry.Path)"
        try {
            $Key = Get-Item -Path $FullPath -ErrorAction Stop
        } catch {
            continue
        }

        foreach ($ValueName in $Key.GetValueNames()) {
            $ValueData = $Key.GetValue($ValueName)
            if ($null -eq $ValueData -or [string]::IsNullOrWhiteSpace([string]$ValueData)) { continue }

            $Results.Add([PSCustomObject]@{
                Hive        = $Entry.Hive
                KeyPath     = $Entry.Path
                ValueName   = $ValueName
                ValueData   = [string]$ValueData
                ValueType   = $Key.GetValueKind($ValueName).ToString()
                CollectedAt = (Get-Date).ToUniversalTime().ToString('o')
            })
        }
    }

    # --- Image File Execution Options — debugger hijacking (T1546.012) ---
    $IfeoRoot = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
    try {
        foreach ($IfeoKey in Get-ChildItem -Path $IfeoRoot -ErrorAction Stop) {
            $Debugger = (Get-ItemProperty -Path $IfeoKey.PSPath -Name Debugger -ErrorAction SilentlyContinue).Debugger
            if (-not $Debugger) { continue }

            $Results.Add([PSCustomObject]@{
                Hive        = 'HKLM'
                KeyPath     = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$($IfeoKey.PSChildName)"
                ValueName   = 'Debugger'
                ValueData   = $Debugger
                ValueType   = 'REG_SZ'
                CollectedAt = (Get-Date).ToUniversalTime().ToString('o')
            })
        }
    } catch {}

    # --- AppInit_DLLs — loaded into every user-mode process ---
    $AppInitPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\AppInit_DLLs'
    try {
        $AppInitDlls = (Get-ItemProperty -Path $AppInitPath -ErrorAction Stop).AppInit_DLLs
        if ($AppInitDlls) {
            $Results.Add([PSCustomObject]@{
                Hive        = 'HKLM'
                KeyPath     = 'SYSTEM\CurrentControlSet\Control\Session Manager\AppInit_DLLs'
                ValueName   = 'AppInit_DLLs'
                ValueData   = $AppInitDlls
                ValueType   = 'REG_SZ'
                CollectedAt = (Get-Date).ToUniversalTime().ToString('o')
            })
        }
    } catch {}

    # --- LSA authentication / security / notification packages ---
    $LsaPath    = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
    $LsaValues  = @('Authentication Packages', 'Security Packages', 'Notification Packages')

    foreach ($LsaValue in $LsaValues) {
        try {
            $Packages = (Get-ItemProperty -Path $LsaPath -Name $LsaValue -ErrorAction Stop).$LsaValue
            if (-not $Packages) { continue }

            $Results.Add([PSCustomObject]@{
                Hive        = 'HKLM'
                KeyPath     = 'SYSTEM\CurrentControlSet\Control\Lsa'
                ValueName   = $LsaValue
                ValueData   = ($Packages -join '; ')
                ValueType   = 'REG_MULTI_SZ'
                CollectedAt = (Get-Date).ToUniversalTime().ToString('o')
            })
        } catch {}
    }

    return $Results.ToArray()
}
