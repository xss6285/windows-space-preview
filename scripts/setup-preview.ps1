[CmdletBinding()]
param([string]$WorkDirectory, [switch]$CheckOnly)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Windows 10 or 11 is required.' }
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $identity
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run from a normal user session, not as Administrator. Preview must run at the same privilege level as Explorer.'
}
$statusText = & (Join-Path $PSScriptRoot 'manage-preview.ps1') -Action Status
$status = $statusText | ConvertFrom-Json
if (-not $status.Executable -and -not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'Install Microsoft App Installer (winget) from Microsoft Store, then retry. https://apps.microsoft.com/detail/9nblggh4nns1'
}
if ($CheckOnly) {
    [pscustomobject]@{PrerequisitesPassed=$true;QuickLookInstalled=[bool]$status.Executable;OfficeViewerInstalled=$status.IndependentOfficeViewer;Plan='Install QuickLook if missing; enable startup; install OfficeViewer if missing; verify components.'} | ConvertTo-Json
    return
}
if (-not $WorkDirectory) { $WorkDirectory = Join-Path $env:LOCALAPPDATA 'WindowsSpacePreview\setup-work' }
Write-Host 'Step 1/3: QuickLook and startup'
& (Join-Path $PSScriptRoot 'manage-preview.ps1') -Action Install
Write-Host 'Step 2/3: Word, Excel and PowerPoint viewer'
if (-not $status.IndependentOfficeViewer) {
    & (Join-Path $PSScriptRoot 'install-office-preview.ps1') -WorkDirectory $WorkDirectory
} else { Write-Host 'Independent OfficeViewer is already installed.' }
Write-Host 'Step 3/3: Verify installation'
$final = (& (Join-Path $PSScriptRoot 'manage-preview.ps1') -Action Status) | ConvertFrom-Json
if (-not ($final.Running -and $final.StartupMatchesExecutable -and $final.ImageViewer -and $final.TextViewer -and $final.PdfViewer -and $final.IndependentOfficeViewer)) {
    $final | ConvertTo-Json -Depth 4 | Write-Host
    throw 'Installation verification failed. Keep the output for troubleshooting.'
}
if ($final.PossibleConflicts.Count -gt 0) {
    Write-Host ('Another preview tool is running: ' + ($final.PossibleConflicts -join ', ') + '. Disable its Space shortcut if there is a conflict.')
}
$final | ConvertTo-Json -Depth 4
Write-Host 'Ready. Select a file in Explorer and press Space. Press Esc to close.'
Write-Host 'Supported: images, PSD composite, PDF-compatible AI, TXT, PDF, DOC/DOCX, XLS/XLSX, PPTX.'
Write-Host 'Use the top-right Open button to open the original file in its Windows default app (same as double-click).'
Write-Host 'Legacy PPT and WPS-specific WPS/ET/DPS are not included. Save a standard-format copy.'
