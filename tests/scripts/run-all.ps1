#Requires -Version 5.1
<#
.SYNOPSIS
  Run the Terraform testing framework on Windows.

.EXAMPLE
  .\tests\scripts\run-all.ps1
  .\tests\scripts\run-all.ps1 -Suite modules
  .\tests\scripts\run-all.ps1 -Suite plan -Environment dev -WithPlan
#>
param(
  [ValidateSet('all', 'static', 'modules', 'environments', 'security', 'compliance', 'plan', 'regression')]
  [string]$Suite = 'regression',

  [ValidateSet('dev', 'stage', 'prod', '')]
  [string]$Environment = '',

  [switch]$WithPlan
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Bash = Get-Command bash -ErrorAction SilentlyContinue

if (-not $Bash) {
  Write-Error 'bash is required to run the test framework scripts on Windows.'
}

$Runner = Join-Path $RepoRoot 'tests/scripts/run-all.sh'
$Args = @('--suite', $Suite)

if ($WithPlan) { $Args += '--with-plan' }
if ($Environment) { $Args += '--env', $Environment }

Push-Location $RepoRoot
try {
  & bash $Runner @Args
  exit $LASTEXITCODE
}
finally {
  Pop-Location
}
