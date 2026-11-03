param(
    [string]$AsciiWorkDirectory = 'C:\Users\Public\habit_tracker_verify'
)

. (Join-Path $PSScriptRoot 'common.ps1')

$projectRoot = Get-ProjectRoot
$flutter = Resolve-Flutter
Initialize-AndroidEnvironment -ProjectRoot $projectRoot

# Flutter 3.47.x fails to start its analysis server when the project path
# contains non-ASCII characters (Content-Length is computed in UTF-16 units).
# Analysis itself is fine, so in that case we analyze an ASCII-path mirror.
$isAsciiPath = $projectRoot -match '^[\x20-\x7E]+$'

if ($isAsciiPath) {
    Invoke-Flutter -Flutter $flutter -Arguments @('analyze') -WorkingDirectory $projectRoot
    return
}

Write-Host "Project path contains non-ASCII characters; analyzing a mirror at $AsciiWorkDirectory"

New-Item -ItemType Directory -Path $AsciiWorkDirectory -Force | Out-Null

$robocopyArgs = @(
    $projectRoot,
    $AsciiWorkDirectory,
    '/MIR',
    '/XD', '.dart_tool', 'build', '.git', '.idea',
    '/NFL', '/NDL', '/NJH', '/NJS', '/NP'
)
& robocopy @robocopyArgs | Out-Null
if ($LASTEXITCODE -ge 8) {
    throw "robocopy failed with exit code $LASTEXITCODE."
}

Invoke-Flutter -Flutter $flutter -Arguments @('pub', 'get') -WorkingDirectory $AsciiWorkDirectory
Invoke-Flutter -Flutter $flutter -Arguments @('analyze') -WorkingDirectory $AsciiWorkDirectory
