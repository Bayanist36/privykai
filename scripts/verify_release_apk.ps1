param(
    [string]$ApkDirectory = '',
    [switch]$AllowDebugSignature
)

. (Join-Path $PSScriptRoot 'common.ps1')

$projectRoot = Get-ProjectRoot
Initialize-AndroidEnvironment -ProjectRoot $projectRoot

if (-not $ApkDirectory) {
    $ApkDirectory = Join-Path $projectRoot 'build\app\outputs\flutter-apk'
}
if (-not (Test-Path -LiteralPath $ApkDirectory)) {
    throw "APK directory not found: $ApkDirectory"
}

# Prefer the ABI splits. A stale universal app-release.apk from an older build
# must not hide (or fail) the actual RC artifacts.
$apks = @(Get-ChildItem -LiteralPath $ApkDirectory -Filter 'app-*-release.apk' -File)
if ($apks.Count -eq 0) {
    $apks = @(Get-ChildItem -LiteralPath $ApkDirectory -Filter 'app-release.apk' -File)
}
if ($apks.Count -eq 0) {
    throw "No release APKs found in $ApkDirectory. Run scripts/build_release_apk.ps1 first."
}

$buildTools = Get-ChildItem -Path (Join-Path $env:ANDROID_HOME 'build-tools') -Directory |
    Sort-Object Name -Descending |
    Select-Object -First 1
if ($null -eq $buildTools) {
    throw 'Android build-tools were not found.'
}

$apksigner = Join-Path $buildTools.FullName 'apksigner.bat'
$aapt2 = Join-Path $buildTools.FullName 'aapt2.exe'
if (-not (Test-Path -LiteralPath $apksigner)) {
    throw "apksigner not found: $apksigner"
}
if (-not (Test-Path -LiteralPath $aapt2)) {
    throw "aapt2 not found: $aapt2"
}

$failed = $false
$summary = @()

foreach ($apk in $apks) {
    Write-Host ''
    Write-Host "== $($apk.Name) =="

    $sizeMb = [math]::Round($apk.Length / 1MB, 1)
    Write-Host "  Size: $sizeMb MB"
    if ($sizeMb -gt 30) {
        Write-Warning "  $($apk.Name) is larger than 30 MB; check the ABI split."
    }

    $badging = & $aapt2 dump badging $apk.FullName
    $labelLine = $badging | Where-Object { $_ -match '^application-label:' } | Select-Object -First 1
    $packageLine = $badging | Where-Object { $_ -match '^package:' } | Select-Object -First 1
    $nativeLine = $badging | Where-Object { $_ -match '^native-code:' } | Select-Object -First 1
    Write-Host "  $packageLine"
    Write-Host "  $labelLine"
    if ($nativeLine) {
        Write-Host "  $nativeLine"
    }

    if ($labelLine -notmatch 'Привыкай') {
        Write-Error "  Label is not 'Привыкай': $labelLine" -ErrorAction Continue
        $failed = $true
    }

    $resources = & $aapt2 dump resources $apk.FullName
    $hasNotificationIcon = ($resources | Select-String -Pattern 'drawable/ic_notification' -SimpleMatch) -ne $null
    if (-not $hasNotificationIcon) {
        Write-Error '  drawable/ic_notification is missing: reminders will fail in release (BUG-02).' -ErrorAction Continue
        $failed = $true
    }
    else {
        Write-Host '  drawable/ic_notification: present'
    }

    $hasAdaptiveForeground = ($resources | Select-String -Pattern 'drawable/ic_launcher_foreground' -SimpleMatch) -ne $null
    if (-not $hasAdaptiveForeground) {
        Write-Error '  Adaptive launcher foreground is missing (BUG-11).' -ErrorAction Continue
        $failed = $true
    }
    else {
        Write-Host '  adaptive launcher icon: present'
    }

    $hasInternet = ($badging | Select-String -Pattern 'android.permission.INTERNET' -SimpleMatch) -ne $null
    if ($hasInternet) {
        Write-Error '  INTERNET permission found in a release APK.' -ErrorAction Continue
        $failed = $true
    }

    # Static reminder smoke: the plugin needs its receivers, boot permission
    # and the kept notification icon in the release artifact.
    $manifest = & $aapt2 dump xmltree --file AndroidManifest.xml $apk.FullName
    $manifestText = ($manifest | Out-String)
    $reminderManifestParts = @(
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.RECEIVE_BOOT_COMPLETED',
        'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver',
        'com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver'
    )
    foreach ($part in $reminderManifestParts) {
        if ($manifestText -notmatch [regex]::Escape($part)) {
            Write-Error "  Reminder manifest part is missing: $part" -ErrorAction Continue
            $failed = $true
        }
    }
    Write-Host '  reminder receivers and permissions: present'

    $signerOutput = & $apksigner verify --print-certs $apk.FullName 2>&1
    $signerExit = $LASTEXITCODE
    $signerText = ($signerOutput | Out-String)
    if ($signerExit -ne 0) {
        Write-Error "  apksigner verification failed:`n$signerText" -ErrorAction Continue
        $failed = $true
        $summary += "$($apk.Name): signature invalid ($sizeMb MB)"
        continue
    }

    $certificateLine = ($signerText -split "`n" | Where-Object { $_ -match 'certificate DN' } | Select-Object -First 1)
    Write-Host "  $($certificateLine.Trim())"
    if ($signerText -match 'Android Debug') {
        if ($AllowDebugSignature) {
            Write-Warning '  Signed with the debug key (allowed for this QA build only).'
        }
        else {
            Write-Error '  Signed with the debug key. Configure android/key.properties (BUG-03).' -ErrorAction Continue
            $failed = $true
        }
        $summary += "$($apk.Name): DEBUG signature, $sizeMb MB"
    }
    else {
        $summary += "$($apk.Name): company signature, $sizeMb MB"
    }
}

Write-Host ''
if ($failed) {
    throw 'Release APK verification failed. See the errors above.'
}

Write-Host 'Release APK verification passed:'
$summary | ForEach-Object { Write-Host "  $_" }
