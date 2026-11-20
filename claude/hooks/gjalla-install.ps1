# Installs or upgrades the standalone gjalla CLI binary on native Windows:
#   powershell -NoProfile -ExecutionPolicy Bypass -File gjalla-install.ps1 -PluginRoot <plugin root>
#
# The Windows counterpart of gjalla-install.sh, with the same rules: runs only when the plugin carries
# gjalla-install.json, started in the background by gjalla.sh at session start. The download URL comes only from
# that file, never from the environment: <host>/downloads/gjalla-<cli_version>-win-x64.exe, checked against
# <same URL>.sha256 before it is installed. Installs to %USERPROFILE%\.local\bin\gjalla.exe (added to the user PATH
# so git hooks and new terminals find it) and records the version in %USERPROFILE%\.gjalla\cli-binary-version.
# A gjalla this script did not install is never replaced. Uses the Windows certificate store for TLS.
param([Parameter(Mandatory = $true)][string]$PluginRoot)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'  # Windows PowerShell 5.1 downloads far slower with the progress bar on

function Fail([string]$Message) {
  [Console]::Error.WriteLine("gjalla-install: $Message")
  exit 1
}

$manifest = Join-Path $PluginRoot 'gjalla-install.json'
if (-not (Test-Path -LiteralPath $manifest)) { exit 0 }
try { $cfg = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json } catch { Fail "unreadable gjalla-install.json" }

$hostUrl = ([string]$cfg.host).TrimEnd('/')
$version = [string]$cfg.cli_version
# https only; plain http just for a loopback host.
if ($hostUrl -notmatch '^(https://[A-Za-z0-9.-]+(:[0-9]+)?|http://(127\.0\.0\.1|localhost)(:[0-9]+)?)$') {
  Fail "host in gjalla-install.json must be an https origin: '$hostUrl'"
}
if ($version -notmatch '^[0-9A-Za-z][0-9A-Za-z.+-]{0,31}$') { Fail "bad cli_version: '$version'" }
# Only win-x64 is built; Windows on ARM runs it under emulation.
if (-not [Environment]::Is64BitOperatingSystem) { Fail "32-bit Windows is not supported" }

$binDir = Join-Path $env:USERPROFILE '.local\bin'
$target = Join-Path $binDir 'gjalla.exe'
$state = Join-Path $env:USERPROFILE '.gjalla'
$marker = Join-Path $state 'cli-binary-version'
if (Test-Path -LiteralPath $target) {
  if (-not (Test-Path -LiteralPath $marker)) { exit 0 }  # not ours
  if ((Get-Content -LiteralPath $marker -Raw).Trim() -eq $version) { exit 0 }
} elseif (Get-Command gjalla -ErrorAction SilentlyContinue) {
  exit 0  # the user's own gjalla wins
}

New-Item -ItemType Directory -Force -Path $binDir, $state | Out-Null
$lock = Join-Path $state 'cli-install.lock'
# A lock older than 10 minutes belongs to an install that was killed.
$held = Get-Item -LiteralPath $lock -ErrorAction SilentlyContinue
if ($held -and $held.CreationTime -lt (Get-Date).AddMinutes(-10)) { Remove-Item -LiteralPath $lock -Force -Recurse }
try { New-Item -ItemType Directory -Path $lock -ErrorAction Stop | Out-Null } catch { exit 0 }  # another session is installing

$tmp = Join-Path $binDir (".gjalla-download-" + [guid]::NewGuid().ToString('N'))
try {
  New-Item -ItemType Directory -Path $tmp | Out-Null
  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
  $asset = "gjalla-$version-win-x64.exe"
  $url = "$hostUrl/downloads/$asset"
  $sumFile = Join-Path $tmp 'sum'
  $exe = Join-Path $tmp 'gjalla.exe'
  try { Invoke-WebRequest -Uri "$url.sha256" -OutFile $sumFile -UseBasicParsing -TimeoutSec 300 } catch { Fail "download failed: $url.sha256" }
  try { Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing -TimeoutSec 300 } catch { Fail "download failed: $url" }

  $expected = ((Get-Content -LiteralPath $sumFile -Raw).Trim() -split '\s+')[0].ToLowerInvariant()
  if ($expected -notmatch '^[0-9a-f]{64}$') { Fail "no SHA-256 in $url.sha256" }
  $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $exe).Hash.ToLowerInvariant()
  if ($actual -ne $expected) { Fail "checksum mismatch for ${asset}: expected $expected, got $actual; not installed" }

  # A running gjalla.exe can't be overwritten but can be renamed; the old copy is removed on a later run.
  $old = "$target.old"
  Remove-Item -LiteralPath $old -Force -ErrorAction SilentlyContinue
  if (Test-Path -LiteralPath $target) { Move-Item -LiteralPath $target -Destination $old -Force }
  Move-Item -LiteralPath $exe -Destination $target
  [IO.File]::WriteAllText($marker, "$version`n")  # LF, the same bytes gjalla-install.sh writes

  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if (-not (($userPath -split ';') -contains $binDir)) {
    $newPath = if ($userPath) { "$($userPath.TrimEnd(';'));$binDir" } else { $binDir }
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
  }
  [Console]::Error.WriteLine("gjalla-install: installed $asset to $target")
  # The binary unpacks itself once per version; doing it here keeps that off the next hook's clock.
  try { & $target --version *> $null } catch { Fail "installed $target, but it did not run" }
} finally {
  Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $lock -Recurse -Force -ErrorAction SilentlyContinue
}
