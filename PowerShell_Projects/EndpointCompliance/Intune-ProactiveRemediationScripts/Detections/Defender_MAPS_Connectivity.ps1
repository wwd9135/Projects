# 3. MAPS Connectivity
$MpCmdRun = "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe"
$date = get-dateT
if (-not (Test-Path $MpCmdRun)) {
    Write-Host "MpCmdRun.exe not found at $MpCmdRun" -ForegroundColor Red
    Write-Host 1
} else {
    $Output   = & $MpCmdRun -ValidateMapsConnection 2>&1
    $ExitCode = $LASTEXITCODE
    $OutputStr = $Output -join " "  # Join array into single string
    if ($ExitCode -eq 0 -or $OutputStr -match "successfully established a connection") {
        Write-Host 0 # COMPLIANT: MAPS connectivity is working
    } elseif ($OutputStr -match "ERROR: ValidateMapsConnection failed" -or $OutputStr -match "ERROR") {
        if ($OutputStr -match '\[(\d{2}/\d{2}/\d{4}\s\d{2}:\d{2}:\d{2})\]') {
            Write-Host "Timestamp: $($matches[1])"
           
            if ($matches[1] ) {}
        } else {
            Write-Host "No timestamp found in output"
        }
        Write-Host $OutputStr
    }
}