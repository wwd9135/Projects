# test script for verbose detection and debugging - checks for VS Code installation and version with detailed output
# Detection script (PoC mode - no version enforcement)
# Triggers remediation ONLY if policy is missing

$regpath = "HKLM:\SOFTWARE\Policies\Microsoft\VSCode"
$name = "AllowedExtensions"

Write-Host "========== START VS CODE DETECTION =========="
Write-Host ""

$vsCodePath = $null
$installType = $null
$checkedPaths = @()

# --- MACHINE INSTALL CHECK ---
$machinePath = "$env:ProgramFiles\Microsoft VS Code\Code.exe"
$checkedPaths += $machinePath

Write-Host "[CHECK] Machine install path:"
Write-Host "        $machinePath"

if (Test-Path $machinePath) {
    Write-Host "        FOUND"
    $vsCodePath = $machinePath
    $installType = "Machine"
} else {
    Write-Host "        NOT FOUND"
}

# --- USER INSTALL CHECK ---
if (-not $vsCodePath) {

    Write-Host ""
    Write-Host "[CHECK] Scanning user profiles..."

    Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {

        $userCodePath = Join-Path $_.FullName "AppData\Local\Programs\Microsoft VS Code\Code.exe"
        $checkedPaths += $userCodePath

        Write-Host "        Checking: $userCodePath"

        if (Test-Path $userCodePath) {
            Write-Host "        FOUND under user: $($_.Name)"
            $vsCodePath = $userCodePath
            $installType = "User ($($_.Name))"
            return
        } else {
            Write-Host "        Not found"
        }
    }
}

# --- RESULT: INSTALL STATE ---
Write-Host ""

if (-not $vsCodePath) {
    Write-Host "[RESULT] VS Code not installed"
    Write-Host "Checked paths:"
    $checkedPaths | ForEach-Object { Write-Host " - $_" }

    Write-Host "Detection Result: 0 (Not applicable)"
    Write-Host "========== END =========="
    return
}

Write-Host "[RESULT] VS Code FOUND"
Write-Host "Install Type : $installType"
Write-Host "Executable   : $vsCodePath"

# --- REGISTRY CHECK ---
Write-Host ""
Write-Host "[CHECK] Registry policy..."

Write-Host "    Path : $regpath"
Write-Host "    Name : $name"

if (Test-Path $regpath) {
    Write-Host "    Registry path exists"

    $regValue = Get-ItemProperty -Path $regpath -Name $name -ErrorAction SilentlyContinue

    if ($regValue) {
        Write-Host "    POLICY FOUND"
        Write-Host "    Value Data : $($regValue.$name)"
        Write-Host "Detection Result: 0 (Compliant)"
    }
    else {
        Write-Host "    POLICY MISSING (value not set)"
        Write-Host "Detection Result: 1 (Remediation required)"
    }
}
else {
    Write-Host "    Registry path missing"
    Write-Host "    POLICY MISSING"
    Write-Host "Detection Result: 1 (Remediation required)"
}

# --- SUMMARY ---
Write-Host ""
Write-Host "========== SUMMARY =========="
Write-Host "Install Type : $installType"
Write-Host "Path         : $vsCodePath"
Write-Host "Registry Path Checked : $regpath"
Write-Host "Registry Value        : $name"
Write-Host "========== END =========="