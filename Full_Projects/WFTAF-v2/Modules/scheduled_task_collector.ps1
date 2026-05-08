<#
.SYNOPSIS
    Scheduled task persistence artefact collector — T1053.005
.DESCRIPTION
    Enumerates non-disabled scheduled tasks with full action, trigger, author, and
    principal details. Resolves and hashes action binaries for integrity tracking.
.OUTPUTS
    [PSCustomObject[]] Array of scheduled task artefact objects.
.NOTES
    Author  : William Richardson
    ATT&CK  : T1053.005
    Called by collector_main.ps1 — do not execute directly.
#>

function Get-ScheduledTaskPersistence {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()

    $Results = [System.Collections.Generic.List[PSCustomObject]]::new()

    $Tasks = Get-ScheduledTask -ErrorAction SilentlyContinue |
             Where-Object { $_.State -ne 'Disabled' }

    foreach ($Task in $Tasks) {
        try {
            $Info = Get-ScheduledTaskInfo -TaskName $Task.TaskName -TaskPath $Task.TaskPath `
                        -ErrorAction SilentlyContinue

            # Extract action details — most persistence uses the first action
            $FirstAction    = $Task.Actions | Select-Object -First 1
            $ActionPath     = $FirstAction?.Execute
            $ActionArgs     = $FirstAction?.Arguments
            $ActionWorkDir  = $FirstAction?.WorkingDirectory

            # Full action list for tasks with multiple actions
            $AllActions = @($Task.Actions | ForEach-Object {
                [PSCustomObject]@{
                    Type          = $_.CimClass.CimClassName
                    Execute       = $_.Execute
                    Arguments     = $_.Arguments
                    WorkingDir    = $_.WorkingDirectory
                }
            })

            # Trigger classification
            $TriggerTypes = @($Task.Triggers | ForEach-Object {
                $_.CimClass.CimClassName `
                    -replace 'MSFT_TaskTrigger',   '' `
                    -replace 'MSFT_Task',          ''
            })

            # Hash the action binary if it resolves to a file on disk
            $ActionHash = $null
            if ($ActionPath -and (Test-Path -Path $ActionPath -ErrorAction SilentlyContinue)) {
                $ActionHash = (Get-FileHash -Path $ActionPath -Algorithm SHA256 -ErrorAction SilentlyContinue)?.Hash
            }

            $Results.Add([PSCustomObject]@{
                TaskName        = $Task.TaskName
                TaskPath        = $Task.TaskPath
                State           = $Task.State.ToString()
                Description     = $Task.Description
                Author          = $Task.Principal?.UserId ?? $Task.Principal?.GroupId
                RunAsUser       = $Task.Principal?.UserId
                RunLevel        = $Task.Principal?.RunLevel.ToString()
                ActionPath      = $ActionPath
                ActionArguments = $ActionArgs
                ActionWorkDir   = $ActionWorkDir
                ActionHash      = $ActionHash
                AllActions      = $AllActions
                TriggerTypes    = $TriggerTypes
                LastRunTime     = $Info?.LastRunTime?.ToString('o')
                NextRunTime     = $Info?.NextRunTime?.ToString('o')
                LastTaskResult  = $Info?.LastTaskResult
                CollectedAt     = (Get-Date).ToUniversalTime().ToString('o')
            })
        } catch {
            continue
        }
    }

    return $Results.ToArray()
}
