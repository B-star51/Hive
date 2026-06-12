# CorrelationAgent.ps1
# Hive's brain. It cross-links signals from every other agent by primary entity
# (the user), scores them, and raises an Incident. Corroboration across multiple
# agents is the strongest escalation indicator, so it gets a score bonus.

function Invoke-CorrelationAgent {
    [CmdletBinding()]
    param(
        [object[]]$Signals,
        [int]$WindowMinutes = 60,
        [int]$ScoreThreshold = 50
    )
    if (-not $Signals) { return }

    $incidents = foreach ($g in ($Signals | Group-Object Entity)) {
        $agents = @($g.Group.Agent | Sort-Object -Unique)
        $score  = ($g.Group | ForEach-Object { Get-HiveSeverityWeight $_.Severity } |
                   Measure-Object -Sum).Sum
        if ($agents.Count -ge 2) { $score += 25 }   # multi-agent corroboration bonus

        $severity = if ($score -ge 100) { 'Critical' }
                    elseif ($score -ge $ScoreThreshold) { 'High' }
                    else { 'Low' }

        [PSCustomObject]@{
            Entity      = $g.Name
            Score       = $score
            Severity    = $severity
            Escalated   = ($score -ge $ScoreThreshold)
            AgentsFired = $agents
            SignalCount = $g.Count
            FirstSeen   = ($g.Group.Timestamp | Measure-Object -Minimum).Minimum
            LastSeen    = ($g.Group.Timestamp | Measure-Object -Maximum).Maximum
            Signals     = $g.Group
        }
    }

    $incidents | Sort-Object Score -Descending
}
