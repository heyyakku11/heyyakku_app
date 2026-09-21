# Re-apply after `flutter pub get` if the firebase_core KGP warning returns.
# Flutter regex-matches `apply plugin: 'kotlin-android'` even inside guards
# (https://github.com/flutter/flutter/issues/189770). pluginManager.apply avoids that.
$ErrorActionPreference = 'Stop'
$pubCache = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { Join-Path $env:LOCALAPPDATA 'Pub\Cache' }
$buildGradle = Get-ChildItem -Path (Join-Path $pubCache 'hosted') -Recurse -Filter 'build.gradle' |
    Where-Object { $_.FullName -match 'firebase_core-[^\\]+\\android\\build\.gradle$' } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $buildGradle) {
    Write-Error 'firebase_core android/build.gradle not found in pub cache'
}

$path = $buildGradle.FullName
$content = Get-Content -Raw -Path $path
$old = "apply plugin: 'kotlin-android'"
$new = "pluginManager.apply('kotlin-android')"
if ($content -notlike "*$old*") {
    Write-Host "Already patched or unexpected content: $path"
    exit 0
}
Set-Content -Path $path -Value ($content.Replace($old, $new)) -NoNewline
Write-Host "Patched $path"
