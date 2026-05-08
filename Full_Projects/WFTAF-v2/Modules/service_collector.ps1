<#
.SYNOPSIS
    Windows service persistence artefact collector — T1543.003
.DESCRIPTION
    Enumerates auto-start services, resolves svchost service DLL paths from the
    registry, and hashes primary binaries for downstream integrity analysis.
.OUTPUTS
    [PSCustomObject[]] Array of service artefact objects.
.NOTES
    Author  : William Richardson
    ATT&CK  : T1543.003
    Called by collector_main.ps1 — do not execute directly.
#>

function Get-ServicePersistence {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()

    $Results = [System.Collections.Generic.List[PSCustomObject]]::new()

    $Services = Get-CimInstance -ClassName Win32_Service -ErrorAction SilentlyContinue |
                Where-Object { $_.StartMode -in @('Auto', 'Automatic') }

    foreach ($Svc in $Services) {
        $BinaryPath = $Svc.PathName
        $DllPath    = $null
        $BinaryHash = $null

        # Resolve the underlying DLL for svchost-hosted services.
        # svchost services run as DLLs loaded via a registry ServiceDll value —
        # the binary path alone gives no meaningful signal for these.
        if ($BinaryPath -match 'svchost') {
            $ServiceParamKey = "HKLM:\SYSTEM\CurrentControlSet\Services\$($Svc.Name)\Parameters"
            try {
                $DllPath = (Get-ItemProperty -Path $ServiceParamKey `
                                -Name ServiceDll -ErrorAction Stop).ServiceDll
            } catch {}
        }

        # Extract the raw executable path, stripping quotes and CLI flags
        $RawExe = ($BinaryPath -split '"')[1]
        if (-not $RawExe) {
            $RawExe = ($BinaryPath -split ' -| /')[0].Trim('"')
        }

        if ($RawExe -and (Test-Path -Path $RawExe -ErrorAction SilentlyContinue)) {
            $BinaryHash = (Get-FileHash -Path $RawExe -Algorithm SHA256 -ErrorAction SilentlyContinue)?.Hash
        }

        $Results.Add([PSCustomObject]@{
            Name         = $Svc.Name
            DisplayName  = $Svc.DisplayName
            Description  = $Svc.Description
            BinaryPath   = $BinaryPath
            DllPath      = $DllPath
            StartMode    = $Svc.StartMode
            State        = $Svc.State
            RunAs        = $Svc.StartName
            ProcessId    = $Svc.ProcessId
            BinaryHash   = $BinaryHash
            CollectedAt  = (Get-Date).ToUniversalTime().ToString('o')
        })
    }

    return $Results.ToArray()
}
