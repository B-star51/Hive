# HiveReport.ps1
# Produces a clean, serializable report object for machine consumers (the
# Microsoft 365 Copilot agent / API action). Same engine as the console run -
# this just shapes the output as JSON-friendly data instead of colored text.

function Get-HiveReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Config,
        [Parameter(Mandatory)][string]$RootPath
    )

    $activeSource =
        if     ($Config.dataSource.use_local_logs)  { 'LocalJsonProvider' }
        elseif ($Config.dataSource.use_azure_graph) { 'AzureGraphProvider' }
        elseif ($Config.dataSource.use_sentinel)    { 'SentinelProvider' }
        else                                        { 'None' }

    $events    = @(Get-HiveEvents -Config $Config -RootPath $RootPath)
    $signals   = @(Invoke-HiveAgents -Events $events)
    $incidents = @(Invoke-CorrelationAgent -Signals $signals `
                    -WindowMinutes  $Config.correlation.windowMinutes `
                    -ScoreThreshold $Config.correlation.incidentScoreThreshold)
    $responses = @(Invoke-ResponseAgent -Incidents $incidents)

    [PSCustomObject]@{
        generatedAt = (Get-Date).ToString('o')
        dataSource  = $activeSource
        eventCount  = $events.Count
        signals     = @($signals | ForEach-Object {
            [PSCustomObject]@{
                agent       = $_.Agent
                severity    = $_.Severity
                ruleId      = $_.RuleId
                title       = $_.Title
                description = $_.Description
                entity      = $_.Entity
                timestamp   = $_.Timestamp.ToString('o')
            }
        })
        incidents   = @($incidents | ForEach-Object {
            [PSCustomObject]@{
                entity      = $_.Entity
                severity    = $_.Severity
                score       = $_.Score
                escalated   = $_.Escalated
                agentsFired = $_.AgentsFired
                signalCount = $_.SignalCount
                firstSeen   = $_.FirstSeen.ToString('o')
                lastSeen    = $_.LastSeen.ToString('o')
            }
        })
        responses   = @($responses | ForEach-Object {
            [PSCustomObject]@{
                entity             = $_.Entity
                severity           = $_.Severity
                score              = $_.Score
                recommendedActions = @($_.RecommendedActions)
            }
        })
    }
}
