# Fake bun/python to exercise deps.ps1 the way install.ps1 actually calls it:
# under $ErrorActionPreference = 'Stop'. On Windows PowerShell, assigning a
# native command's output to a variable under 'Stop' turns an expected
# nonzero-exit probe (e.g. "import insightface" when it isn't installed yet)
# into a terminating error even with stderr redirected to $null. That
# previously made install.ps1 abort on the very first dependency check on any
# machine where insightface/onnxruntime/opencv weren't already installed -
# i.e. every fresh install. deps.ps1 must set its own 'Continue' preference so
# it tolerates these expected failures regardless of the caller's preference.
$deps = Join-Path (Split-Path -Parent $PSScriptRoot) 'deps.ps1'

$state = @{ Installed = @(); Model = $false }

function bun { '1.4.2' }

function python {
    if ($args[0] -eq '-c') {
        $module = ($args[1] -split ' ')[1] -replace ';$', ''
        if ($state.Installed -contains $module) {
            Write-Output 'ok'
            $global:LASTEXITCODE = 0
        } else {
            # Mimic a real Python ImportError: multi-line stderr, exit 1.
            [Console]::Error.WriteLine('Traceback (most recent call last):')
            [Console]::Error.WriteLine("ModuleNotFoundError: No module named '$module'")
            $global:LASTEXITCODE = 1
        }
        return
    }
    if ($args[0] -eq '-m' -and $args[1] -eq 'pip') {
        $state.Installed += $args[3]
        $global:LASTEXITCODE = 0
        return
    }
    if ($args[0] -eq '--version') { '3.12.10'; return }
    $global:LASTEXITCODE = 0
}

function Assert-True($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

# Simulate install.ps1's caller scope: nothing installed yet, Stop in effect.
$state.Installed = @()
$ErrorActionPreference = 'Stop'
$threw = $false
try {
    & $deps *> $null
} catch {
    $threw = $true
}
Assert-True (-not $threw) 'deps.ps1 must not abort under a Stop caller when a probe reports "not installed yet".'
Assert-True ($state.Installed -contains 'insightface') 'insightface should have been installed.'
Assert-True ($state.Installed -contains 'opencv-python') 'opencv-python should have been installed.'

# python -m pip is used (not bare pip), so packages land in the checked interpreter.
$srcInstall = Get-Content -Raw (Join-Path (Split-Path -Parent $PSScriptRoot) 'deps.ps1')
Assert-True ($srcInstall -notmatch '(?m)^\s*pip install') 'deps.ps1 must use "python -m pip install", not bare "pip install".'

$global:LASTEXITCODE = 0
Write-Host 'PASS: face-swap dependency setup tests'
