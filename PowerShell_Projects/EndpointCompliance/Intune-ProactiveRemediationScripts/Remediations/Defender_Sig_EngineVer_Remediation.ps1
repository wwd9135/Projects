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
    } else {
        exit 1 # If we can't find the task, exit with an error to trigger Intune alert
    }
}
catch {
    exit 1 # If we fail to trigger a sync, exit with an error to trigger Intune alert
} 
exit 0 # Sync triggered successfully, exit with compliant to avoid remediation
