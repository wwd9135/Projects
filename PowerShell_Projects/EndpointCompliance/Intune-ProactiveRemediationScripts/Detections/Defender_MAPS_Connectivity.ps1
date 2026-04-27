# 3. MAPS Connectivity
$MpCmdRun = "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe"
if (-not (Test-Path $MpCmdRun)) {
    Write-Host "MpCmdRun.exe not found at $MpCmdRun" -ForegroundColor Red
    exit 1
} else {
    $Output   = & $MpCmdRun -ValidateMapsConnection 2>&1
    $ExitCode = $LASTEXITCODE
    $OutputStr = $Output -join " "

    if ($ExitCode -eq 0 -or $OutputStr -match "successfully established a connection") {
        exit 0 # COMPLIANT: MAPS connectivity is working
    } elseif ($OutputStr -match "ERROR: ValidateMapsConnection failed" -or $OutputStr -match "ERROR") {

        if ($OutputStr -match '\[(\d{2}/\d{2}/\d{4}\s\d{2}:\d{2}:\d{2})\]') {
            $TimestampStr = $matches[1]
            $Timestamp    = [datetime]::ParseExact($TimestampStr, "dd/MM/yyyy HH:mm:ss", $null)
            $Now          = Get-Date
            $AgeDiff      = $Now - $Timestamp

            if ($AgeDiff.TotalHours -ge 3) {
                Write-Host "FAIL: Last successful MAPS connection was $([math]::Round($AgeDiff.TotalHours, 1)) hours ago ($TimestampStr)" -ForegroundColor Red
                exit 1
            } else {
                Write-Host "PASS: Last successful MAPS connection was $([math]::Round($AgeDiff.TotalMinutes, 0)) minutes ago ($TimestampStr)" -ForegroundColor Green
                exit 0
            }
        } else {
            Write-Host "FAIL: Could not determine last successful MAPS connection time" -ForegroundColor Red
            exit 1
        }
    }
}