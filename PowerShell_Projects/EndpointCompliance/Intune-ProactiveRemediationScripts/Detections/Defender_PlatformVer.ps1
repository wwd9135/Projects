[version]$MinimumPlatformVersion = '4.18.26020.6'

[version]$AMServiceVersion = Get-MpComputerStatus | Select-Object -ExpandProperty AMServiceVersion

if ($AMServiceVersion -ge $MinimumPlatformVersion) {
    exit 0
    } else {
    exit 1
}


