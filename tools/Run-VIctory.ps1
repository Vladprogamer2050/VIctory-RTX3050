[CmdletBinding()]
param(
    [ValidateSet('balanced', 'baseline')]
    [string]$Profile = 'balanced',
    [string]$GameExe = 'D:\GTA6\GTA6.Xbox.v1.0.2.1-CYBERLEEK\game_scarlett_master.exe'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$VictoryExe = Join-Path $RepoRoot 'target\release\victory.exe'
$SdkDll = Join-Path $RepoRoot 'target\release\D3D12\D3D12Core.dll'

if (-not (Test-Path -LiteralPath $VictoryExe)) {
    throw "Release executable missing. Run: cargo build --release -p victory"
}
if (-not (Test-Path -LiteralPath $GameExe)) {
    throw "Game executable not found: $GameExe"
}
if (-not (Test-Path -LiteralPath $SdkDll)) {
    throw "D3D12 Agility SDK missing. Run: cargo xtask agility"
}

# Keep caches and save data outside the source tree.
$env:VICTORY_CACHE_DIR = Join-Path $env:LOCALAPPDATA 'victory\cache'
$env:VICTORY_DATA_DIR = Join-Path $env:LOCALAPPDATA 'victory\data'
New-Item -ItemType Directory -Force -Path $env:VICTORY_CACHE_DIR, $env:VICTORY_DATA_DIR | Out-Null

# Remove stale capture/debug/performance switches inherited from this shell.
$Switches = @(
    'VICTORY_GPU_TIMING', 'VICTORY_CAPTURE', 'VICTORY_CAPTURE_FRAMES',
    'VICTORY_DUMP_TARGETS', 'VICTORY_KEYS', 'VICTORY_LATE_WAIT',
    'VICTORY_WIDE_BACK', 'VICTORY_CARD_FETCH_INFLIGHT',
    'VICTORY_LEVELS_ON_DEMAND', 'VICTORY_INPLACE',
    'VICTORY_INDIRECT_WINDOW', 'VICTORY_WAVE_WIDE'
)
foreach ($Name in $Switches) {
    Remove-Item "Env:$Name" -ErrorAction SilentlyContinue
}

# Baseline disables the relay; balanced enables the upstream-tested stage 2.
if ($Profile -eq 'baseline') {
    $env:VICTORY_RELAY = '0'
} else {
    $env:VICTORY_RELAY = '2'
}

$Os = Get-CimInstance Win32_OperatingSystem
$FreeRamGb = [math]::Round($Os.FreePhysicalMemory / 1MB, 2)
$Log = Join-Path $env:TEMP ("victory-{0}-{1}.log" -f $Profile, (Get-Date -Format 'yyyyMMdd-HHmmss'))

Write-Host "VIctory profile : $Profile"
Write-Host "Game            : $GameExe"
Write-Host "Available RAM   : $FreeRamGb GB"
Write-Host "Log             : $Log"
if ($FreeRamGb -lt 3) {
    Write-Warning 'Less than 3 GB of physical RAM is free. Close heavy apps before entering the world.'
}

Push-Location $RepoRoot
try {
    & $VictoryExe run $GameExe --execute 2>&1 | Tee-Object -FilePath $Log
    $ExitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}
Write-Host "VIctory exit code: $ExitCode"
Write-Host "Log saved to: $Log"
exit $ExitCode
