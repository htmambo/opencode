Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$pidBackend = Join-Path $PSScriptRoot "opencode-backend.pid"
$pidWeb = Join-Path $PSScriptRoot "opencode-web.pid"

$action = $args[0]
if ([string]::IsNullOrWhiteSpace($action)) { $action = "start" }

function Is-Running([string]$pidFile) {
  if (-not (Test-Path $pidFile)) { return $false }
  $id = Get-Content $pidFile -ErrorAction SilentlyContinue
  if (-not $id) { return $false }
  return $null -ne (Get-Process -Id $id -ErrorAction SilentlyContinue)
}

function Start-Backend() {
  if (Is-Running $pidBackend) { return }
  $p = Start-Process -PassThru -WorkingDirectory (Join-Path $root "packages/opencode") -FilePath "bun" -ArgumentList @("run","--conditions=browser","./src/index.ts","serve","--port","4096")
  Set-Content -Path $pidBackend -Value $p.Id
}

function Start-Web() {
  if (Is-Running $pidWeb) { return }
  $p = Start-Process -PassThru -WorkingDirectory (Join-Path $root "packages/app") -FilePath "bun" -ArgumentList @("dev","--","--port","4444")
  Set-Content -Path $pidWeb -Value $p.Id
}

function Stop-ByPid([string]$pidFile) {
  if (-not (Test-Path $pidFile)) { return }
  $id = Get-Content $pidFile -ErrorAction SilentlyContinue
  if ($id) {
    $proc = Get-Process -Id $id -ErrorAction SilentlyContinue
    if ($null -ne $proc) { Stop-Process -Id $id -Force }
  }
  Remove-Item $pidFile -ErrorAction SilentlyContinue
}

function Print-All() {
  Write-Host "Backend: http://localhost:4096"
  Write-Host "App: http://localhost:4444"
}

function Print-Web() { Write-Host "App: http://localhost:4444" }
function Print-Backend() { Write-Host "Backend: http://localhost:4096" }

switch ($action.ToLowerInvariant()) {
  "start" { Start-Backend; Start-Web; Print-All }
  "restart" { Stop-ByPid $pidBackend; Stop-ByPid $pidWeb; Start-Backend; Start-Web; Print-All }
  "stop" { Stop-ByPid $pidBackend; Stop-ByPid $pidWeb }
  "web" { Stop-ByPid $pidWeb; Start-Web; Print-Web }
  "backend" { Stop-ByPid $pidBackend; Start-Backend; Print-Backend }
  default {
    Write-Host "Usage: dev.ps1 [start|stop|restart|web|backend]"
    exit 1
  }
}
