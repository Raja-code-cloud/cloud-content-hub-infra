#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Validate sensitive Terraform outputs are marked sensitive = true.
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

SENSITIVE_OUTPUT_NAMES=("password" "connection_string" "api_key" "private_key" "access_token")
FINDINGS=0

cd "$REPO_ROOT"

check_outputs_file() {
  local file="$1"
  local keyword
  for keyword in "${SENSITIVE_OUTPUT_NAMES[@]}"; do
    if grep -E "output \"[^\"]*${keyword}[^\"]*\"" "$file" >/dev/null 2>&1; then
      if ! awk '
        /^output "/ {
          block=$0
          in_block=1
        }
        in_block {
          block=block "\n" $0
          if ($0 ~ /^}/) {
            if (block ~ /output "[^"]*'"${keyword}"'[^"]*"/ && block !~ /sensitive[[:space:]]*=[[:space:]]*true/) {
              exit 1
            }
            in_block=0
            block=""
          }
        }
        END { exit 0 }
      ' "$file"; then
        log_error "Output with sensitive keyword '${keyword}' missing sensitive = true in ${file}"
        FINDINGS=1
      fi
    fi
  done
}

while IFS= read -r file; do
  check_outputs_file "$file"
done < <(find modules environments -name 'outputs.tf' 2>/dev/null)

if [[ "$FINDINGS" -ne 0 ]]; then
  die "Sensitive output validation failed."
fi

log_ok "Sensitive output validation passed"
exit 0
