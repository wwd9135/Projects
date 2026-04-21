$issues = @()

# --- Attempt Signature Update ---
try {
    Update-MpSignature -ErrorAction Stop
    Start-Sleep -Seconds 45 # Give it time to pull down signatures

    $MPStat = Get-MpComputerStatus -ErrorAction Stop
    if ($MPStat.AntivirusSignatureAge -gt 3) {
        $issues += "Signatures still stale after update attempt ($($MPStat.AntivirusSignatureAge) days)"
    }
} catch {
    $issues += "Signature update failed: $($_.Exception.Message)"
}

# --- Passive Mode ---
# Cannot auto-remediate - surface it clearly for manual investigation
try {
    $MPStat = Get-MpComputerStatus -ErrorAction Stop
    if ($MPStat.AMRunningMode -ne 'Normal') {
        $issues += "Engine mode abnormal ($($MPStat.AMRunningMode)) - manual investigation required"
    }
} catch {
    $issues += "Could not verify engine mode post-remediation"
}

# --- Final Exit ---
if ($issues.Count -gt 0) {
    Write-Output "REMEDIATION INCOMPLETE: $($issues -join ' | ')"
    exit 1
}

Write-Output "Defender Engine Health: REMEDIATED"
exit 0