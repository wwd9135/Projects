$OnboardPath = "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status"

try {
    $props = Get-ItemProperty -Path $OnboardPath -ErrorAction Stop
    $Onboard = $props.OnboardingState
} catch {
    # Path missing = definitely not onboarded
    Write-host 1
}

if ($Onboard -eq 1) {
    Write-Host 0   # Compliant
} else {
    Write-Host 1   # Needs remediation
}
Write-Output "SYSTEM sees OnboardingState = $Onboard"
Write-Host $props