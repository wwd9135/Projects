try {
    # 1. Attempt to start the service (May fail if tamper protection enabled)
    $defService = Get-Service windefend -ErrorAction SilentlyContinue
    if ($defService -and $defService.Status -ne 'Running') {
        Start-Service windefend -ErrorAction SilentlyContinue
    }

    # 2. Trigger Signature and Engine Updates
    $MpCmdRun = "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe"
    if (Test-Path $MpCmdRun) {
        & $MpCmdRun -SignatureUpdate
    }

    # 3. Force an Intune MDM sync using the documented enrollment client task
    try {
        $task = Get-ScheduledTask -ErrorAction SilentlyContinue |
            Where-Object {
                $_.TaskName -like 'Schedule created by enrollment client*' -and
                $_.State -ne 'Disabled'
            } |
            Select-Object -First 1

        if ($task) {
            Start-ScheduledTask -InputObject $task -ErrorAction Stop
            # Redo this one. Need to do an exit code instead.
            $SyncTriggered = $true
        }
    }
    catch {
        $SyncTriggered = $false
    }

} catch {
    #Write-Output "Remediation Failed: $($_.Exception.Message)"
    exit 1
}