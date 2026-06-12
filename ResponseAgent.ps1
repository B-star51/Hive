# ResponseAgent.ps1
# Turns escalated incidents into recommended containment actions. The demo is
# advisory-only (AutoContainment = $false). To make it active, wire these
# actions to AD cmdlets (Disable-ADAccount) or Graph calls (revokeSignInSessions).

function Invoke-ResponseAgent {
    [CmdletBinding()]
    param([object[]]$Incidents)
    if (-not $Incidents) { return }

    foreach ($i in ($Incidents | Where-Object { $_.Escalated })) {
        $actions = [System.Collections.Generic.List[string]]::new()

        if ($i.AgentsFired -contains 'RoleChangeAgent') {
            $actions.Add("Revert the privileged group membership change for '$($i.Entity)'.")
            $actions.Add("Require re-justification of the role grant via a PIM / approval workflow.")
        }
        if ($i.AgentsFired -contains 'TokenMisuseAgent') {
            $actions.Add("Revoke active Kerberos tickets for '$($i.Entity)' (reset krbtgt if widespread).")
            $actions.Add("Revoke OAuth / refresh tokens and force re-authentication.")
        }
        if ($i.AgentsFired -contains 'LateralMovementAgent') {
            $actions.Add("Isolate the source host and audit access to the sensitive server.")
        }
        $actions.Add("Disable account '$($i.Entity)' pending SOC review.")
        $actions.Add("Open a SOC ticket (severity: $($i.Severity)) and notify the identity team.")

        [PSCustomObject]@{
            Entity             = $i.Entity
            Severity           = $i.Severity
            Score              = $i.Score
            RecommendedActions = $actions
            AutoContainment    = $false
        }
    }
}
