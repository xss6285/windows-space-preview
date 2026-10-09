[CmdletBinding()]
param(
    [ValidateSet('Status','Install','Start','Restart')]
    [string]$Action = 'Status',
    [string]$FilePath
)
$ErrorActionPreference = 'Stop'
function Find-PreviewExecutable {
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\QuickLook\QuickLook.exe",
        "$env:ProgramFiles\QuickLook\QuickLook.exe",
        "${env:ProgramFiles(x86)}\QuickLook\QuickLook.exe"
    )
    $running = Get-Process -Name QuickLook -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($running -and $running.Path) { $candidates = @($running.Path) + $candidates }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    return $null
}
$exe = Find-PreviewExecutable
if ($Action -eq 'Install' -and -not $exe) {
    & winget install --id QL-Win.QuickLook --exact --source winget --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) { throw "QuickLook installation failed: $LASTEXITCODE" }
    $exe = Find-PreviewExecutable
    if (-not $exe) { throw 'Installation returned success but executable was not found. Inspect installation location.' }
}
$startup = Join-Path ([Environment]::GetFolderPath('Startup')) 'QuickLook.lnk'
if ($Action -in @('Install','Start','Restart')) {
    if (-not $exe) { throw 'QuickLook is not installed. Use -Action Install.' }
    if ($Action -eq 'Install') {
        $shell = New-Object -ComObject WScript.Shell
        $link = $shell.CreateShortcut($startup)
        $link.TargetPath = $exe
        $link.Arguments = '/autorun'
        $link.WorkingDirectory = Split-Path -Parent $exe
        $link.IconLocation = "$exe,0"
        $link.Save()
    }
    if ($Action -eq 'Restart') {
        Get-Process -Name QuickLook -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe } | Stop-Process
        Start-Sleep -Milliseconds 500
    }
    if (-not (Get-Process -Name QuickLook -ErrorAction SilentlyContinue)) {
        Start-Process -FilePath $exe -ArgumentList '/autorun' -WorkingDirectory (Split-Path -Parent $exe) -WindowStyle Hidden
        Start-Sleep -Seconds 2
    }
}
$fileInfo = $null
if ($FilePath) {
    $resolved = (Resolve-Path -LiteralPath $FilePath).Path
    $stream = [IO.File]::Open($resolved,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    try {
        $buffer = New-Object byte[] 16
        $count = $stream.Read($buffer,0,$buffer.Length)
    } finally { $stream.Dispose() }
    $header = [Text.Encoding]::ASCII.GetString($buffer,0,$count)
    $format = if ($header.StartsWith('%PDF')) { 'PDF content (PDF-compatible AI if extension is .ai)' }
        elseif ($header.StartsWith('8BPS')) { 'Photoshop PSD/PSB; composite rendering must still be tested' }
        elseif ($header.StartsWith('%!PS')) { 'PostScript; not covered by built-in PDFViewer' }
        else { 'Other; header alone does not establish preview support' }
    $fileInfo = [pscustomobject]@{ Path=$resolved; Extension=[IO.Path]::GetExtension($resolved); Format=$format }
}
$base = if ($exe) { Split-Path -Parent $exe } else { $null }
$startupTarget = $null
if (Test-Path -LiteralPath $startup) {
    $startupShell = New-Object -ComObject WScript.Shell
    $startupTarget = $startupShell.CreateShortcut($startup).TargetPath
}
[pscustomobject]@{
    Executable=$exe
    Version=if ($exe) { (Get-Item -LiteralPath $exe).VersionInfo.ProductVersion } else { $null }
    Running=@(Get-Process -Name QuickLook -ErrorAction SilentlyContinue).Count -gt 0
    StartupShortcut=$startupTarget
    StartupMatchesExecutable=($null -ne $exe -and $startupTarget -eq $exe)
    ImageViewer=($null -ne $base -and (Test-Path -LiteralPath (Join-Path $base 'QuickLook.Plugin\QuickLook.Plugin.ImageViewer\QuickLook.Plugin.ImageViewer.dll')))
    TextViewer=($null -ne $base -and (Test-Path -LiteralPath (Join-Path $base 'QuickLook.Plugin\QuickLook.Plugin.TextViewer\QuickLook.Plugin.TextViewer.dll')))
    PdfViewer=($null -ne $base -and (Test-Path -LiteralPath (Join-Path $base 'QuickLook.Plugin\QuickLook.Plugin.PDFViewer\QuickLook.Plugin.PDFViewer.dll')))
    IndependentOfficeViewer=(Test-Path -LiteralPath (Join-Path $env:APPDATA 'pooi.moe\QuickLook\QuickLook.Plugin\QuickLook.Plugin.OfficeViewer\Syncfusion.DocIO.Base.dll'))
    PossibleConflicts=@(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(PowerToys.Peek.UI|Seer)$' } | Select-Object -ExpandProperty ProcessName)
    File=$fileInfo
} | ConvertTo-Json -Depth 4
