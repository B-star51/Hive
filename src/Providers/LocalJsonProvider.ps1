# LocalJsonProvider.ps1
# Reads synthetic Windows Security / AD events from a JSON file and normalizes
# them. This mirrors exactly what a real Get-WinEvent based collector would do,
# which is why the agents downstream cannot tell the difference between this and
# a live feed.

function Invoke-LocalJsonProvider {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) {
        throw "LocalJsonProvider: log file not found at '$Path'"
    }

    $raw = Get-Content -Path $Path -Raw | ConvertFrom-Json

    foreach ($e in $raw) {
        $d = $e.EventData
        switch ([int]$e.EventID) {

            { $_ -in 4728, 4732, 4756 } {   # a member was added to a security-enabled group
                New-NormalizedEvent -Timestamp ([datetime]$e.TimeCreated) -EventType 'RoleChange' `
                    -Source 'LocalAD' -EventId $e.EventID `
                    -Actor $d.SubjectUserName -TargetUser $d.MemberName `
                    -TargetGroup $d.TargetUserName -SourceHost $e.Computer -Raw $e
            }

            4672 {                          # special privileges assigned to new logon
                New-NormalizedEvent -Timestamp ([datetime]$e.TimeCreated) -EventType 'PrivilegeAssignment' `
                    -Source 'LocalAD' -EventId $e.EventID `
                    -TargetUser $d.SubjectUserName -SourceHost $e.Computer -Raw $e
            }

            4768 {                          # Kerberos TGT (authentication ticket) requested
                New-NormalizedEvent -Timestamp ([datetime]$e.TimeCreated) -EventType 'TokenUse' `
                    -Source 'LocalAD' -EventId $e.EventID -TokenType 'Kerberos-TGT' `
                    -TargetUser $d.TargetUserName -SourceHost $d.IpAddress -Raw $e
            }

            4769 {                          # Kerberos service ticket requested
                New-NormalizedEvent -Timestamp ([datetime]$e.TimeCreated) -EventType 'TokenUse' `
                    -Source 'LocalAD' -EventId $e.EventID -TokenType 'Kerberos-ST' `
                    -TargetUser $d.TargetUserName -SourceHost $d.IpAddress `
                    -TargetHost $d.ServiceName -Raw $e
            }

            { $_ -in 4624, 4625 } {         # logon success (4624) / failure (4625)
                New-NormalizedEvent -Timestamp ([datetime]$e.TimeCreated) -EventType 'Authentication' `
                    -Source 'LocalAD' -EventId $e.EventID `
                    -TargetUser $d.TargetUserName -SourceHost $d.WorkstationName `
                    -TargetHost $e.Computer `
                    -Result $(if ($_ -eq 4624) { 'Success' } else { 'Failure' }) -Raw $e
            }

            default { }                     # ignore everything else
        }
    }
}
