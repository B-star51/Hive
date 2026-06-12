# TokenMisuseAgent.ps1
# Detects Kerberos ticket reuse from an unexpected host - a classic
# pass-the-ticket / token-theft indicator. It maps where each user's TGT was
# issued, then flags service tickets requested from a different host.

function Invoke-TokenMisuseAgent {
    [CmdletBinding()]
    param([object[]]$Events)
    if (-not $Events) { return }

    $tokenEvents = $Events | Where-Object { $_.EventType -eq 'TokenUse' }

    # First TGT issuance host per user.
    $tgtHostByUser = @{}
    foreach ($t in ($tokenEvents | Where-Object { $_.TokenType -eq 'Kerberos-TGT' } | Sort-Object Timestamp)) {
        if (-not $tgtHostByUser.ContainsKey($t.TargetUser)) {
            $tgtHostByUser[$t.TargetUser] = $t.SourceHost
        }
    }

    foreach ($st in ($tokenEvents | Where-Object { $_.TokenType -eq 'Kerberos-ST' })) {
        $issuedHost = $tgtHostByUser[$st.TargetUser]
        if ($issuedHost -and $st.SourceHost -and $issuedHost -ne $st.SourceHost) {
            New-HiveSignal -Agent 'TokenMisuseAgent' -Severity 'High' -RuleId 'TM-001' `
                -Title "Kerberos ticket used from unexpected host" `
                -Description ("TGT for '$($st.TargetUser)' was issued from $issuedHost but a service " +
                              "ticket was later requested from $($st.SourceHost) (possible pass-the-ticket).") `
                -Entity $st.TargetUser -RelatedEntities @($issuedHost, $st.SourceHost) `
                -Timestamp $st.Timestamp -Evidence $st
        }
    }
}
