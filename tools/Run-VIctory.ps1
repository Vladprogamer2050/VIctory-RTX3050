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

if (-not (Test-Path -LiteralPath $VictoryExe)) { throw "Release executable missing. Run: cargo build --release -p victory" }
if (-not (Test-Path -LiteralPath $GameExe)) { throw "Game executable not found: $GameExe" }
if (-not (Test-Path -LiteralPath $SdkDll)) { throw "D3D12 Agility SDK missing. Run: cargo xtask agility" }

$env:VICTORY_CACHE_DIR = Join-Path $env:LOCALAPPDATA 'victory\cache'
$env:VICTORY_DATA_DIR = Join-Path $env:LOCALAPPDATA 'victory\data'
New-Item -ItemType Directory -Force -Path $env:VICTORY_CACHE_DIR, $env:VICTORY_DATA_DIR | Out-Null

$Switches = @(
    'VICTORY_GPU_TIMING', 'VICTORY_CAPTURE', 'VICTORY_CAPTURE_FRAMES',
    'VICTORY_DUMP_TARGETS', 'VICTORY_KEYS', 'VICTORY_LATE_WAIT',
    'VICTORY_WIDE_BACK', 'VICTORY_CARD_FETCH_INFLIGHT',
    'VICTORY_LEVELS_ON_DEMAND', 'VICTORY_INPLACE',
    'VICTORY_INDIRECT_WINDOW', 'VICTORY_WAVE_WIDE'
)
foreach ($Name in $Switches) { Remove-Item "Env:$Name" -ErrorAction SilentlyContinue }

if ($Profile -eq 'baseline') { $env:VICTORY_RELAY = '0' }
else { $env:VICTORY_RELAY = '2' }

$Os = Get-CimInstance Win32_OperatingSystem
$FreeRamGb = [math]::Round($Os.FreePhysicalMemory / 1MB, 2)
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Log = Join-Path $env:TEMP ("victory-{0}-{1}.log" -f $Profile, $Stamp)
$StdOut = Join-Path $env:TEMP ("victory-{0}-{1}.stdout.tmp" -f $Profile, $Stamp)
$StdErr = Join-Path $env:TEMP ("victory-{0}-{1}.stderr.tmp" -f $Profile, $Stamp)

Write-Host "VIctory profile : $Profile"
Write-Host "Game            : $GameExe"
Write-Host "Available RAM   : $FreeRamGb GB"
Write-Host "Log             : $Log"
if ($FreeRamGb -lt 3) { Write-Warning 'Less than 3 GB of physical RAM is free. Close heavy apps before entering the world.' }

# Capture native stdout/stderr separately. PowerShell 7 otherwise may turn
# ordinary Rust stderr log lines into NativeCommandError records.
$ExitCode = 1
Push-Location $RepoRoot
try {
    $ArgumentLine = 'run "{0}" --execute' -f $GameExe
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
