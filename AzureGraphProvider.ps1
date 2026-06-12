# AzureGraphProvider.ps1
# STUB - not implemented in the demo. This is the "endpoint stub" for Azure AD /
# Microsoft Graph described in the architecture. Someone can implement it later
# without changing any agent.
#
# Suggested implementation:
#   1. Acquire a token (client credentials) for the Graph API.
#   2. GET https://graph.microsoft.com/v1.0/auditLogs/directoryAudits
#        -> map "Add member to role" entries to RoleChange NormalizedEvents.
#   3. GET https://graph.microsoft.com/v1.0/auditLogs/signIns
#        -> map risky / token events to TokenUse + Authentication events.
#   4. Return NormalizedEvent[] (see ../Core/EventModel.ps1).
#
# Enable by setting use_azure_graph = true in config/settings.json.

function Invoke-AzureGraphProvider {
    [CmdletBinding()]
    param($Config)

    throw [System.NotImplementedException]::new(
        "AzureGraphProvider is a stub. Implement Microsoft Graph calls here and " +
        "map the responses to NormalizedEvent objects. Enable via use_azure_graph " +
        "in config/settings.json once implemented.")
}
