<#
.SYNOPSIS
    WMI event subscription persistence collector — T1546.003
.DESCRIPTION
    Enumerates WMI event filters, consumers (all consumer types), and
    filter-to-consumer bindings in root\subscription. Any binding present
    represents a potential persistent execution mechanism.
.OUTPUTS
    [PSCustomObject[]] Array of WMI subscription artefact objects.
.NOTES
    Author  : William Richardson
    ATT&CK  : T1546.003
    Requires: Administrative privileges for root\subscription access.
    Called by collector_main.ps1 — do not execute directly.
#>

function Get-WmiPersistence {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()

    $Results   = [System.Collections.Generic.List[PSCustomObject]]::new()
    $Namespace = 'root\subscription'

    # Retrieve all filters and bindings
    $Filters  = @(Get-WmiObject -Namespace $Namespace -Class __EventFilter              -ErrorAction SilentlyContinue)
    $Bindings = @(Get-WmiObject -Namespace $Namespace -Class __FilterToConsumerBinding  -ErrorAction SilentlyContinue)

    # All known consumer types — adversaries favour CommandLine and ActiveScript
    $ConsumerClasses = @(
        '__NTEventLogEventConsumer',
        'CommandLineEventConsumer',
        'ActiveScriptEventConsumer',
        'LogFileEventConsumer',
        'SMTPEventConsumer'
    )

    $AllConsumers = foreach ($Class in $ConsumerClasses) {
        Get-WmiObject -Namespace $Namespace -Class $Class -ErrorAction SilentlyContinue
    }

    foreach ($Binding in $Bindings) {
        $FilterPath   = $Binding.Filter
        $ConsumerPath = $Binding.Consumer

        $Filter   = $Filters      | Where-Object { $_.__PATH -eq $FilterPath   } | Select-Object -First 1
        $Consumer = $AllConsumers | Where-Object { $_.__PATH -eq $ConsumerPath } | Select-Object -First 1

        $Results.Add([PSCustomObject]@{
            FilterName          = $Filter?.Name
            FilterQuery         = $Filter?.Query
            FilterQueryLanguage = $Filter?.QueryLanguage
            ConsumerName        = $Consumer?.Name
            ConsumerType        = $Consumer?.__CLASS
            ConsumerCommand     = $Consumer?.CommandLineTemplate
            ConsumerScript      = $Consumer?.ScriptText
            Namespace           = $Namespace
            CollectedAt         = (Get-Date).ToUniversalTime().ToString('o')
        })
    }

    return $Results.ToArray()
}
