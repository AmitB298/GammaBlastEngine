<#  Fix-TogglesImport.ps1
    - Fix "from ..config import ..." -> "from ...config import ..." in toggles.py
    - Backup, optional verification (Python import, API calls), optional pytest
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [Parameter(Mandatory = $true)]
  [string]$Root,
  [string]$PythonExe = "python",
  [string]$ApiBase   = "http://127.0.0.1:8000",
  [switch]$NoVerify,
  [switch]$RunTests
)

$ErrorActionPreference = "Stop"

function Info([string]$m){ Write-Host "[INFO ] $m" -ForegroundColor Cyan }
function Ok  ([string]$m){ Write-Host "[ OK  ] $m" -ForegroundColor Green }
function Warn([string]$m){ Write-Host "[WARN ] $m" -ForegroundColor Yellow }
function Fail([string]$m){ Write-Host "[FAIL ] $m" -ForegroundColor Red }

$rootPath  = (Resolve-Path $Root).Path
$togglesPy = Join-Path $rootPath "gamma_blast_engine\service\routers\toggles.py"
if (-not (Test-Path $togglesPy)) { Fail "File not found: $togglesPy"; exit 1 }

Info "Root : $rootPath"
Info "File : $togglesPy"

# Read content
$content = Get-Content $togglesPy -Raw -Encoding utf8

# Multiline patterns (match at start of any line)
$patOk   = '(?m)^\s*from\s+\.\.\.\s*config\s+import\s+'
$patBad  = '(?m)^\s*from\s+\.\.\s*config\s+import\s+'

$alreadyOk = $content -match $patOk
$needsFix  = $content -match $patBad

if ($alreadyOk) {
  Ok "Import already correct (from ...config import ...). Nothing to change."
}
elseif ($needsFix) {
  $fixed = $content -creplace $patBad, 'from ...config import '
  if ($PSCmdlet.ShouldProcess($togglesPy, "Fix relative import to use three dots")) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = "$togglesPy.bak-$stamp"
    Copy-Item $togglesPy $backup -Force
    Info "Backup saved: $backup"

    Set-Content -LiteralPath $togglesPy -Value $fixed -Encoding utf8
    Ok "Updated import to 'from ...config import ...'."
  }
}
else {
  # Fallback: conservative token replace if the exact pattern wasn’t matched
  if ($content -like '*from ..config import*') {
    $fixed = $content -replace 'from \.\.config import','from ...config import'
    if ($PSCmdlet.ShouldProcess($togglesPy, "Fallback token replace '..config' -> '...config'")) {
      $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
      $backup = "$togglesPy.bak-$stamp"
      Copy-Item $togglesPy $backup -Force
      Info "Backup saved: $backup"

      Set-Content -LiteralPath $togglesPy -Value $fixed -Encoding utf8
      Ok "Updated import via fallback replace."
    }
  } else {
    Warn "Did not find a 'from ..config import' line to change. No edit performed."
  }
}

if ($NoVerify) { Info "Verification skipped by -NoVerify."; Ok "Fix-TogglesImport completed."; exit 0 }

# Verify Python import
try {
  Info "Verifying Python import using '$PythonExe'"
  $pyCmd = @'
import gamma_blast_engine.service.routers.toggles as m
print("IMPORT_OK")
'@
  $out = & $PythonExe -c $pyCmd 2>&1
  if ($LASTEXITCODE -ne 0 -or -not ($out -match 'IMPORT_OK')) {
    Fail "Python import failed:`n$out"; exit 2
  } else { Ok "Python import succeeded." }
} catch { Fail "Python not available or import crashed: $($_.Exception.Message)"; exit 2 }

# If server running, exercise /api/toggles
$healthUrl = "$ApiBase/health"
try {
  Info "Checking if server is running at $healthUrl"
  $health = Invoke-WebRequest $healthUrl -UseBasicParsing -TimeoutSec 2
  if ($health.StatusCode -ge 200 -and $health.StatusCode -lt 300) {
    Ok "Server reachable. Exercising /api/toggles..."
    $getUrl = "$ApiBase/api/toggles"
    $getResp = Invoke-RestMethod $getUrl
    Ok ("GET /api/toggles -> " + ($getResp | ConvertTo-Json -Compress))

    $putBody = @{ sentiment_enabled = $true } | ConvertTo-Json -Compress
    $putResp = Invoke-RestMethod $getUrl -Method Put -ContentType "application/json" -Body $putBody
    Ok ("PUT /api/toggles -> " + ($putResp | ConvertTo-Json -Compress))

    $togglesPath = Join-Path $rootPath "configs\defaults.toggles.json"
    if (Test-Path $togglesPath) {
      $disk = Get-Content $togglesPath -Raw
      Ok "Disk contents of defaults.toggles.json:`n$disk"
    } else {
      Warn "Expected toggles file not found at $togglesPath (check Settings.toggles_path)."
    }
  } else {
    Warn "Server responded with status $($health.StatusCode). Skipping API verify."
  }
} catch { Warn "Server not reachable; skipping API verify." }

# Optional: run pytest
if ($RunTests) {
  try {
    Info "Running pytest -q"; & pytest -q
    if ($LASTEXITCODE -eq 0) { Ok "pytest passed." } else { Fail "pytest reported failures." }
  } catch { Warn "pytest not available or failed to run: $($_.Exception.Message)" }
}

Ok "Fix-TogglesImport completed."
