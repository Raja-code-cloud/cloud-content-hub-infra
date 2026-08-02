#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Unit tests for module validation and fixture-based checks.
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/lib/common.sh
source "${SCRIPT_DIR}/../scripts/lib/common.sh"

FAILED=0

test_fixture() {
  local fixture_dir="$1"
  local name
  name="$(basename "$fixture_dir")"
  log_info "Fixture test: ${name}"
  if (
    cd "$fixture_dir"
    terraform init -backend=false -input=false >/dev/null
    terraform validate -no-color
  ); then
    log_ok "Fixture ${name} passed"
  else
    log_error "Fixture ${name} failed"
    FAILED=1
  fi
}

while IFS= read -r fixture_dir; do
  [[ -n "$fixture_dir" ]] || continue
  test_fixture "$fixture_dir"
done < <(find "${TESTS_DIR}/fixtures/examples" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

exit "$FAILED"
