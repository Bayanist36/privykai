. (Join-Path $PSScriptRoot 'common.ps1')

$projectRoot = Get-ProjectRoot
$flutter = Resolve-Flutter
Initialize-AndroidEnvironment -ProjectRoot $projectRoot

Invoke-Flutter -Flutter $flutter -Arguments @('pub', 'get') -WorkingDirectory $projectRoot
Invoke-Flutter -Flutter $flutter -Arguments @('test') -WorkingDirectory $projectRoot
& (Join-Path $PSScriptRoot 'analyze.ps1')
& (Join-Path $PSScriptRoot 'build_debug_apk.ps1')

Write-Host 'Verification complete: tests passed, analysis is clean, debug APK built.'
