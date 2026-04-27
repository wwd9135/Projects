$Apps = (Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall) | Get-ItemProperty | Select-Object DisplayName
$Apps += (Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall) | Get-ItemProperty | Select-Object DisplayName
if ((Test-Path "$env:ProgramFiles\Google\Chrome\Application\chrome.exe") -or (Test-Path "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe")) {
    if ($null -eq ($apps | Where-Object DisplayName -EQ "Google Chrome")) {
        Write-Output $false
        }
    Write-Output $true
    } else {
    Write-Output $true
}

#taken from https://patchtuesday.com/blog/tech-blog/windows-defender-exploit-guard-breaks-google-chrome/