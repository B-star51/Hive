#Requires -Version 5.1
<#
.SYNOPSIS
    Hive - Privilege Escalation Watchdog (multi-agent demo).

.DESCRIPTION
    Loads identity/AD events through a pluggable provider, runs detection
    agents (role change, token misuse, lateral movement), correlates their
    signals into incidents, and recommends containment actions.

    The data source is selected in config/settings.json. The demo ships with
    synthetic local logs; Azure Graph and Sentinel providers are stubbed so the
    same agents can run against real cloud data later with no code changes.

.EXAMPLE
    .\Invoke-Hive.ps1

.EXAMPLE
    .\Invoke-Hive.ps1 -ConfigPath .\config\settings.json
#>
[CmdletBinding()]
param(
    [string]$ConfigPath,
    [switch]$Html        # also generate a standalone HTML dashboard and open it
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
if (-not $ConfigPath) { $ConfigPath = Join-Path $root 'config\settings.json' }

# --- load the codebase (model, providers, agents, core) ---
. "$root\src\Core\EventModel.ps1"
. "$root\src\Providers\LocalJsonProvider.ps1"
. "$root\src\Providers\AzureGraphProvider.ps1"
. "$root\src\Providers\SentinelProvider.ps1"
. "$root\src\Agents\RoleChangeAgent.ps1"
. "$root\src\Agents\TokenMisuseAgent.ps1"
. "$root\src\Agents\LateralMovementAgent.ps1"
. "$root\src\Agents\CorrelationAgent.ps1"
. "$root\src\Agents\ResponseAgent.ps1"
. "$root\src\Core\HiveCore.ps1"
. "$root\src\Core\HiveReport.ps1"
. "$root\src\Core\HiveHtmlReport.ps1"

function Write-Section { param([string]$Text)
    Write-Host ""
    Write-Host "==== $Text ====" -ForegroundColor Cyan
}
function Get-SeverityColor { param([string]$s)
    switch ($s) { 'Critical' {'Red'} 'High' {'Magenta'} 'Medium' {'Yellow'} default {'Gray'} }
}

Write-Host ""
Write-Host "  H I V E  -  Privilege Escalation Watchdog" -ForegroundColor White
Write-Host "  ------------------------------------------" -ForegroundColor DarkGray

$config = Get-HiveConfig -Path $ConfigPath

$activeSource =
    if     ($config.dataSource.use_local_logs) { 'LocalJsonProvider (synthetic logs)' }
    elseif ($config.dataSource.use_azure_graph){ 'AzureGraphProvider' }
    elseif ($config.dataSource.use_sentinel)   { 'SentinelProvider' }
    else                                       { 'NONE' }
Write-Host "  Data source: $activeSource" -ForegroundColor DarkGray

# 1. Ingest + normalize
$events = @(Get-HiveEvents -Config $config -RootPath $root)
Write-Section "Ingest"
Write-Host ("Normalized {0} events from the active provider." -f $events.Count)

# 2. Run detection agents
$signals = @(Invoke-HiveAgents -Events $events)
Write-Section "Agent signals ($($signals.Count))"
if (-not $signals) {
    Write-Host "No suspicious activity detected." -ForegroundColor Green
}
foreach ($s in ($signals | Sort-Object Timestamp)) {
    Write-Host ("[{0}] {1} {2}" -f $s.Severity, $s.RuleId, $s.Title) -ForegroundColor (Get-SeverityColor $s.Severity)
    Write-Host ("    {0:HH:mm} {1}" -f $s.Timestamp, $s.Description) -ForegroundColor Gray
    Write-Host ("    ATT&CK: {0} ({1})" -f $s.MitreTechnique, $s.MitreTechniqueName) -ForegroundColor DarkCyan
}

# 3. Correlate into incidents
$incidents = @(Invoke-CorrelationAgent -Signals $signals `
    -WindowMinutes $config.correlation.windowMinutes `
    -ScoreThreshold $config.correlation.incidentScoreThreshold)

Write-Section "Correlated incidents"
foreach ($i in $incidents) {
    $tag = if ($i.Escalated) { 'ESCALATED' } else { 'watch' }
    Write-Host ("{0}  entity='{1}'  score={2}  agents={3}  [{4}]" -f `
        $i.Severity, $i.Entity, $i.Score, ($i.AgentsFired -join ','), $tag) `
        -ForegroundColor (Get-SeverityColor $i.Severity)
    if ($i.Escalated) {
        Write-Host ("    Tactics: {0}" -f ($i.Tactics -join ' -> ')) -ForegroundColor DarkCyan
        Write-Host  "    Attack chain:" -ForegroundColor DarkGray
        foreach ($step in $i.AttackChain) {
            Write-Host ("      {0:HH:mm}  {1,-9} {2}  {3}" -f `
                $step.Time, $step.Technique, $step.RuleId, $step.Step) -ForegroundColor Gray
        }
    }
}

# 4. Response recommendations
$responses = @(Invoke-ResponseAgent -Incidents $incidents)
Write-Section "Recommended response"
if (-not $responses) {
    Write-Host "No incident crossed the escalation threshold." -ForegroundColor Green
}
foreach ($r in $responses) {
    Write-Host ("Incident: '{0}'  (severity {1}, score {2})" -f $r.Entity, $r.Severity, $r.Score) -ForegroundColor White
    foreach ($a in $r.RecommendedActions) { Write-Host "    - $a" -ForegroundColor Gray }
    Write-Host ("    AutoContainment: {0} (advisory-only demo)" -f $r.AutoContainment) -ForegroundColor DarkGray
}

# Optional HTML dashboard
if ($Html) {
    $report   = Get-HiveReport -Config $config -RootPath $root
    $htmlPath = Join-Path $root 'report.html'
    New-HiveHtmlReport -Report $report -Path $htmlPath | Out-Null
    Write-Section "HTML report"
    Write-Host "Wrote $htmlPath" -ForegroundColor Green
    Start-Process $htmlPath
}

Write-Host ""
