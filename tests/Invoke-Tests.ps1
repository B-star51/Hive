# Invoke-Tests.ps1 - convenience runner. Installs Pester for the current user
# if it isn't already present, then runs the Hive test suite.
$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version.Major -ge 5 })) {
    Write-Host "Installing Pester (CurrentUser scope)..." -ForegroundColor Yellow
    Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser -Force -SkipPublisherCheck
}

Import-Module Pester -MinimumVersion 5.0
Invoke-Pester -Path "$PSScriptRoot\Hive.Tests.ps1" -Output Detailed
