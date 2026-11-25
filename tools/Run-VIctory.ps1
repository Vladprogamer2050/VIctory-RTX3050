[CmdletBinding()]
param(
    [ValidateSet('balanced', 'baseline', 'indirect-window', 'indirect-window-check', 'indirect-window-copy')]
    [string]$Profile = 'balanced',
    [ValidateSet('release', 'diag')]
    [string]$BuildProfile = 'release',
    [ValidateSet('series-x', 'series-s')]
    [string]$Console = 'series-x',
    [string]$GameExe = 'game_scarlett_master.exe'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$BuildDir = Join-Path $RepoRoot (Join-Path 'target' $BuildProfile)
$VictoryExe = Join-Path $BuildDir 'victory.exe'
$SdkDll = Join-Path $BuildDir 'D3D12\D3D12Core.dll'
if ($BuildProfile -eq 'diag' -and -not (Test-Path -LiteralPath $SdkDll)) {
    $ReleaseSdkDll = Join-Path $RepoRoot 'target\release\D3D12\D3D12Core.dll'
    if (Test-Path -LiteralPath $ReleaseSdkDll) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $SdkDll) | Out-Null
        Copy-Item -LiteralPath $ReleaseSdkDll -Destination $SdkDll
    }
}
if (-not [System.IO.Path]::IsPathRooted($GameExe)) { $GameExe = Join-Path $RepoRoot $GameExe }

if (-not (Test-Path -LiteralPath $VictoryExe)) {
    $BuildHint = if ($BuildProfile -eq 'diag') { 'cargo build --profile diag -p victory --features diagnostics' } else { 'cargo build --release -p victory' }
    throw "$BuildProfile executable missing. Run: $BuildHint"
}
if (-not (Test-Path -LiteralPath $GameExe)) { throw "Game executable not found: $GameExe" }
if (-not (Test-Path -LiteralPath $SdkDll)) { throw "D3D12 Agility SDK missing. Run: cargo xtask agility" }

$env:VICTORY_CACHE_DIR = Join-Path $env:LOCALAPPDATA 'victory\cache'
$env:VICTORY_DATA_DIR = Join-Path $env:LOCALAPPDATA 'victory\data'
New-Item -ItemType Directory -Force -Path $env:VICTORY_CACHE_DIR, $env:VICTORY_DATA_DIR | Out-Null

$Switches = @(
    'VICTORY_GPU_TIMING', 'VICTORY_CAPTURE', 'VICTORY_CAPTURE_FRAMES',
    'VICTORY_DUMP_TARGETS', 'VICTORY_KEYS', 'VICTORY_LATE_WAIT',
    'VICTORY_WIDE_BACK', 'VICTORY_CARD_FETCH_INFLIGHT',
    'VICTORY_LEVELS_ON_DEMAND', 'VICTORY_INPLACE', 'VICTORY_COPY_PLAIN',
    'VICTORY_FAST_CORES', 'VICTORY_DISK_CORES', 'VICTORY_FRAME_LOG',
    'VICTORY_CARD_METER', 'VICTORY_PROFILE',
    'VICTORY_INDIRECT_WINDOW', 'VICTORY_INDIRECT_WINDOW_CHECK', 'VICTORY_WAVE_WIDE'
)
foreach ($Name in $Switches) { Remove-Item "Env:$Name" -ErrorAction SilentlyContinue }

if ($Profile -eq 'baseline') { $env:VICTORY_RELAY = '0' }
else { $env:VICTORY_RELAY = '2' }

if ($Profile -in @('indirect-window', 'indirect-window-check', 'indirect-window-copy')) {
    $env:VICTORY_INDIRECT_WINDOW = '1'
}
if ($Profile -eq 'indirect-window-copy') {
    $env:VICTORY_COPY_PLAIN = '1'
}
if ($Profile -eq 'indirect-window-check') {
    $env:VICTORY_INDIRECT_WINDOW_CHECK = '1'
}

$Os = Get-CimInstance Win32_OperatingSystem
$FreeRamGb = [math]::Round($Os.FreePhysicalMemory / 1MB, 2)
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Log = Join-Path $env:TEMP ("victory-{0}-{1}.log" -f $Profile, $Stamp)
$StdOut = Join-Path $env:TEMP ("victory-{0}-{1}.stdout.tmp" -f $Profile, $Stamp)
$StdErr = Join-Path $env:TEMP ("victory-{0}-{1}.stderr.tmp" -f $Profile, $Stamp)

Write-Host "VIctory profile : $Profile"
Write-Host "Build profile   : $BuildProfile"
Write-Host "Console model   : $Console"
Write-Host "Executable      : $VictoryExe"
Write-Host "Game            : $GameExe"
Write-Host "Available RAM   : $FreeRamGb GB"
Write-Host "Log             : $Log"
if ($FreeRamGb -lt 3) { Write-Warning 'Less than 3 GB of physical RAM is free. Close heavy apps before entering the world.' }

# Capture native stdout/stderr separately. PowerShell 7 otherwise may turn
# ordinary Rust stderr log lines into NativeCommandError records.
$ExitCode = 1
Push-Location $RepoRoot
try {
    $ArgumentLine = 'run --console {0} "{1}" --execute' -f $Console, $GameExe
    $Process = Start-Process -FilePath $VictoryExe -ArgumentList $ArgumentLine -WorkingDirectory $RepoRoot -NoNewWindow -Wait -PassThru -RedirectStandardOutput $StdOut -RedirectStandardError $StdErr
    $ExitCode = $Process.ExitCode
    $Combined = @()
    if (Test-Path -LiteralPath $StdOut) { $Combined += Get-Content -LiteralPath $StdOut }
    if (Test-Path -LiteralPath $StdErr) { $Combined += Get-Content -LiteralPath $StdErr }
    $Combined | Set-Content -LiteralPath $Log -Encoding UTF8
    if ($Combined.Count -gt 0) { $Combined | ForEach-Object { Write-Host $_ } }
}
finally {
    Pop-Location
    Remove-Item $StdOut, $StdErr -Force -ErrorAction SilentlyContinue
}
Write-Host "VIctory exit code: $ExitCode"
Write-Host "Log saved to: $Log"
exit $ExitCode
