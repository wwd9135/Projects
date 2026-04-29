# 3. MAPS Connectivity
$MpCmdRun = "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe"

if (-not (Test-Path $MpCmdRun)) {
    Write-Host "FAIL: MpCmdRun.exe not found at $MpCmdRun"
    exit 1
}

$Output    = & $MpCmdRun -ValidateMapsConnection 2>&1
$ExitCode  = $LASTEXITCODE
$OutputStr = $Output -join " "

# Explicit success — binary pass only on clean exit + success string
if ($ExitCode -eq 0 -and $OutputStr -match "successfully established a connection") {
    Write-Host "PASS: MAPS connectivity verified successfully"
    exit 0
}

# Error path — try to extract last known good timestamp from output
if ($OutputStr -match '\[(\d{2}/\d{2}/\d{4}\s\d{2}:\d{2}:\d{2})\]') {
    $TimestampStr = $matches[1]
    $Timestamp    = [datetime]::ParseExact($TimestampStr, "dd/MM/yyyy HH:mm:ss", $null)
    $AgeDiff      = (Get-Date) - $Timestamp

    if ($AgeDiff.TotalHours -lt 3) {
        Write-Host "PASS: Last successful MAPS connection was $([math]::Round($AgeDiff.TotalMinutes, 0)) minutes ago ($TimestampStr)"
        exit 0
    } else {
        Write-Host "FAIL: Last successful MAPS connection was $([math]::Round($AgeDiff.TotalHours, 1)) hours ago ($TimestampStr)"
        exit 1
    }
}

# Catch-all — no timestamp found, no clean success → non-compliant
Write-Host "FAIL: MAPS connectivity check failed and no timestamp could be determined. Exit code: $ExitCode"
Write-Host "Output: $OutputStr"
exit 1