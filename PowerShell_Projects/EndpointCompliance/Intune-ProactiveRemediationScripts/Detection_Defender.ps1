# TODO@
# Review the data coming from each check to ensure its doing what I expect
# Focus on remediations if all is well?
#



<#
.SYNOPSIS
    Defender Health & Execution Detection Script for Intune Proactive Remediations
.DESCRIPTION
    Checks Core Service Health, MDE Onboarding, MAPS Connectivity, Signature Age, 
    and critical protection states. 
    Returns Exit 1 if unhealthy (triggers remediation) or Exit 0 if healthy.
#>

try {
    $Issues = @()

    # 1. Service Status
    $defService = Get-Service -Name "WinDefend" -ErrorAction SilentlyContinue
    if (-not $defService -or $defService.Status -ne 'Running') { 
        $Issues += "Service Stopped/Missing" 
    }

    # 2. Onboarding Status (Registry)
    $OnboardPath = "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status"
    $Onboard = (Get-ItemProperty -Path $OnboardPath -ErrorAction SilentlyContinue).OnboardingState
    if ($Onboard -ne 1) { 
        $Issues += "Not Onboarded" 
    }

    # 3. MAPS connectivity
    $MpCmdRun = "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe"

    # Ensure binary exists (Intune-safe)
    if (-not (Test-Path $MpCmdRun)) {
        $Issues += "FAIL: MpCmdRun not found"
    } else {
        # Run once, capture output + exit code
        $Output = & $MpCmdRun -ValidateMapsConnection 2>&1
        $ExitCode = $LASTEXITCODE

        # Detection logic (fail-safe)
        if ($ExitCode -eq 0 -and $Output -match 'successfully established a connection') {
            # PASS: We do nothing here so the script continues to the next check.
        }
        else {
            # FAIL: We add it to the issues array. 
            # Note: Intune outputs are best kept to a single line, so we combine your output here.
            $Issues += "FAIL: MAPS connectivity failed (ExitCode=$ExitCode)"
        }
    }

    # Attempt to pull Defender stats. Wrapped in a try/catch because if the 
    # engine is corrupted, these cmdlets will throw terminating errors.
    try {
        $MPStat = Get-MpComputerStatus -ErrorAction Stop
        $MPPref = Get-MpPreference -ErrorAction Stop

        # 4. Signature Age (Max 3 days)
        if ($MPStat.AntivirusSignatureAge -gt 3) { 
            $Issues += "Stale Signatures ($($MPStat.AntivirusSignatureAge) days)" 
        }

        # 5. Platform & Engine Versions (Cast as [version] to ensure accurate math comparison)
        [version]$MinPlatform = '4.18.2001.10'
        [version]$MinEngine   = '1.1.26010.1'
        
        if ($MPStat.AMServiceVersion -as [version] -and [version]$MPStat.AMServiceVersion -lt $MinPlatform) { 
            $Issues += "Old Platform ($($MPStat.AMServiceVersion))" 
        }
        if ($MPStat.AMProductVersion -as [version] -and [version]$MPStat.AMProductVersion -lt $MinEngine) { 
            $Issues += "Old Engine ($($MPStat.AMProductVersion))" 
        }

        # 6. Running Mode
        if ($MPStat.AMRunningMode -ne 'Normal') { 
            $Issues += "Mode: $($MPStat.AMRunningMode)" 
        }

        # 7. RTP, PUA, and Network Protection
        if ($MPStat.RealTimeProtectionEnabled -ne $true) { $Issues += "RTP Disabled" }
        if ($MPPref.PUAProtection -ne 1) { $Issues += "PUA Disabled" }
        if ($MPPref.EnableNetworkProtection -ne 1) { $Issues += "NetworkProt Disabled" }

        # 8. Device Control State & Policy Age
        $MaxAge = New-TimeSpan -Days 14
        if ($MPStat.DeviceControlState -notin @('Enabled','RebootRequired')) { 
            $Issues += "DC Disabled" 
        }
        
        # Ensure DeviceControlPoliciesLastUpdated has a value before calculating timespan
        if ($MPStat.DeviceControlPoliciesLastUpdated) {
            $timeSinceUpdate = (Get-Date) - $MPStat.DeviceControlPoliciesLastUpdated
            if ($timeSinceUpdate -gt $MaxAge) { 
                $Issues += "Either no update/ event triggered in 14 days (False positive), or the DC is stale" 
            }
        } else {
            $Issues += "DC Policy Never Updated"
        }

    } catch {
        $Issues += "Get-MpComputerStatus failed (Engine likely degraded)"
    }
    
    # Reporting Logic
    if ($Issues.Count -gt 0) {
        # Join with a pipe for easier reading in the Intune portal
        Write-Output "Non-Compliant: $($Issues -join ' | ')"
        Write-Host 1
    } else {
        Write-Output "Compliant: Core Health OK"
        Write-Host 0
    }

} catch {
    # Catch-all for catastrophic script failures
    Write-Output "Non-Compliant: Script Error - $($_.Exception.Message)"
    write-host 1
}
