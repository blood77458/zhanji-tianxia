# Install the patched APK into MuMu (default adb serial 127.0.0.1:16384)
param(
    [string]$Device = "127.0.0.1:16384",
    [string]$Apk = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not (Test-Path (Join-Path $PSScriptRoot "..\client"))) {
    $Root = Resolve-Path (Join-Path $PSScriptRoot "..")
} else {
    $Root = Resolve-Path (Join-Path $PSScriptRoot "..")
}

if (-not $Apk) {
    $cand = @(
        (Join-Path $Root "client\zjt_pack_enablefix_signed.apk"),
        (Join-Path $Root "work\zjt_pack_enablefix_signed.apk")
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $cand) { throw "APK not found. Put zjt_pack_enablefix_signed.apk under client\ (see README)." }
    $Apk = $cand
}

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) { $adb = "adb" }

$pkg = "com.happyelements.canon.baiduDK"
Write-Host "Installing $Apk -> $Device"
& $adb -s $Device install -r $Apk
& $adb -s $Device shell am start -n "$pkg/com.happyelements.arda.MainActivity"
Write-Host "Done."
