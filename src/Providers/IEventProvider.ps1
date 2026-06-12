# IEventProvider.ps1
# ---------------------------------------------------------------------------
# THE PROVIDER CONTRACT (documentation only - PowerShell has no interfaces here)
#
# Every Hive data provider MUST expose a function of the shape:
#
#     Invoke-<Name>Provider  ->  NormalizedEvent[]   (see ../Core/EventModel.ps1)
#
# A provider is the ONLY component in Hive that knows about a specific data
# source (a JSON file, the Windows Event Log, Microsoft Graph, Sentinel/KQL).
# Its single job is to read that source and emit NormalizedEvent objects.
#
# Agents depend on the NormalizedEvent contract, never on the source. To wire
# in a real Azure feed you implement the matching stub and flip the toggle in
# config/settings.json - no agent code changes.
#
# Currently implemented : LocalJsonProvider
# Stubbed (ready to fill): AzureGraphProvider, SentinelProvider
# ---------------------------------------------------------------------------
