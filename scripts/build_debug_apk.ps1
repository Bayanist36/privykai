param(
    [string]$OutputDirectory = ''
)

. (Join-Path $PSScriptRoot 'common.ps1')

$projectRoot = Get-ProjectRoot
$flutter = Resolve-Flutter
Initialize-AndroidEnvironment -ProjectRoot $projectRoot

Invoke-Flutter -Flutter $flutter -Arguments @('pub', 'get') -WorkingDirectory $projectRoot
Invoke-Flutter -Flutter $flutter -Arguments @('build', 'apk', '--debug') -WorkingDirectory $projectRoot

$apkPath = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-debug.apk'
if (-not (Test-Path -LiteralPath $apkPath)) {
    throw "Build finished but APK was not found at $apkPath."
}

if ($OutputDirectory) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    Copy-Item -LiteralPath $apkPath -Destination $OutputDirectory -Force
    $apkPath = Join-Path $OutputDirectory 'app-debug.apk'
}

Write-Host "Debug APK: $apkPath"
