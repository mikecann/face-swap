# face-swap/deps.ps1
# Checks bun, Python, and installs insightface + onnxruntime + opencv-python.
# Also checks for the inswapper_128.onnx model file.
# Idempotent - safe to run multiple times.

# install.ps1 runs with $ErrorActionPreference = 'Stop'. On Windows PowerShell,
# assigning a native command's output to a variable under that preference turns
# a non-zero exit (an expected "not installed yet" probe) into a terminating
# error even when stderr is redirected to $null. Every probe/install below is
# expected to fail on a fresh machine, so this must stay 'Continue' for those.
$ErrorActionPreference = 'Continue'

Write-Host "  [face-swap] Checking dependencies..." -ForegroundColor Cyan

# Check bun
if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
    Write-Host "    MISSING  bun - install from https://bun.sh" -ForegroundColor Red
} else {
    Write-Host "    OK  bun $(bun --version)" -ForegroundColor Green
}

# Check Python
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "    MISSING  python - install from https://python.org" -ForegroundColor Red
    return
}
Write-Host "    OK  $(python --version)" -ForegroundColor Green

# Check insightface
$insightfaceOk = python -c "import insightface; print('ok')" 2>$null
if ($insightfaceOk -eq "ok") {
    Write-Host "    OK  insightface already installed" -ForegroundColor Green
} else {
    Write-Host "    Installing insightface..." -ForegroundColor Yellow
    python -m pip install insightface
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    FAILED to install insightface. Resolve the pip error above and rerun deps.ps1." -ForegroundColor Red
    }
}

# Check onnxruntime (try GPU first, fall back to CPU)
$onnxOk = python -c "import onnxruntime; print('ok')" 2>$null
if ($onnxOk -eq "ok") {
    Write-Host "    OK  onnxruntime already installed" -ForegroundColor Green
} else {
    Write-Host "    Installing onnxruntime-gpu (GPU-accelerated)..." -ForegroundColor Yellow
    python -m pip install onnxruntime-gpu
    $onnxOk = python -c "import onnxruntime; print('ok')" 2>$null
    if ($onnxOk -ne "ok") {
        Write-Host "    onnxruntime-gpu failed; installing onnxruntime (CPU)..." -ForegroundColor Yellow
        python -m pip install onnxruntime
        if ($LASTEXITCODE -ne 0) {
            Write-Host "    FAILED to install onnxruntime. Resolve the pip error above and rerun deps.ps1." -ForegroundColor Red
        }
    }
}

# Check opencv
$cvOk = python -c "import cv2; print('ok')" 2>$null
if ($cvOk -eq "ok") {
    Write-Host "    OK  opencv-python already installed" -ForegroundColor Green
} else {
    Write-Host "    Installing opencv-python..." -ForegroundColor Yellow
    python -m pip install opencv-python
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    FAILED to install opencv-python. Resolve the pip error above and rerun deps.ps1." -ForegroundColor Red
    }
}

# Check model file
$modelsDir = "$env:LOCALAPPDATA\face-swap\models"
$modelPath  = "$modelsDir\inswapper_128.onnx"

New-Item -ItemType Directory -Force -Path $modelsDir | Out-Null

if (Test-Path $modelPath) {
    Write-Host "    OK  inswapper_128.onnx found at $modelPath" -ForegroundColor Green
} else {
    Write-Host "" -ForegroundColor Yellow
    Write-Host "    NOTICE: inswapper_128.onnx model not found." -ForegroundColor Yellow
    Write-Host "    Download it (~555 MB) from:" -ForegroundColor Yellow
    Write-Host "      https://github.com/facefusion/facefusion-assets/releases/download/models/inswapper_128.onnx" -ForegroundColor Cyan
    Write-Host "    Save it to:" -ForegroundColor Yellow
    Write-Host "      $modelPath" -ForegroundColor Cyan
    Write-Host "    (The models directory has been created for you.)" -ForegroundColor DarkGray
}
