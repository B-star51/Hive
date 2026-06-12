# RoleChangeAgent.ps1
# Watches for additions to privileged AD groups. Off-hours changes and changes
# made by service accounts are treated as more suspicious.

function Invoke-RoleChangeAgent {
    [CmdletBinding()]
    param([object[]]$Events)
    if (-not $Events) { return }

    $privilegedGroups = @(
        'Domain Admins', 'Enterprise Admins', 'Schema Admins',
        'Administrators', 'Account Operators', 'Backup Operators', 'DnsAdmins'
    )

    foreach ($e in ($Events | Where-Object { $_.EventType -eq 'RoleChange' })) {
        if ($privilegedGroups -notcontains $e.TargetGroup) { continue }

        $offHours = ($e.Timestamp.Hour -lt 6 -or $e.Timestamp.Hour -ge 22)
        $sev   = 'High'
        $notes = @()
        if ($offHours)               { $sev = 'Critical'; $notes += 'off-hours change' }
        if ($e.Actor -match '^svc[-_]|\$$') { $notes += "performed by service account '$($e.Actor)'" }

        $suffix = if ($notes) { ' (' + ($notes -join '; ') + ')' } else { '' }

        New-HiveSignal -Agent 'RoleChangeAgent' -Severity $sev -RuleId 'RC-001' `
            -Title "Privileged group membership change: $($e.TargetGroup)" `
            -Description "'$($e.TargetUser)' was added to '$($e.TargetGroup)' by '$($e.Actor)'.$suffix" `
            -Entity $e.TargetUser -RelatedEntities @($e.Actor, $e.TargetGroup) `
            -Timestamp $e.Timestamp -Evidence $e
    }
}
