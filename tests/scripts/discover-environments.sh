#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Discover Terraform environments for CI matrix generation.
#
# Usage:
#   ./tests/scripts/discover-environments.sh          # one environment per line
#   ./tests/scripts/discover-environments.sh --json   # JSON array
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

format="${1:-}"

case "$format" in
  --json)
    environments_json_array
    ;;
  --github)
    printf 'environments=%s\n' "$(environments_json_array | jq -c .)"
    ;;
  "")
    discover_environments
    ;;
  *)
    die "Unknown option: $format"
    ;;
esac
