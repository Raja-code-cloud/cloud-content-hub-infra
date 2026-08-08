#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Workstation readiness check — Linux, macOS, Git Bash on Windows.
#
# Usage: ./scripts/workstation-check.sh
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PASS=0
WARN=0
FAIL=0

check_cmd() {
  local label="$1"
  local cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    local version
    version="$("$cmd" --version 2>&1 | head -1 || echo "installed")"
    printf "  [PASS] %-18s %s\n" "$label" "$version"
    PASS=$((PASS + 1))
  else
    printf "  [FAIL] %-18s not found\n" "$label"
    FAIL=$((FAIL + 1))
  fi
}

check_optional() {
  local label="$1"
  local cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    local version
    version="$("$cmd" --version 2>&1 | head -1 || echo "installed")"
    printf "  [PASS] %-18s %s\n" "$label" "$version"
    PASS=$((PASS + 1))
  else
    printf "  [WARN] %-18s not found (optional)\n" "$label"
    WARN=$((WARN + 1))
  fi
}

echo "=== Git configuration ==="
for key in user.name user.email init.defaultBranch; do
  value="$(git config --global "$key" 2>/dev/null || true)"
  if [[ -n "$value" ]]; then
    printf "  [PASS] git config %s = %s\n" "$key" "$value"
    PASS=$((PASS + 1))
  else
    printf "  [WARN] git config %s is not set\n" "$key"
    WARN=$((WARN + 1))
  fi
done

if git lfs version >/dev/null 2>&1; then
  printf "  [PASS] Git LFS: %s\n" "$(git lfs version | head -1)"
  PASS=$((PASS + 1))
else
  printf "  [WARN] Git LFS not installed\n"
  WARN=$((WARN + 1))
fi

echo ""
echo "=== Required tooling ==="
check_cmd "Terraform" terraform
check_cmd "terraform-docs" terraform-docs
check_cmd "TFLint" tflint
check_cmd "Checkov" checkov
check_cmd "Trivy" trivy
check_cmd "jq" jq
check_cmd "Git" git
check_cmd "Python" python3

echo ""
echo "=== Azure CLI (optional for local plan/apply) ==="
if command -v az >/dev/null 2>&1; then
  printf "  [PASS] Azure CLI: %s\n" "$(az version --query '\"azure-cli\"' -o tsv 2>/dev/null || az version 2>&1 | head -1)"
  PASS=$((PASS + 1))
  if az account show >/dev/null 2>&1; then
    sub="$(az account show --query name -o tsv 2>/dev/null || echo unknown)"
    tenant="$(az account show --query tenantId -o tsv 2>/dev/null || echo unknown)"
    printf "  [PASS] Subscription: %s\n" "$sub"
    printf "  [PASS] Tenant:       %s\n" "$tenant"
    PASS=$((PASS + 2))
  else
    printf "  [WARN] Not logged in — run: az login\n"
    WARN=$((WARN + 1))
  fi
else
  printf "  [WARN] Azure CLI not installed\n"
  WARN=$((WARN + 1))
fi

echo ""
echo "=== Repository quality gate smoke test ==="
cd "$REPO_ROOT"
if terraform fmt -check -recursive >/dev/null 2>&1; then
  printf "  [PASS] terraform fmt -check\n"
  PASS=$((PASS + 1))
else
  printf "  [FAIL] terraform fmt -check (run: terraform fmt -recursive)\n"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Summary ==="
printf "  Passed:   %d\n" "$PASS"
printf "  Warnings: %d\n" "$WARN"
printf "  Failed:   %d\n" "$FAIL"

if [[ "$FAIL" -gt 0 ]]; then
  echo ""
  echo "Workstation NOT READY — install missing tools and re-run."
  exit 1
fi

echo ""
echo "Workstation READY for repository quality gates."
exit 0
