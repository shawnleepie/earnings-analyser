# run-smoketest-then-batch.ps1
#
# Runs backfill-batch.ps1 scoped to a single smoke-test ticker first. Only
# if that ticker ends up with enough archived periods does it proceed to
# the full unattended batch (all remaining companies.yaml tickers). If the
# smoke test fails, it stops there and logs why, rather than burning hours
# unattended on a script that isn't actually working.

param(
    [string]$SmokeTestTicker = "IPG",
    [int]$PassThreshold = 3
)

$ProjectPath = "C:\Users\Shawn\OneDrive - Pie Funds NZ\Agents\Earnings analyser\files"
Set-Location $ProjectPath

Write-Output "=== SMOKE TEST: running $SmokeTestTicker alone first ==="
& "$ProjectPath\scripts\backfill-batch.ps1" -Tickers $SmokeTestTicker

$smokePath = Join-Path $ProjectPath "archive\$SmokeTestTicker"
$smokePeriods = 0
if (Test-Path $smokePath) {
    $smokePeriods = (Get-ChildItem -Path $smokePath -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "analysis" }).Count
}

if ($smokePeriods -ge $PassThreshold) {
    Write-Output "=== SMOKE TEST PASSED ($smokePeriods periods archived for $SmokeTestTicker) - proceeding to full batch ==="
    & "$ProjectPath\scripts\backfill-batch.ps1"
} else {
    Write-Output "=== SMOKE TEST FAILED (only $smokePeriods period(s) archived for $SmokeTestTicker, needed $PassThreshold) ==="
    Write-Output "=== NOT proceeding to full batch. Check logs\ for $SmokeTestTicker-stdout.log / $SmokeTestTicker-stderr.log before retrying. ==="
}