#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Discover Terraform modules for CI matrix generation.
#
# Usage:
#   ./tests/scripts/discover-modules.sh          # one module per line
#   ./tests/scripts/discover-modules.sh --json   # JSON array
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

format="${1:-}"

case "$format" in
  --json)
    modules_json_array
    ;;
  --github)
    printf 'modules=%s\n' "$(modules_json_array | jq -c .)"
    ;;
  "")
    discover_modules
    ;;
  *)
    die "Unknown option: $format"
    ;;
esac
