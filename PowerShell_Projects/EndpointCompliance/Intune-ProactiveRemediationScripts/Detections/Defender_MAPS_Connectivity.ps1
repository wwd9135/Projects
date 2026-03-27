# 3. MAPS Connectivity
$MpCmdRun = "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe"

if (-not (Test-Path $MpCmdRun)) {
    Write-Host "MpCmdRun.exe not found at $MpCmdRun" -ForegroundColor Red
    exit 1
} else {
    $Output   = & $MpCmdRun -ValidateMapsConnection 2>&1
    $ExitCode = $LASTEXITCODE

    if ($ExitCode -eq 0 -or $Output -match "successfully established a connection") {
        exit 0 # COMPLIANT: MAPS connectivity is working
    } else {
        exit 1 # NON-COMPLIANT: MAPS connectivity issue detected
    }
}