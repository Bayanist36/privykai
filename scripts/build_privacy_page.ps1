param(
    [string]$OperatorName = '',
    [string]$ContactEmail = '',
    [string]$EffectiveDate = '',
    [string]$OutputPath = '',
    [switch]$CheckOnly
)

. (Join-Path $PSScriptRoot 'common.ps1')

$projectRoot = Get-ProjectRoot
$templatePath = Join-Path $projectRoot 'docs\privacy\privacy-policy.template.html'
if (-not $OutputPath) {
    $OutputPath = Join-Path $projectRoot 'docs\privacy\index.html'
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $projectRoot $OutputPath
}

if (-not (Test-Path -LiteralPath $templatePath)) {
    throw "Privacy policy template not found: $templatePath"
}

if (-not $CheckOnly) {
    $OperatorName = $OperatorName.Trim()
    $ContactEmail = $ContactEmail.Trim()

    if ($OperatorName.Length -lt 2) {
        throw 'OperatorName is required. Use the full legal name of the account owner (individual, IE or company).'
    }
    if ($OperatorName -match '[{}<>]') {
        throw 'OperatorName must not contain { } < >.'
    }
    if ($ContactEmail -notmatch '^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$') {
        throw 'ContactEmail is not a valid e-mail address.'
    }

    if (-not $EffectiveDate) {
        $culture = [System.Globalization.CultureInfo]::GetCultureInfo('ru-RU')
        $EffectiveDate = (Get-Date).ToString('d MMMM yyyy', $culture)
    }

    $html = [System.IO.File]::ReadAllText($templatePath, [System.Text.Encoding]::UTF8)
    $html = [System.Text.RegularExpressions.Regex]::Replace(
        $html,
        '(?s)<!-- DRAFT_WARNING_START -->.*?<!-- DRAFT_WARNING_END -->\s*',
        ''
    )
    $html = $html.Replace('{{OPERATOR_NAME}}', [System.Net.WebUtility]::HtmlEncode($OperatorName))
    $html = $html.Replace('{{CONTACT_EMAIL}}', [System.Net.WebUtility]::HtmlEncode($ContactEmail))
    $html = $html.Replace('{{EFFECTIVE_DATE}}', [System.Net.WebUtility]::HtmlEncode($EffectiveDate))

    $outputDirectory = Split-Path -Parent $OutputPath
    if (-not (Test-Path -LiteralPath $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($OutputPath, $html, $utf8NoBom)
    Write-Host "Built: $OutputPath"
}

if (-not (Test-Path -LiteralPath $OutputPath)) {
    throw "Privacy policy page not found: $OutputPath"
}

$page = [System.IO.File]::ReadAllText($OutputPath, [System.Text.Encoding]::UTF8)
$errors = New-Object System.Collections.Generic.List[string]

if ($page.Length -lt 8000) {
    $errors.Add("The page looks too short ($($page.Length) characters).")
}
if ($page -match '\{\{|\}\}') {
    $errors.Add('Unreplaced placeholders remain in the page.')
}
if ($page -match '(?i)<html\s+lang="ru"') {
    Write-Host 'OK  language: ru'
}
else {
    $errors.Add('The page must declare <html lang="ru">.')
}
if ($page -match '(?i)<meta\s+charset="utf-8"') {
    Write-Host 'OK  encoding: utf-8'
}
else {
    $errors.Add('The page must declare UTF-8 encoding.')
}
if ($page -match '(?i)Черновик:') {
    $errors.Add('The draft warning is still present. Run the build without -CheckOnly.')
}
if ($page -match '(?i)<script|<link\s+[^>]*href=|<img\s|@import|url\s*\(|https?://') {
    $errors.Add('The page must not load external scripts, styles, images or resources.')
}
else {
    Write-Host 'OK  no external resources'
}

$requiredSections = @(
    'Общие сведения',
    'Какие данные обрабатываются',
    'Цели обработки',
    'Где и как хранятся данные',
    'Сроки хранения',
    'Удаление данных и ваши права',
    'Передача третьим лицам',
    'Безопасность',
    'Изменения Политики',
    'Контакты'
)
foreach ($section in $requiredSections) {
    if ($page.Contains($section)) {
        Write-Host "OK  section: $section"
    }
    else {
        $errors.Add("Missing section: $section")
    }
}

foreach ($phrase in @('Оператор', 'Электронная почта', 'Роскомнадзор', 'com.sukhanovlabs.habittracker')) {
    if (-not $page.Contains($phrase)) {
        $errors.Add("Missing required phrase: $phrase")
    }
}

if (-not $CheckOnly) {
    $encodedOperator = [System.Net.WebUtility]::HtmlEncode($OperatorName)
    if (-not $page.Contains($encodedOperator)) {
        $errors.Add('The operator name is not present in the page.')
    }
    if (-not $page.Contains($ContactEmail)) {
        $errors.Add('The contact e-mail is not present in the page.')
    }
}

$hash = (Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256).Hash
$sizeKb = [math]::Round((Get-Item -LiteralPath $OutputPath).Length / 1KB, 1)

Write-Host ''
if ($errors.Count -gt 0) {
    Write-Host 'Privacy policy page check FAILED:'
    $errors | ForEach-Object { Write-Host "  - $_" }
    throw 'Fix the errors above and rebuild the page.'
}

Write-Host 'Privacy policy page check passed.'
Write-Host "  File: $OutputPath"
Write-Host "  Size: $sizeKb KB"
Write-Host "  SHA256: $hash"
Write-Host ''
Write-Host 'Next steps:'
Write-Host '  1. Open the page locally and read it once in a browser.'
Write-Host '  2. Publish the docs/privacy folder using the instructions in docs/privacy/README.md.'
Write-Host '  3. Verify the public URL in an incognito window and from a phone.'
Write-Host '  4. Put the URL into the RuStore card and into the in-app privacy screen.'
