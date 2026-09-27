# Re-bind game domains to the Windows host so the emulator can reach canon_server.
# Usage: powershell -ExecutionPolicy Bypass -File work\fix_hosts.ps1
# Run again after every emulator reboot (bind-mount is not persistent).

$ErrorActionPreference = "Continue"
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) { throw "adb not found: $adb" }

$work = Split-Path -Parent $MyInvocation.MyCommand.Path
$domains = @(
  "android1.canon.happyelements.cn",
  "android1.canon.happyelements.com",
  "log.dc.cn.happyelements.com",
  "etlog.happyelements.cn",
  "m.cn.happyelements.com"
)

function Probe-HostIp($device) {
  $candidates = @("10.0.2.2", "172.26.160.1", "192.168.1.4")
  # also try host LAN IPs on MEmuSwitch / Ethernet
  Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.PrefixOrigin -ne "WellKnown" } |
    ForEach-Object { $candidates += $_.IPAddress }
  $candidates = $candidates | Select-Object -Unique
  foreach ($ip in $candidates) {
    $r = & $adb -s $device shell "curl -s -m 2 http://${ip}/staticVersion" 2>$null
    if ($r -match "static_url_root") {
      return $ip
    }
  }
  return $null
}

function Write-HostsFile($path, $ip) {
  $lines = @(
    "127.0.0.1       localhost",
    "::1             ip6-localhost"
  )
  foreach ($d in $domains) {
    $lines += ("{0,-15} {1}" -f $ip, $d)
  }
  ($lines -join "`n") + "`n" | Set-Content -Path $path -Encoding ascii -NoNewline
}

$devices = & $adb devices | Select-String "device$" | ForEach-Object {
  ($_ -split "\s+")[0]
} | Where-Object { $_ -and $_ -ne "List" }

if (-not $devices) {
  Write-Host "No adb devices. Start MuMu / emulator first."
  exit 1
}

foreach ($dev in $devices) {
  Write-Host "==== $dev ===="
  & $adb -s $dev root 2>$null | Out-Null
  Start-Sleep 1
  if ($dev -like "127.0.0.1*") { & $adb connect $dev 2>$null | Out-Null; Start-Sleep 1 }

  $ip = Probe-HostIp $dev
  if (-not $ip) {
    Write-Host "FAIL: no host IP reachable from $dev (is canon_server on :80?)"
    continue
  }
  Write-Host "host gateway: $ip"

  $hostsPath = Join-Path $work ("hosts_{0}.txt" -f ($dev -replace "[:.]", "_"))
  Write-HostsFile $hostsPath $ip
  & $adb -s $dev push $hostsPath /data/local/tmp/hosts 2>&1 | Out-Null
  & $adb -s $dev shell "umount /system/etc/hosts 2>/dev/null; mount -o bind /data/local/tmp/hosts /system/etc/hosts" 2>&1 | Out-Null

  $check = & $adb -s $dev shell "curl -s -m 3 http://android1.canon.happyelements.cn/staticVersion" 2>$null
  if ($check -match "static_url_root") {
    Write-Host "OK: domain resolves and staticVersion responds"
  } else {
    Write-Host "FAIL: domain still unreachable after bind-mount"
    & $adb -s $dev shell "cat /system/etc/hosts"
  }
}
