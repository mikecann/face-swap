# Remove this clone's entries, preserving the shared menu and other tools.
param([string]$ToolsDir = 'C:\dev\tools')
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'uninstall.ps1 requires Windows.' }
. (Join-Path $PSScriptRoot 'install-lib.ps1')
$launcher = Join-Path $PSScriptRoot 'face-swap.vbs'
$remainingVerb = $false
foreach ($root in Get-FaceSwapMenuRoots) {
    $verb = "$root\shell\FaceSwap"
    if (Test-Path $verb) {
        $command = (Get-ItemProperty -Path "$verb\command" -ErrorAction SilentlyContinue).'(Default)'
        if ($command -and $command.Contains("`"$launcher`"")) {
            Remove-Item -Path $verb -Recurse -Force
        } else { $remainingVerb = $true }
    }
}
$stubPath = Join-Path $ToolsDir 'face-swap.bat'
if ((Test-Path $stubPath) -and (Get-Content $stubPath -Raw).Contains("`"$launcher`"")) {
    Remove-Item $stubPath -Force
}
$shortcutPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Face Swap.lnk'
$remainingShortcut = $false
if (Test-Path $shortcutPath) {
    $wsh = New-Object -ComObject WScript.Shell
    $shortcut = $wsh.CreateShortcut($shortcutPath)
    if ($shortcut.Arguments -eq "`"$launcher`"") { Remove-Item $shortcutPath -Force }
    else { $remainingShortcut = $true }
}
# A different clone may have replaced these entries and still use the icon.
if (-not $remainingVerb -and -not $remainingShortcut) {
    $iconPath = Join-Path $env:LOCALAPPDATA 'face-swap\icons\face-swap.ico'
    if (Test-Path $iconPath) { Remove-Item $iconPath -Force }
}
Write-Host 'Removed this clone''s Face Swap entries. Models, logs and Python packages were kept.'
