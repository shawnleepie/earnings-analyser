# backfill-batch.ps1
#
# Runs /backfill-archive sequentially and unattended for companies in
# config/companies.yaml, in file order. Safe to stop (Ctrl+C) and re-run —
# skips any ticker that already has enough periods archived. Each company
# gets its own timeout so one stuck run can't block the rest indefinitely.
# Backfill-only by design: builds historical archive for all companies
# first; analysis-on-demand for a specific release already works via the
# Telegram trigger, so there's no need to also run full analysis on 29
# companies' current periods in the same overnight batch.
#
# Usage:
#   .\scripts\backfill-batch.ps1                        # all tickers, list order, skip already-archived
#   .\scripts\backfill-batch.ps1 -Tickers SKS,GNP,IPG    # only these, in this order
#   .\scripts\backfill-batch.ps1 -TimeoutMinutes 150     # override per-company timeout (default 120)
#   .\scripts\backfill-batch.ps1 -Force                  # re-run even already-archived tickers

param(
    [string[]]$Tickers = @(),
    [int]$TimeoutMinutes = 120,
    [int]$MinPeriodsToSkip = 4,
    [switch]$Force
)

$ProjectPath = "C:\Users\Shawn\OneDrive - Pie Funds NZ\Agents\Earnings analyser\files"
$LogDir = Join-Path $ProjectPath "logs"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$LogFile = Join-Path $LogDir "backfill-batch-$(Get-Date -Format 'yyyy-MM-dd_HHmmss').log"

function Log($msg) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    Write-Output $line
    Add-Content -Path $LogFile -Value $line
}

Set-Location $ProjectPath

$listenerRunning = Get-CimInstance Win32_Process -Filter "Name='python.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match "telegram_listener\.py" }
if ($listenerRunning) {
    Log "ABORTING: a telegram_listener.py process is already running (PID $($listenerRunning.ProcessId)). Stop it first (Ctrl+C in its window, or Stop-Process -Id $($listenerRunning.ProcessId) -Force), then re-run this script."
    exit 1
}

if ($Tickers.Count -eq 0) {
    $yamlContent = Get-Content "config\companies.yaml" -Raw
    $Tickers = [regex]::Matches($yamlContent, '(?m)^\s*-\s*ticker:\s*(\S+)') | ForEach-Object { $_.Groups[1].Value }
}

Log "=== Batch backfill starting: $($Tickers.Count) ticker(s) queued: $($Tickers -join ', ') ==="

$results = @()

foreach ($ticker in $Tickers) {
    $archivePath = Join-Path $ProjectPath "archive\$ticker"
    $periodCount = 0
    if (Test-Path $archivePath) {
        $periodCount = (Get-ChildItem -Path $archivePath -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne "analysis" }).Count
    }

    if (-not $Force -and $periodCount -ge $MinPeriodsToSkip) {
        Log "$ticker - SKIPPED (already has $periodCount period(s) archived)."
        $results += "$ticker : skipped ($periodCount periods already archived)"
        continue
    }

    Log "$ticker - starting backfill (currently $periodCount period(s) archived)..."

    $stdoutLog = Join-Path $LogDir "$ticker-stdout.log"
    $stderrLog = Join-Path $LogDir "$ticker-stderr.log"

    $proc = Start-Process -FilePath "claude" -ArgumentList @(
        "-p", "`"/backfill-archive $ticker`"",
        "--allowedTools", "WebSearch", "WebFetch", "Read", "Write", "Bash",
        "--max-turns", "150"
    ) -WorkingDirectory $ProjectPath -PassThru -NoNewWindow `
      -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog

    $finished = $proc.WaitForExit($TimeoutMinutes * 60 * 1000)

    if (-not $finished) {
        Log "$ticker - TIMED OUT after $TimeoutMinutes minutes. Killing process $($proc.Id)."
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        $results += "$ticker : TIMED OUT"
        Start-Sleep -Seconds 5
        continue
    }

    $newPeriodCount = 0
    if (Test-Path $archivePath) {
        $newPeriodCount = (Get-ChildItem -Path $archivePath -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne "analysis" }).Count
    }

    if ($newPeriodCount -gt $periodCount) {
        Log "$ticker - DONE. Periods archived: $newPeriodCount (was $periodCount). Exit code: $($proc.ExitCode)."
        $results += "$ticker : done ($newPeriodCount periods)"
    } else {
        Log "$ticker - WARNING: exited (code $($proc.ExitCode)) but no new periods detected. Check $stdoutLog / $stderrLog manually."
        $results += "$ticker : WARNING - no progress detected"
    }

    Start-Sleep -Seconds 5
}

Log "=== Batch backfill complete ==="
foreach ($r in $results) { Log $r }
Log "Full log: $LogFile"