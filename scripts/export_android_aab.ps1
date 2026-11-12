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

$godot = Join-Path $env:LOCALAPPDATA "Programs/Godot/Godot_v4.7.2-stable_win64_console.exe"
if (-not (Test-Path -LiteralPath $godot)) {
    $godot = (Get-Command godot*console.exe -ErrorAction Stop).Source
}
$project = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
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
