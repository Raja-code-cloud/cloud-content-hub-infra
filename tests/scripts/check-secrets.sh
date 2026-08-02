#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Scan repository for potential secrets in source files.
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

PATTERNS_FILE="${CONFIG_DIR}/secret-patterns.txt"
FINDINGS=0

cd "$REPO_ROOT"

scan_file() {
  local file="$1"
  local pattern
  while IFS= read -r pattern; do
    [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
    if grep -E -- "$pattern" "$file" >/dev/null 2>&1; then
      log_error "Potential secret pattern in ${file}"
      FINDINGS=1
    fi
  done < "$PATTERNS_FILE"
}

while IFS= read -r file; do
  case "$file" in
    *.example|*terraform.tfvars.example|*README.md|tests/config/secret-patterns.txt|tests/reports/*)
      continue
      ;;
  esac
  scan_file "$file"
done < <(git ls-files '*.tf' '*.tfvars' '*.json' '*.yaml' '*.yml' 2>/dev/null || find . -type f \( -name '*.tf' -o -name '*.tfvars' -o -name '*.json' \) -not -path './.git/*' -not -path './.terraform/*')

if [[ "$FINDINGS" -ne 0 ]]; then
  die "Secret scan detected potential credentials in source files."
fi

log_ok "Secret scan passed"
exit 0
