# ------------------------------------------------------------------------------
# Common Module — Check Blocks
#
# Modules in this repository do NOT declare providers or required_providers.
# Providers are configured exclusively at the environment root level.
#
# See: docs/terraform/provider-inheritance.md
# ------------------------------------------------------------------------------

check "required_tags" {
  assert {
    condition     = local.required_tags_valid
    error_message = "Required organizational tags are missing or empty. Ensure owner, business_unit, cost_center, and base tag keys are set."
  }
}

check "resource_prefix_length" {
  assert {
    condition     = length(local.computed_resource_prefix) <= 24
    error_message = "resource_prefix must not exceed 24 characters to support globally unique Azure resource names."
  }
}
