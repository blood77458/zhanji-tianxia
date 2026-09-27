param(
  [Parameter(Mandatory)][string]$Url,
  [Parameter(Mandatory)][string]$OutFile,
  [int]$Segments = 24,
  [int]$MaxMinutes = 90
)
$ErrorActionPreference = 'Stop'
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
$partDir = "$OutFile.parts"
New-Item -ItemType Directory -Force -Path $partDir | Out-Null

# --- determine total size ---
$lenTxt = & curl.exe -sS -I -A $ua --max-time 30 $Url 2>$null | Select-String -Pattern '^Content-Length:' | Select-Object -First 1
if (-not $lenTxt) { throw "cannot determine Content-Length" }
$Total = [int64](($lenTxt -split ':')[1].Trim())
Write-Host "[seg] url        : $Url"
Write-Host "[seg] total size : $Total bytes ($([math]::Round($Total/1MB,2)) MB)"

$chunk = [math]::Ceiling($Total / $Segments)
$ranges = @()
for ($i = 0; $i -lt $Segments; $i++) {
  $s = [int64]$i * $chunk
  if ($s -ge $Total) { break }
  $e = [math]::Min($s + $chunk - 1, $Total - 1)
  $ranges += [pscustomobject]@{ Index = $i; Start = $s; End = $e; Want = $e - $s + 1; Part = (Join-Path $partDir ("{0:D3}.part" -f $i)) }
}

# --- launch parallel curl jobs (skip already-complete parts) ---
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$jobs = @()
foreach ($r in $ranges) {
  if ((Test-Path $r.Part) -and ((Get-Item $r.Part).Length -eq $r.Want)) {
    Write-Host "[seg] part $($r.Index) already complete, skipping"
    continue
  }
  $jobs += Start-Job -ScriptBlock {
    param($u, $ua, $s, $e, $p)
    & curl.exe -sS -A $ua --max-time 3600 --retry 5 --retry-delay 3 --retry-all-errors `
      -r "$s-$e" -o $p $u
    if ($LASTEXITCODE -ne 0) { "FAIL $LASTEXITCODE" } else { "OK" }
  } -ArgumentList $Url, $ua, $r.Start, $r.End, $r.Part
}

# --- monitor ---
$deadline = (Get-Date).AddMinutes($MaxMinutes)
while (($jobs | Where-Object { $_.State -eq 'Running' }).Count -gt 0 -and (Get-Date) -lt $deadline) {
  Start-Sleep -Seconds 15
  $have = 0
  foreach ($r in $ranges) { if (Test-Path $r.Part) { $have += (Get-Item $r.Part).Length } }
  $pct = if ($Total -gt 0) { [math]::Round(100 * $have / $Total, 1) } else { 0 }
  $rate = if ($sw.Elapsed.TotalSeconds -gt 0) { [math]::Round($have / $sw.Elapsed.TotalSeconds / 1KB) } else { 0 }
  Write-Host ("[seg] {0,5:N1}%  {1,7:N1}/{2:N1} MB  {3,5} KB/s  {4:N1} min elapsed" -f $pct, ($have/1MB), ($Total/1MB), $rate, $sw.Elapsed.TotalMinutes)
}
$jobs | Wait-Job -Timeout 60 | Out-Null
$jobs | Remove-Job -Force
$sw.Stop()

# --- verify all parts ---
$missing = @()
foreach ($r in $ranges) {
  if (-not (Test-Path $r.Part) -or (Get-Item $r.Part).Length -ne $r.Want) {
    $got = if (Test-Path $r.Part) { (Get-Item $r.Part).Length } else { 0 }
    $missing += "part $($r.Index): want $($r.Want) got $got"
  }
}
if ($missing.Count -gt 0) {
  Write-Host "[seg] INCOMPLETE:"; $missing | ForEach-Object { Write-Host "   $_" }
  exit 2
}

# --- merge in order ---
Write-Host "[seg] merging $($ranges.Count) parts -> $OutFile"
$out = [System.IO.File]::Create($OutFile)
try {
  foreach ($r in ($ranges | Sort-Object Index)) {
    $in = [System.IO.File]::OpenRead($r.Part)
    try { $in.CopyTo($out) } finally { $in.Dispose() }
  }
} finally { $out.Dispose() }

$finalLen = (Get-Item $OutFile).Length
Write-Host "[seg] merged size : $finalLen (expected $Total)"
if ($finalLen -ne $Total) { Write-Host "[seg] SIZE MISMATCH"; exit 3 }
Write-Host "[seg] MD5         : $((Get-FileHash $OutFile -Algorithm MD5).Hash)"
Write-Host "[seg] SHA256      : $((Get-FileHash $OutFile -Algorithm SHA256).Hash)"
Write-Host "[seg] DONE in $([math]::Round($sw.Elapsed.TotalMinutes,1)) min"
