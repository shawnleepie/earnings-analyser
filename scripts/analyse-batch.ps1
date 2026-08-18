# analyse-batch.ps1
#
# Runs /analyse-earnings sequentially and unattended for a specified list of
# tickers. Unlike backfill-batch.ps1, this always requires an explicit
# -Tickers list - there's no sensible "run analysis on everyone" default,
# since analysis should be targeted at companies whose results you actually
# want analysed right now, not run blindly across the whole cares list.
#
# For any ticker with a complete archive already, /analyse-earnings itself
# skips straight past fetch/extraction into the four analysis agents,
# synthesis, PDF generation, and Telegram delivery - much faster than a
# full backfill+analysis run.
#
# CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS=0 is set below because Claude Code's
# own -p (headless) mode has an internal 600-second ceiling on how long it
# waits for background subagent tasks before force-terminating them. Long
# synthesis/extraction steps (especially on same-day-released results) can
# exceed that, causing a silent mid-write failure. Setting this to 0 makes
# it wait indefinitely instead, relying on our own script-level timeout
# below as the real safety net.
#
# Usage:
#   .\scripts\analyse-batch.ps1 -Tickers SRG,SKS
#   .\scripts\analyse-batch.ps1 -Tickers SRG,SKS -TimeoutMinutes 90
#
param(
    [Parameter(Mandatory=$true)]
    [string[]]$Tickers,
    [int]$TimeoutMinutes = 90
)
#
$ProjectPath = "C:\Users\Shawn\OneDrive - Pie Funds NZ\Agents\Earnings analyser\files"
$LogDir = Join-Path $ProjectPath "logs"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$LogFile = Join-Path $LogDir "analyse-batch-$(Get-Date -Format 'yyyy-MM-dd_HHmmss').log"
#
function Log($msg) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    Write-Output $line
    Add-Content -Path $LogFile -Value $line
}
#
Set-Location $ProjectPath
$env:CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS = "0"
#
$listenerRunning = Get-CimInstance Win32_Process -Filter "Name='python.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match "telegram_listener\.py" }
if ($listenerRunning) {
    Log "ABORTING: a telegram_listener.py process is already running (PID $($listenerRunning.ProcessId)). Stop it first, then re-run this script."
    exit 1
}
#
$otherBatchRunning = Get-CimInstance Win32_Process -Filter "Name='claude.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match "backfill-archive|analyse-earnings" }
if ($otherBatchRunning) {
    Log "ABORTING: another headless claude backfill/analyse process is already running (PID $($otherBatchRunning.ProcessId)). Wait for it to finish first."
    exit 1
}
#
Log "=== Analysis batch starting: $($Tickers.Count) ticker(s) queued: $($Tickers -join ', ') ==="
#
$results = @()
#
foreach ($ticker in $Tickers) {
    $analysisDir = Join-Path $ProjectPath "archive\$ticker\analysis"
#
    $preRunTime = Get-Date
    Start-Sleep -Milliseconds 500
#
    Log "$ticker - starting /analyse-earnings..."
#
    $stdoutLog = Join-Path $LogDir "$ticker-analyse-stdout.log"
    $stderrLog = Join-Path $LogDir "$ticker-analyse-stderr.log"
#
    $proc = Start-Process -FilePath "claude" -ArgumentList @(
        "-p", "`"/analyse-earnings $ticker`"",
        "--allowedTools", "WebSearch", "WebFetch", "Read", "Write", "Bash",
        "--max-turns", "150"
    ) -WorkingDirectory $ProjectPath -PassThru -NoNewWindow `
      -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog
#
    $finished = $proc.WaitForExit($TimeoutMinutes * 60 * 1000)
#
    if (-not $finished) {
        Log "$ticker - TIMED OUT after $TimeoutMinutes minutes. Killing process $($proc.Id)."
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        $results += "$ticker : TIMED OUT"
        Start-Sleep -Seconds 5
        continue
    }
#
    $freshReport = $null
    if (Test-Path $analysisDir) {
        $freshReport = Get-ChildItem -Path $analysisDir -Filter "*.md" -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -gt $preRunTime } |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
    }
#
    if ($freshReport) {
        Log "$ticker - DONE. Report freshly written: $($freshReport.Name) at $($freshReport.LastWriteTime). Exit code: $($proc.ExitCode)."
        $results += "$ticker : done ($($freshReport.Name))"
    } else {
        Log "$ticker - WARNING: no fresh report written this run (exit code $($proc.ExitCode)). An old report may exist from a prior day but does not count. Check $stdoutLog and $stderrLog."
        $results += "$ticker : WARNING - no fresh report produced this run"
    }
#
    Start-Sleep -Seconds 5
}
#
Log "=== Analysis batch complete ==="
foreach ($r in $results) { Log $r }
Log "Full log: $LogFile"