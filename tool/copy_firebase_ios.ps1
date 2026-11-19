param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('dev', 'staging', 'production')]
    [string]$Env
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root "firebase/$Env/GoogleService-Info.plist"
$destination = Join-Path $root 'ios/Runner/GoogleService-Info.plist'

if (-not (Test-Path $source)) {
    throw "Missing $source. Copy the .example file and fill in Firebase console values."
}

Copy-Item -Path $source -Destination $destination -Force
Write-Host "Copied $source -> $destination"
