#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Terraform Testing Framework — Shared Library
# ------------------------------------------------------------------------------

set -euo pipefail

readonly TEST_FRAMEWORK_VERSION="1.0.0"
readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
readonly TESTS_DIR="${REPO_ROOT}/tests"
readonly CONFIG_DIR="${TESTS_DIR}/config"
readonly REPORTS_DIR="${TESTS_DIR}/reports"
readonly MANIFEST_FILE="${CONFIG_DIR}/manifest.json"
readonly COMPLIANCE_FILE="${CONFIG_DIR}/compliance-rules.json"
readonly MODULES_DIR="${REPO_ROOT}/modules"
readonly ENVIRONMENTS_DIR="${REPO_ROOT}/environments"

if [[ -t 1 ]]; then
  readonly C_INFO='\033[0;34m'
  readonly C_OK='\033[0;32m'
  readonly C_WARN='\033[1;33m'
  readonly C_ERR='\033[0;31m'
  readonly C_RESET='\033[0m'
else
  readonly C_INFO=''
  readonly C_OK=''
  readonly C_WARN=''
  readonly C_ERR=''
  readonly C_RESET=''
fi

log_info() { echo -e "${C_INFO}[INFO]${C_RESET} $*"; }
log_ok() { echo -e "${C_OK}[OK]${C_RESET} $*"; }
log_warn() { echo -e "${C_WARN}[WARN]${C_RESET} $*"; }
log_error() { echo -e "${C_ERR}[ERROR]${C_RESET} $*" >&2; }
die() { log_error "$@"; exit 1; }

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

require_jq() {
  require_command jq
}

ensure_reports_dir() {
  mkdir -p "${REPORTS_DIR}"
}

manifest_value() {
  local query="$1"
  require_jq
  jq -r "$query" "$MANIFEST_FILE"
}

discover_modules() {
  local module
  for module_path in "${MODULES_DIR}"/*/; do
    [[ -d "$module_path" ]] || continue
    [[ -f "${module_path}main.tf" ]] || continue
    basename "$module_path"
  done | sort
}

discover_environments() {
  local env
  for env_path in "${ENVIRONMENTS_DIR}"/*/; do
    [[ -d "$env_path" ]] || continue
    [[ -f "${env_path}main.tf" ]] || continue
    basename "$env_path"
  done | sort
}

modules_json_array() {
  local modules=()
  local module
  while IFS= read -r module; do
    [[ -n "$module" ]] && modules+=("$module")
  done < <(discover_modules)
  printf '%s\n' "${modules[@]}" | jq -R . | jq -s .
}

environments_json_array() {
  local envs=()
  local env
  while IFS= read -r env; do
    [[ -n "$env" ]] && envs+=("$env")
  done < <(discover_environments)
  printf '%s\n' "${envs[@]}" | jq -R . | jq -s .
}

record_result() {
  local suite="$1"
  local name="$2"
  local status="$3"
  local details="${4:-}"
  ensure_reports_dir
  local file="${REPORTS_DIR}/${suite}-results.jsonl"
  jq -nc \
    --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg suite "$suite" \
    --arg name "$name" \
    --arg status "$status" \
    --arg details "$details" \
    '{timestamp:$ts,suite:$suite,name:$name,status:$status,details:$details}' >> "$file"
}

run_gate() {
  local suite="$1"
  local name="$2"
  shift 2
  log_info "Gate: ${name}"
  if "$@"; then
    record_result "$suite" "$name" "passed"
    log_ok "${name} passed"
    return 0
  else
    record_result "$suite" "$name" "failed"
    log_error "${name} failed"
    return 1
  fi
}

terraform_init_validate() {
  local target_dir="$1"
  (
    cd "$target_dir"
    terraform init -backend=false -input=false >/dev/null
    terraform validate -no-color
  )
}

terraform_fmt_check() {
  terraform fmt -recursive -check -diff
}

write_suite_summary() {
  local suite="$1"
  local title="$2"
  local summary_file="${REPORTS_DIR}/${suite}-summary.md"
  local results_file="${REPORTS_DIR}/${suite}-results.jsonl"

  {
    echo "# ${title}"
    echo ""
    echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo ""
    if [[ -f "$results_file" ]]; then
      echo "| Check | Status | Details |"
      echo "|-------|--------|---------|"
      while IFS= read -r line; do
        local name status details
        name="$(echo "$line" | jq -r '.name')"
        status="$(echo "$line" | jq -r '.status')"
        details="$(echo "$line" | jq -r '.details // ""')"
        echo "| ${name} | ${status} | ${details} |"
      done < "$results_file"
    else
      echo "_No results recorded._"
    fi
  } > "$summary_file"
}

export TF_IN_AUTOMATION="${TF_IN_AUTOMATION:-true}"
