[CmdletBinding()]
param([switch]$CheckOnly)
$ErrorActionPreference = 'Stop'
$source = if (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'SKILL.md')) { $PSScriptRoot } else { Join-Path $PSScriptRoot 'windows-space-preview' }
if (-not (Test-Path -LiteralPath (Join-Path $source 'SKILL.md'))) { throw 'Extract the complete ZIP first. The skill folder is missing.' }
& (Join-Path $source 'scripts\setup-preview.ps1') -CheckOnly:$CheckOnly
if ($CheckOnly) { return }
$skillRoot = if ($env:CODEX_HOME) { Join-Path $env:CODEX_HOME 'skills' } else { Join-Path $env:USERPROFILE '.codex\skills' }
$target = Join-Path $skillRoot 'windows-space-preview'
if (Test-Path -LiteralPath $target) {
    $backupRoot = Join-Path $env:LOCALAPPDATA 'WindowsSpacePreview\skill-backups'
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    Copy-Item -LiteralPath $target -Destination (Join-Path $backupRoot ([DateTime]::Now.ToString('yyyyMMddHHmmssfff'))) -Recurse
}
New-Item -ItemType Directory -Path $target -Force | Out-Null
foreach ($item in @('SKILL.md','agents','scripts')) {
    Copy-Item -LiteralPath (Join-Path $source $item) -Destination $target -Recurse -Force
}
Write-Host ('Skill installed: ' + $target)
Write-Host 'Open a new Codex chat to use $windows-space-preview. Daily preview works without Codex.'
