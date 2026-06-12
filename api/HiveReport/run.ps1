using namespace System.Net

# HTTP-triggered Azure Function that runs the Hive engine and returns the report
# as JSON. This is the endpoint the Microsoft 365 Copilot agent's action calls
# (see appPackage/hive-openapi.yaml -> GET /hive/report).
#
# Deployment note: the engine lives in ../../src and config in ../../config,
# relative to this function. When you deploy, include the whole repo (or copy
# src/ + config/ + data/ alongside the function app) so these paths resolve.

param($Request, $TriggerMetadata)

$ErrorActionPreference = 'Stop'

# Repo root = two levels up from api/HiveReport
$repoRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName

. "$repoRoot\src\Core\EventModel.ps1"
. "$repoRoot\src\Providers\LocalJsonProvider.ps1"
. "$repoRoot\src\Providers\AzureGraphProvider.ps1"
. "$repoRoot\src\Providers\SentinelProvider.ps1"
. "$repoRoot\src\Agents\RoleChangeAgent.ps1"
. "$repoRoot\src\Agents\TokenMisuseAgent.ps1"
. "$repoRoot\src\Agents\LateralMovementAgent.ps1"
. "$repoRoot\src\Agents\CorrelationAgent.ps1"
. "$repoRoot\src\Agents\ResponseAgent.ps1"
. "$repoRoot\src\Core\HiveCore.ps1"
. "$repoRoot\src\Core\HiveReport.ps1"

try {
    $config = Get-HiveConfig -Path "$repoRoot\config\settings.json"
    $report = Get-HiveReport -Config $config -RootPath $repoRoot

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Headers    = @{ 'Content-Type' = 'application/json' }
        Body       = ($report | ConvertTo-Json -Depth 8)
    })
}
catch {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Headers    = @{ 'Content-Type' = 'application/json' }
        Body       = (@{ error = $_.Exception.Message } | ConvertTo-Json)
    })
}
