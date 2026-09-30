# Shared by this repo's installer and uninstaller only.
function Get-FaceSwapMenuRoots {
    foreach ($ext in @('.jpg', '.jpeg', '.png', '.webp', '.bmp', '.tiff', '.tif')) {
        "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\MikesTools"
    }
    'HKCU:\Software\Classes\Directory\shell\MikesTools'
    'HKCU:\Software\Classes\Directory\Background\shell\MikesTools'
}

function ConvertTo-Ico($pngPath, $icoPath) {
    # PNG-in-ICO preserves the alpha channel without System.Drawing.
    $pngBytes = [System.IO.File]::ReadAllBytes($pngPath)
    $stream = [System.IO.FileStream]::new($icoPath, [System.IO.FileMode]::Create)
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]1)
        $writer.Write([byte]16); $writer.Write([byte]16); $writer.Write([byte]0)
        $writer.Write([byte]0); $writer.Write([uint16]1); $writer.Write([uint16]32)
        $writer.Write([uint32]$pngBytes.Length); $writer.Write([uint32]22)
        $writer.Write($pngBytes)
    } finally {
        $writer.Dispose()
        $stream.Dispose()
    }
}

function Set-MikesToolsRoot($rootKey) {
    # Leave existing shared menu properties and every other tool's verbs alone.
    if (-not (Test-Path $rootKey)) {
        New-Item -Path $rootKey -Force | Out-Null
        Set-ItemProperty -Path $rootKey -Name 'MUIVerb' -Value "Mike's Tools"
        Set-ItemProperty -Path $rootKey -Name 'SubCommands' -Value ''
        Set-ItemProperty -Path $rootKey -Name 'Icon' -Value "$env:SystemRoot\System32\imageres.dll,109"
    }
}

function Add-FaceSwapVerb($rootKey, $icon, $command) {
    $verbKey = "$rootKey\shell\FaceSwap"
    New-Item -Path "$verbKey\command" -Force | Out-Null
    Set-ItemProperty -Path $verbKey -Name 'MUIVerb' -Value 'Face Swap'
    Set-ItemProperty -Path $verbKey -Name 'Icon' -Value $icon
    Set-ItemProperty -Path "$verbKey\command" -Name '(Default)' -Value $command
}
