# LateralMovementAgent.ps1
# Two detections:
#   LM-001  a sensitive host is accessed by an account outside its admin baseline
#   LM-002  a single account fails logon across several hosts (spray / probing)

function Invoke-LateralMovementAgent {
    [CmdletBinding()]
    param([object[]]$Events)
    if (-not $Events) { return }

    $sensitiveHosts = @('DC01', 'DC02', 'SQL01', 'FILESRV01')
    $adminBaseline  = @('administrator', 'svc-backup', 'sqladmin')  # accounts expected on those hosts

    $auth = $Events | Where-Object { $_.EventType -eq 'Authentication' }

    # LM-001 - successful logon to a sensitive host by a non-baseline account
    foreach ($e in ($auth | Where-Object { $_.Result -eq 'Success' })) {
        $target = ($e.TargetHost -replace '\..*$', '')   # strip any FQDN suffix
        if (($sensitiveHosts -contains $target) -and
            ($adminBaseline -notcontains $e.TargetUser.ToLower())) {
            New-HiveSignal -Agent 'LateralMovementAgent' -Severity 'High' -RuleId 'LM-001' `
                -Title "Sensitive host accessed by non-baseline account" `
                -Description ("'$($e.TargetUser)' logged on to sensitive host '$target' from " +
                              "'$($e.SourceHost)'. Account is not in the admin baseline for that host.") `
                -Entity $e.TargetUser -RelatedEntities @($e.SourceHost, $target) `
                -Timestamp $e.Timestamp -Evidence $e
        }
    }

    # LM-002 - failed logons spread across multiple hosts
    foreach ($g in ($auth | Where-Object { $_.Result -eq 'Failure' } | Group-Object TargetUser)) {
        $hosts = @($g.Group.TargetHost | Sort-Object -Unique)
        if ($hosts.Count -ge 3) {
            New-HiveSignal -Agent 'LateralMovementAgent' -Severity 'Medium' -RuleId 'LM-002' `
                -Title "Failed logons across multiple hosts" `
                -Description "'$($g.Name)' failed logon on $($hosts.Count) hosts: $($hosts -join ', ')." `
                -Entity $g.Name -RelatedEntities $hosts `
                -Timestamp ($g.Group.Timestamp | Measure-Object -Maximum).Maximum -Evidence $g.Group
        }
    }
}
