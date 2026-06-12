# SentinelProvider.ps1
# STUB - not implemented in the demo. Endpoint stub for Microsoft Sentinel /
# Log Analytics. Implement later without touching any agent.
#
# Suggested implementation:
#   1. Authenticate to the Log Analytics query API.
#   2. Run KQL such as:
#        SecurityEvent | where EventID in (4728,4732,4756,4768,4769,4624,4625)
#   3. Map each row to a NormalizedEvent (see ../Core/EventModel.ps1).
#   4. Return NormalizedEvent[].
#
# Enable by setting use_sentinel = true in config/settings.json.

function Invoke-SentinelProvider {
    [CmdletBinding()]
    param($Config)

    throw [System.NotImplementedException]::new(
        "SentinelProvider is a stub. Implement the Log Analytics KQL query here " +
        "and map rows to NormalizedEvent objects. Enable via use_sentinel in " +
        "config/settings.json once implemented.")
}
