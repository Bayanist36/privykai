param(
    [switch]$Universal
)

. (Join-Path $PSScriptRoot 'common.ps1')

$projectRoot = Get-ProjectRoot
$flutter = Resolve-Flutter
Initialize-AndroidEnvironment -ProjectRoot $projectRoot

$keyProperties = Join-Path $projectRoot 'android\key.properties'
$hasReleaseKey = Test-Path -LiteralPath $keyProperties
if (-not $hasReleaseKey) {
    Write-Warning 'android/key.properties is missing: this build is signed with the debug key and is not publishable.'
    Write-Warning 'Run scripts/generate_release_keystore.ps1 when the owner approves the release key.'
}

Invoke-Flutter -Flutter $flutter -Arguments @('pub', 'get') -WorkingDirectory $projectRoot

# Drop stale artifacts so a previous universal or x86_64 APK is never shipped
# or verified as part of this RC.
$apkDirectory = Join-Path $projectRoot 'build\app\outputs\flutter-apk'
if (Test-Path -LiteralPath $apkDirectory) {
    Get-ChildItem -LiteralPath $apkDirectory -File |
        Where-Object { $_.Name -match '^app(-.*)?-release\.apk$' } |
        Remove-Item -Force
}

$arguments = @('build', 'apk', '--release')
if (-not $Universal) {
    # RuStore needs ARM devices only; two split APKs stay well below 30 MB.
    # x86_64 is not shipped (BUG-10).
    $arguments += @(
        '--split-per-abi',
        '--target-platform', 'android-arm,android-arm64'
    )
}
Invoke-Flutter -Flutter $flutter -Arguments $arguments -WorkingDirectory $projectRoot

$verifyArguments = @{}
if (-not $hasReleaseKey) {
    $verifyArguments['AllowDebugSignature'] = $true
}
& (Join-Path $PSScriptRoot 'verify_release_apk.ps1') @verifyArguments

Write-Host ''
Write-Host "Release APKs: $apkDirectory"
Get-ChildItem -LiteralPath $apkDirectory -Filter 'app-*-release.apk' -File |
    ForEach-Object {
        Write-Host ("  {0} ({1:N1} MB)" -f $_.Name, ($_.Length / 1MB))
    }
