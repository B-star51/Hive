# EventModel.ps1
# ---------------------------------------------------------------------------
# The shared data contract for all of Hive.
#
# Providers translate raw source data into NormalizedEvent objects.
# Agents only ever read NormalizedEvent objects and emit HiveSignal objects.
# Because of this, swapping LocalJson -> AzureGraph -> Sentinel never requires
# touching a single line of agent logic.
# ---------------------------------------------------------------------------

function New-NormalizedEvent {
    [CmdletBinding()]
    param(
        [datetime]$Timestamp = (Get-Date),
        [ValidateSet('RoleChange','Authentication','TokenUse','PrivilegeAssignment','Unknown')]
        [string]$EventType = 'Unknown',
        [string]$Source = 'LocalAD',     # LocalAD | AzureAD | M365 | Sentinel
        [string]$Actor,                  # who performed the action
        [string]$TargetUser,             # subject account
        [string]$TargetGroup,            # group / role touched (role changes)
        [string]$SourceHost,             # origin host or IP
        [string]$TargetHost,             # destination host
        [string]$TokenType,              # Kerberos-TGT | Kerberos-ST | OAuth | Refresh
        [string]$TokenId,
        [string]$Result = 'Success',
        [int]$EventId,
        $Raw
    )
    [PSCustomObject]@{
        Timestamp  = $Timestamp
        EventType  = $EventType
        Source     = $Source
        Actor      = $Actor
        TargetUser = $TargetUser
        TargetGroup= $TargetGroup
        SourceHost = $SourceHost
        TargetHost = $TargetHost
        TokenType  = $TokenType
        TokenId    = $TokenId
        Result     = $Result
        EventId    = $EventId
        Raw        = $Raw
    }
}

function New-HiveSignal {
    [CmdletBinding()]
    param(
        [string]$Agent,
        [ValidateSet('Low','Medium','High','Critical')]
        [string]$Severity = 'Low',
        [string]$RuleId,
        [string]$Title,
        [string]$Description,
        [string]$Entity,                 # primary entity for correlation (usually the user)
        [string[]]$RelatedEntities,
        [datetime]$Timestamp = (Get-Date),
        [string]$MitreTactic,            # ATT&CK tactic, e.g. 'Privilege Escalation'
        [string]$MitreTechnique,         # ATT&CK technique id, e.g. 'T1098'
        [string]$MitreTechniqueName,     # e.g. 'Account Manipulation'
        $Evidence
    )
    [PSCustomObject]@{
        Agent              = $Agent
        Severity           = $Severity
        RuleId             = $RuleId
        Title              = $Title
        Description        = $Description
        Entity             = $Entity
        RelatedEntities    = $RelatedEntities
        Timestamp          = $Timestamp
        MitreTactic        = $MitreTactic
        MitreTechnique     = $MitreTechnique
        MitreTechniqueName = $MitreTechniqueName
        Evidence           = $Evidence
    }
}

function Get-HiveSeverityWeight {
    param([string]$Severity)
    switch ($Severity) {
        'Low'      { 10 }
        'Medium'   { 25 }
        'High'     { 50 }
        'Critical' { 80 }
        default    { 0 }
    }
}
