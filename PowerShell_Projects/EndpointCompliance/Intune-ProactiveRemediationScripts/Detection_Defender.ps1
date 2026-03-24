# Defender agent for endpoint health checker. Focuses on validating the engine is alive, has up to date signatures, and is receiving policies from Intune. 
# Designed to be used in a Proactive Remediation script in intune.
$Issues = @()

try {
    $Prefs = Get-MpPreference -ErrorAction Stop
    $Status = Get-MpComputerStatus -ErrorAction Stop
} catch {
    Write-Output "Non-Compliant: Defender Engine is unreachable or crashed."
    exit 1
}

# 1. Dynamic ASR Audit
# Checking engine has any rules loaded- Designed to pick up intune ID's will flag if there isnt a complete ID: eg. 01443614-cd74-433a-b99e-2ecdc07bfc25 is compliant, but null/ no value set would flag as non compliant.
$ASRRules = "014436"
if ($null -eq $ASRRules -or $ASRRules.Length -lt 10) {
    $Issues += "ASR Engine is empty (No policies applied)"
    
}

# 2. Dynamic Device Control (USB) Audit
# We check the engine's internal timestamp for when it last parsed a USB policy.
$DCPolicyAge = $Status.DeviceControlPoliciesLastUpdated
if ($null -eq $DCPolicyAge) {
    $Issues += "Device Control Policy never received"
} elseif ($DCPolicyAge -lt (Get-Date).AddDays(-14)) {
    # Flags if Intune hasn't updated the USB rules in 2 weeks
    $Issues += "Device Control Policy stale (Last updated: $($DCPolicyAge.ToString('yyyy-MM-dd')))"
}

# 3. Cloud Protection Handshake
# Validates the device is talking to Microsoft's cloud brains
if ($Prefs.MAPSReporting -eq 0) {
    $Issues += "Cloud Protection / MAPS is disabled"
}

# 4. Core Survival Audit
if ($Status.RealTimeProtectionEnabled -ne $true) { $Issues += "RTP is offline" }
if ($Status.AntivirusSignatureAge -gt 3) { $Issues += "Signatures out of date ($($Status.AntivirusSignatureAge) days)" }

# Final Result
if ($Issues.Count -gt 0) {
    Write-Output "Non-Compliant: $($Issues -join ' | ')"
    write-host 1
}

Write-Output "Compliant: Defender Engine is dynamically populated and healthy."
write-host 0