# Install from this clone. All GUI entry points use the silent VBS launcher.
param(
    [switch]$SkipDeps,
    [string]$ToolsDir = 'C:\dev\tools'
)
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'install.ps1 requires Windows.' }
$RepoDir = $PSScriptRoot
. (Join-Path $RepoDir 'install-lib.ps1')

if (-not $SkipDeps) {
    & (Join-Path $RepoDir 'deps.ps1')
    if (-not (Get-Command bun -ErrorAction SilentlyContinue)) { throw 'Install Bun first: https://bun.sh' }
    Push-Location $RepoDir
    try {
        bun install
        if ($LASTEXITCODE -ne 0) { throw 'bun install failed.' }
    } finally { Pop-Location }
}

New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
# ASCII avoids encoding problems in cmd.exe.
Set-Content -Path (Join-Path $ToolsDir 'face-swap.bat') -Encoding ASCII -Value @"
@echo off
wscript.exe "$RepoDir\face-swap.vbs" %*
"@
$userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
$machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
$onPath = ($userPath -split ';') + ($machinePath -split ';') |
    Where-Object { $_.TrimEnd('\') -ieq $ToolsDir.TrimEnd('\') }
if (-not $onPath) { Write-Host "Add $ToolsDir to PATH to use the face-swap command." -ForegroundColor Yellow }

$iconsDir = Join-Path $env:LOCALAPPDATA 'face-swap\icons'
New-Item -ItemType Directory -Path $iconsDir -Force | Out-Null
$iconPath = Join-Path $iconsDir 'face-swap.ico'
ConvertTo-Ico (Join-Path $RepoDir 'icons\face-swap.png') $iconPath

$startMenuPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Face Swap.lnk'
$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($startMenuPath)
$shortcut.TargetPath = "$env:SystemRoot\System32\wscript.exe"
$shortcut.Arguments = "`"$RepoDir\face-swap.vbs`""
$shortcut.WorkingDirectory = $RepoDir
$shortcut.Description = 'Swap faces in images using InsightFace (local AI)'
$shortcut.IconLocation = $iconPath
$shortcut.Save()

foreach ($root in Get-FaceSwapMenuRoots) {
    Set-MikesToolsRoot $root
    $argument = if ($root -like '*\Background\*') { '%V' } else { '%1' }
    Add-FaceSwapVerb $root $iconPath "wscript.exe `"$RepoDir\face-swap.vbs`" `"$argument`""
}
Write-Host 'Installed Face Swap: Start Menu and Mike''s Tools image/folder menus.' -ForegroundColor Green
