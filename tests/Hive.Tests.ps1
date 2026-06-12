# Hive.Tests.ps1  (Pester v5)
# Proves the detection engine is deterministic and safe. Run with:
#   Invoke-Pester .\tests\Hive.Tests.ps1
# or  .\tests\Invoke-Tests.ps1

BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
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

    $script:config    = Get-HiveConfig -Path "$root\config\settings.json"
    $script:events    = @(Get-HiveEvents -Config $config -RootPath $root)
    $script:signals   = @(Invoke-HiveAgents -Events $events)
    $script:incidents = @(Invoke-CorrelationAgent -Signals $signals `
                            -WindowMinutes $config.correlation.windowMinutes `
                            -ScoreThreshold $config.correlation.incidentScoreThreshold)
}

Describe 'LocalJsonProvider' {
    It 'normalizes every sample event' {
        $events.Count | Should -Be 11
    }
    It 'maps event id 4728 to a RoleChange' {
        ($events | Where-Object EventId -eq 4728)[0].EventType | Should -Be 'RoleChange'
    }
    It 'Azure/Sentinel providers are stubs that throw NotImplemented' {
        { Invoke-AzureGraphProvider -Config @{} } | Should -Throw
        { Invoke-SentinelProvider   -Config @{} } | Should -Throw
    }
}

Describe 'RoleChangeAgent' {
    It 'flags addition to Domain Admins as Critical (off-hours, service acct)' {
        $s = $signals | Where-Object RuleId -eq 'RC-001'
        $s.Entity   | Should -Be 'jdoe'
        $s.Severity | Should -Be 'Critical'
    }
    It 'ignores non-privileged group changes (bsmith -> Marketing)' {
        ($signals | Where-Object { $_.Entity -eq 'bsmith' }).Count | Should -Be 0
    }
    It 'tags the signal with ATT&CK T1098' {
        ($signals | Where-Object RuleId -eq 'RC-001').MitreTechnique | Should -Be 'T1098'
    }
}

Describe 'TokenMisuseAgent' {
    It 'detects Kerberos ticket reuse from a different host' {
        $s = $signals | Where-Object RuleId -eq 'TM-001'
        $s.Entity         | Should -Be 'jdoe'
        $s.MitreTechnique | Should -Be 'T1550.003'
    }
}

Describe 'LateralMovementAgent' {
    It 'flags a non-baseline logon to a sensitive host' {
        ($signals | Where-Object RuleId -eq 'LM-001').Entity | Should -Be 'jdoe'
    }
    It 'flags failed-logon spray across 3+ hosts' {
        ($signals | Where-Object RuleId -eq 'LM-002').Entity | Should -Be 'guest'
    }
}

Describe 'CorrelationAgent' {
    It 'escalates jdoe (3 agents corroborate)' {
        $j = $incidents | Where-Object Entity -eq 'jdoe'
        $j.Escalated      | Should -BeTrue
        $j.Severity       | Should -Be 'Critical'
        $j.AgentsFired.Count | Should -Be 3
    }
    It 'does NOT escalate guest (single agent, below threshold)' {
        ($incidents | Where-Object Entity -eq 'guest').Escalated | Should -BeFalse
    }
    It 'reconstructs the attack chain in time order' {
        $chain = ($incidents | Where-Object Entity -eq 'jdoe').AttackChain
        $chain[0].RuleId        | Should -Be 'RC-001'
        $chain[-1].RuleId       | Should -Be 'LM-001'
    }
}

Describe 'ResponseAgent (safety)' {
    It 'only produces responses for escalated incidents' {
        $r = @(Invoke-ResponseAgent -Incidents $incidents)
        $r.Count        | Should -Be 1
        $r[0].Entity    | Should -Be 'jdoe'
    }
    It 'never auto-executes containment (advisory-only)' {
        $r = @(Invoke-ResponseAgent -Incidents $incidents)
        $r[0].AutoContainment | Should -BeFalse
    }
}
