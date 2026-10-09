[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$WorkDirectory)
$ErrorActionPreference = 'Stop'
$work = [IO.Path]::GetFullPath($WorkDirectory)
New-Item -ItemType Directory -Path $work -Force | Out-Null
$release = Invoke-RestMethod 'https://api.github.com/repos/QL-Win/QuickLook.Plugin.OfficeViewer/releases/latest'
$asset = @($release.assets | Where-Object name -EQ 'QuickLook.Plugin.OfficeViewer.qlplugin')[0]
if (-not $asset -or -not $asset.browser_download_url.StartsWith('https://github.com/QL-Win/QuickLook.Plugin.OfficeViewer/releases/download/')) { throw 'Official plugin asset not found' }
$zip = Join-Path $work 'OfficeViewer.zip'
Invoke-WebRequest $asset.browser_download_url -OutFile $zip -UseBasicParsing
$unpacked = Join-Path $work 'unpacked'
Expand-Archive -LiteralPath $zip -DestinationPath $unpacked -Force
[xml]$metadata = Get-Content -LiteralPath (Join-Path $unpacked 'QuickLook.Plugin.Metadata.config') -Raw
if ($metadata.Metadata.Namespace -ne 'QuickLook.Plugin.OfficeViewer') { throw 'Unexpected plugin namespace' }
$target = Join-Path $env:APPDATA 'pooi.moe\QuickLook\QuickLook.Plugin\QuickLook.Plugin.OfficeViewer'
if (Test-Path -LiteralPath $target) {
    Copy-Item -LiteralPath $target -Destination (Join-Path $work ('backup-' + [DateTime]::Now.ToString('yyyyMMddHHmmss'))) -Recurse
}
Get-Process -Name QuickLook -ErrorAction SilentlyContinue | Stop-Process
try {
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    Copy-Item -Path (Join-Path $unpacked '*') -Destination $target -Recurse -Force
} finally {
    & (Join-Path $PSScriptRoot 'manage-preview.ps1') -Action Start
}
[pscustomobject]@{OfficeViewerVersion=$metadata.Metadata.Version;Directory=$target;Download=$asset.browser_download_url} | ConvertTo-Json -Compress
