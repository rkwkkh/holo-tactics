$ErrorActionPreference = "Stop"

$required = @(
    "GODOT_ANDROID_KEYSTORE_RELEASE_PATH",
    "GODOT_ANDROID_KEYSTORE_RELEASE_USER",
    "GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD"
)
foreach ($name in $required) {
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
        throw "Missing required signing environment variable: $name"
    }
}
if (-not (Test-Path -LiteralPath $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH -PathType Leaf)) {
    throw "The release keystore path does not exist."
}

$project = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godotName = "Godot_v4.7.2-stable_win64_console.exe"
$godot = Join-Path $env:LOCALAPPDATA "Programs/Godot/$godotName"
if (-not (Test-Path -LiteralPath $godot)) {
    $packageRoot = Join-Path $env:LOCALAPPDATA "Microsoft/WinGet/Packages"
    $godot = Get-ChildItem -Path $packageRoot -Directory -Filter "GodotEngine.GodotEngine*" -ErrorAction SilentlyContinue |
        ForEach-Object { Join-Path $_.FullName $godotName } |
        Where-Object { Test-Path -LiteralPath $_ } |
        Select-Object -First 1
}

if (-not $godot) {
    $command = Get-Command $godotName -ErrorAction SilentlyContinue
    if ($command) { $godot = $command.Source }
}
if (-not $godot) {
    throw "Godot 4.7.2 console executable was not found. Install it or add it to PATH."
}
$presets = Get-Content -LiteralPath (Join-Path $project "export_presets.cfg") -Raw
if ($presets.Contains('package/unique_name="com.example.holotactics"')) {
    throw "Replace the sample Android package ID in both export presets before preparing a Play AAB."
}
if ($presets -notmatch '(?s)\[preset\.1\.options\][^\[]*target_sdk="36"') {
    throw "The Play AAB preset must target API 36 before export under the current Google Play policy."
}

$output = Join-Path $project "build/holo-release.aab"
New-Item -ItemType Directory -Path (Split-Path $output) -Force | Out-Null
$godotArgs = @("--headless", "--path", $project)
if (-not (Test-Path -LiteralPath (Join-Path $project "android/build/.build_version") -PathType Leaf)) {
    $godotArgs += "--install-android-build-template"
}
$godotArgs += @("--export-release", "Android Play AAB", $output)

& $godot @godotArgs
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $output -PathType Leaf)) {
    throw "Godot failed to export the Android AAB."
}

$jarsigner = (Get-Command jarsigner.exe -ErrorAction Stop).Source
$verification = & $jarsigner -verify -verbose -certs $output 2>&1
if ($LASTEXITCODE -ne 0 -or ($verification -join "`n") -notmatch "jar verified") {
    throw "The exported AAB signature could not be verified."
}
Write-Output "Signed Android AAB exported and verified: $output"
