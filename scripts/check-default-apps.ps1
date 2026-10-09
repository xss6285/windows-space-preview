[CmdletBinding()]
param([string[]]$Extensions = @('.psd','.ai','.doc','.docx','.xls','.xlsx','.ppt','.pptx','.pdf','.txt'))
$ErrorActionPreference = 'Stop'
$records = foreach ($extension in $Extensions) {
    if ($extension -notmatch '^\.[a-zA-Z0-9]+$') { throw 'Invalid file extension' }
    $choice = Get-ItemProperty -LiteralPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$extension\UserChoice" -ErrorAction SilentlyContinue
    $progId = $choice.ProgId
    if (-not $progId) {
        $extensionKey = Get-Item -LiteralPath "Registry::HKEY_CLASSES_ROOT\$extension" -ErrorAction SilentlyContinue
        if ($extensionKey) { $progId = $extensionKey.GetValue('') }
    }
    $name = $null
    if ($progId) {
        $classKey = Get-Item -LiteralPath "Registry::HKEY_CLASSES_ROOT\$progId" -ErrorAction SilentlyContinue
        if ($classKey) { $name = $classKey.GetValue('') }
    }
    [pscustomobject]@{Extension=$extension;ProgId=$progId;Description=$name;OpenBehavior='Windows default application; same as Explorer double-click'}
}
$records | ConvertTo-Json -Depth 3
