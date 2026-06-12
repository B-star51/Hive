# HiveCore.ps1
# Orchestration layer. Wires providers -> agents -> correlation -> response.
# It knows nothing about any specific log format; that lives in the providers.

function Get-HiveConfig {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) { throw "Config not found: $Path" }
    Get-Content $Path -Raw | ConvertFrom-Json
}

# Selects the active provider from config and returns NormalizedEvent[].
# This is the single seam where local logs / Azure Graph / Sentinel are swapped.
function Get-HiveEvents {
    param(
        [Parameter(Mandatory)]$Config,
        [Parameter(Mandatory)][string]$RootPath
    )
    $ds = $Config.dataSource
    if ($ds.use_local_logs) {
        $logPath = Join-Path $RootPath $Config.localLogs.path
        return Invoke-LocalJsonProvider -Path $logPath
    }
    elseif ($ds.use_azure_graph) {
        return Invoke-AzureGraphProvider -Config $Config.azureGraph
    }
    elseif ($ds.use_sentinel) {
        return Invoke-SentinelProvider -Config $Config.sentinel
    }
    else {
        throw "No data source enabled in settings.json (set one of use_* to true)."
    }
}

# Runs every detection agent over the same normalized events.
function Invoke-HiveAgents {
    param([Parameter(Mandatory)][object[]]$Events)
    $signals = @()
    $signals += Invoke-RoleChangeAgent      -Events $Events
    $signals += Invoke-TokenMisuseAgent     -Events $Events
    $signals += Invoke-LateralMovementAgent -Events $Events
    $signals | Where-Object { $_ }
}
