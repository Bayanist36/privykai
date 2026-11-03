Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ProjectRoot {
    return Split-Path -Parent $PSScriptRoot
}

function Resolve-Flutter {
    $command = Get-Command flutter -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    $candidates = @(
        (Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat'),
        'D:\dev\flutter\bin\flutter.bat',
        'C:\flutter\bin\flutter.bat'
    )

    if ($env:FLUTTER_ROOT) {
        $candidates = @((Join-Path $env:FLUTTER_ROOT 'bin\flutter.bat')) + $candidates
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    throw 'Flutter SDK not found. Add flutter to PATH or set FLUTTER_ROOT.'
}

function Initialize-AndroidEnvironment {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    if (-not $env:ANDROID_HOME -and -not $env:ANDROID_SDK_ROOT) {
        $sdkCandidates = @('D:\dev\android-sdk')

        $localProperties = Join-Path $ProjectRoot 'android\local.properties'
        if (Test-Path -LiteralPath $localProperties) {
            $sdkLine = Get-Content -LiteralPath $localProperties |
                Where-Object { $_ -match '^sdk\.dir=' } |
                Select-Object -First 1
            if ($sdkLine) {
                $sdkValue = $sdkLine -replace '^sdk\.dir=', ''
                $sdkCandidates += ($sdkValue -replace '\\\\', '\')
            }
        }

        foreach ($candidate in $sdkCandidates) {
            if (Test-Path -LiteralPath $candidate) {
                $env:ANDROID_HOME = $candidate
                $env:ANDROID_SDK_ROOT = $candidate
                break
            }
        }
    }

    if (-not $env:JAVA_HOME) {
        $javaHomes = @(Get-ChildItem -Path 'C:\Program Files\Java' -Directory -Filter 'jdk-*' -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending)
        foreach ($javaHome in $javaHomes) {
            if (Test-Path -LiteralPath (Join-Path $javaHome.FullName 'bin\java.exe')) {
                $env:JAVA_HOME = $javaHome.FullName
                break
            }
        }
    }

    # Keep Gradle caches off the small system disk on this machine.
    if (-not $env:GRADLE_USER_HOME -and (Test-Path -LiteralPath 'D:\dev\gradle-home')) {
        $env:GRADLE_USER_HOME = 'D:\dev\gradle-home'
    }

    if (-not $env:JAVA_HOME) {
        throw 'JAVA_HOME is not set and no JDK was found in C:\Program Files\Java.'
    }
}

function Invoke-Flutter {
    param(
        [Parameter(Mandatory = $true)][string]$Flutter,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory
    )

    Push-Location -LiteralPath $WorkingDirectory
    try {
        & $Flutter @Arguments
        $exitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    if ($exitCode -ne 0) {
        throw "flutter $($Arguments -join ' ') failed with exit code $exitCode."
    }
}
