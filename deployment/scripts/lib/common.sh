#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Deployment Framework — Shared Library
#
# Source from other deployment scripts:
#   source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
# ------------------------------------------------------------------------------

set -euo pipefail

readonly DEPLOYMENT_FRAMEWORK_VERSION="1.0.0"
readonly VALID_ENVIRONMENTS=("dev" "stage" "prod")
readonly REQUIRED_TERRAFORM_VERSION="1.13.0"
readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
readonly ENVIRONMENTS_DIR="${REPO_ROOT}/environments"

# Colors (disabled when not a TTY)
if [[ -t 1 ]]; then
  readonly COLOR_RED='\033[0;31m'
  readonly COLOR_GREEN='\033[0;32m'
  readonly COLOR_YELLOW='\033[1;33m'
  readonly COLOR_BLUE='\033[0;34m'
  readonly COLOR_RESET='\033[0m'
else
  readonly COLOR_RED=''
  readonly COLOR_GREEN=''
  readonly COLOR_YELLOW=''
  readonly COLOR_BLUE=''
  readonly COLOR_RESET=''
fi

log_info() {
  echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

log_success() {
  echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} $*"
}

log_warn() {
  echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*"
}

log_error() {
  echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

die() {
  log_error "$@"
  exit 1
}

usage_environment() {
  cat <<EOF
Usage: $(basename "$0") <environment> [options]

Valid environments: ${VALID_ENVIRONMENTS[*]}

Environment variables:
  TF_ENV              Target environment (alternative to positional argument)
  TF_BACKEND_CONFIG   Path to backend.hcl (default: environments/<env>/backend.hcl)
  TF_VAR_FILE         Path to tfvars (default: environments/<env>/terraform.tfvars)
  TF_PLUGIN_CACHE_DIR Plugin cache directory (recommended in CI)
EOF
}

is_valid_environment() {
  local env="$1"
  local candidate
  for candidate in "${VALID_ENVIRONMENTS[@]}"; do
    if [[ "$candidate" == "$env" ]]; then
      return 0
    fi
  done
  return 1
}

resolve_environment() {
  local env="${1:-${TF_ENV:-}}"
  [[ -n "$env" ]] || die "Environment is required. $(usage_environment)"
  is_valid_environment "$env" || die "Invalid environment '$env'. Must be one of: ${VALID_ENVIRONMENTS[*]}"
  echo "$env"
}

environment_dir() {
  local env
  env="$(resolve_environment "$1")"
  echo "${ENVIRONMENTS_DIR}/${env}"
}

backend_config_path() {
  local env_dir
  env_dir="$(environment_dir "$1")"
  local config="${TF_BACKEND_CONFIG:-${env_dir}/backend.hcl}"
  echo "$config"
}

var_file_path() {
  local env_dir
  env_dir="$(environment_dir "$1")"
  local varfile="${TF_VAR_FILE:-${env_dir}/terraform.tfvars}"
  echo "$varfile"
}

require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

require_terraform() {
  require_command terraform
  local version
  version="$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4 || terraform version | head -1 | awk '{print $2}' | tr -d 'v')"
  if [[ -n "$version" && "$version" != "$REQUIRED_TERRAFORM_VERSION" ]]; then
    log_warn "Terraform version is $version; framework expects $REQUIRED_TERRAFORM_VERSION"
  fi
}

require_backend_config() {
  local env="$1"
  local config
  config="$(backend_config_path "$env")"
  [[ -f "$config" ]] || die "Backend config not found: $config — copy backend.hcl.example and populate values."
  echo "$config"
}

require_var_file() {
  local env="$1"
  local varfile
  varfile="$(var_file_path "$env")"
  [[ -f "$varfile" ]] || die "Variable file not found: $varfile — copy terraform.tfvars.example and populate values."
  echo "$varfile"
}

confirm() {
  local prompt="$1"
  local response
  read -r -p "${prompt} [y/N]: " response
  [[ "$response" =~ ^[Yy]$ ]]
}

confirm_phrase() {
  local expected="$1"
  local prompt="${2:-Type '$expected' to confirm}"
  local response
  read -r -p "${prompt}: " response
  [[ "$response" == "$expected" ]] || die "Confirmation failed. Expected: $expected"
}

export TF_IN_AUTOMATION="${TF_IN_AUTOMATION:-true}"
