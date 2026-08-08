#Requires -Version 5.1
<#
.SYNOPSIS
  Workstation readiness check for Windows (PowerShell + Git Bash).

.EXAMPLE
  .\scripts\workstation-check.ps1
#>
$ErrorActionPreference = 'Continue'
$RepoRoot = Split-Path $PSScriptRoot -Parent

$Pass = 0
$Warn = 0
$Fail = 0

function Write-Check {
  param([string]$Status, [string]$Label, [string]$Detail = '')
  $symbol = switch ($Status) {
    'PASS' { $script:Pass++; '[PASS]' }
    'WARN' { $script:Warn++; '[WARN]' }
    'FAIL' { $script:Fail++; '[FAIL]' }
  }
  if ($Detail) {
    Write-Host ("  {0,-7} {1,-18} {2}" -f $symbol, $Label, $Detail)
  }
  else {
    Write-Host ("  {0,-7} {1,-18}" -f $symbol, $Label)
  }
}

Write-Host '=== Git configuration ==='
foreach ($key in @('user.name', 'user.email', 'init.defaultBranch')) {
  $value = git config --global $key 2>$null
  if ($value) { Write-Check 'PASS' "git config $key" $value }
  else { Write-Check 'WARN' "git config $key" 'not set' }
}

try {
  $lfs = git lfs version 2>&1 | Select-Object -First 1
  Write-Check 'PASS' 'Git LFS' $lfs
}
catch { Write-Check 'WARN' 'Git LFS' 'not installed' }

Write-Host ''
Write-Host '=== Required tooling ==='
$tools = @(
  @{ Label = 'Terraform'; Cmd = 'terraform' },
  @{ Label = 'terraform-docs'; Cmd = 'terraform-docs' },
  @{ Label = 'TFLint'; Cmd = 'tflint' },
  @{ Label = 'Checkov'; Cmd = 'checkov' },
  @{ Label = 'Trivy'; Cmd = 'trivy' },
  @{ Label = 'jq'; Cmd = 'jq' },
  @{ Label = 'Git'; Cmd = 'git' },
  @{ Label = 'Python'; Cmd = 'python' }
)

foreach ($tool in $tools) {
  $cmd = Get-Command $tool.Cmd -ErrorAction SilentlyContinue
  if ($cmd) {
    try {
      $version = & $tool.Cmd --version 2>&1 | Select-Object -First 1
      Write-Check 'PASS' $tool.Label $version
    }
    catch { Write-Check 'PASS' $tool.Label 'installed' }
  }
  else { Write-Check 'FAIL' $tool.Label 'not found' }
}

Write-Host ''
Write-Host '=== Bash (required for test framework on Windows) ==='
$bash = Get-Command bash -ErrorAction SilentlyContinue
if ($bash) { Write-Check 'PASS' 'Git Bash' $bash.Source }
else { Write-Check 'FAIL' 'Git Bash' 'not found' }

Write-Host ''
Write-Host '=== Azure CLI (optional) ==='
$az = Get-Command az -ErrorAction SilentlyContinue
if ($az) {
  try {
    $ver = az version 2>&1 | ConvertFrom-Json
    Write-Check 'PASS' 'Azure CLI' $ver.'azure-cli'
    $account = az account show 2>$null | ConvertFrom-Json
    if ($account) {
      Write-Check 'PASS' 'Subscription' $account.name
      Write-Check 'PASS' 'Tenant' $account.tenantId
    }
    else { Write-Check 'WARN' 'Azure login' 'run: az login' }
  }
  catch { Write-Check 'WARN' 'Azure CLI' 'installed but account check failed' }
}
else { Write-Check 'WARN' 'Azure CLI' 'not installed' }

Write-Host ''
Write-Host '=== Summary ==='
Write-Host "  Passed:   $Pass"
Write-Host "  Warnings: $Warn"
Write-Host "  Failed:   $Fail"

if ($Fail -gt 0) {
  Write-Host ''
  Write-Host 'Workstation NOT READY — install missing tools and re-run.'
  exit 1
}

Write-Host ''
Write-Host 'Workstation READY for repository quality gates.'
exit 0
