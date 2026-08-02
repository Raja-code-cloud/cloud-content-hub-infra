# ------------------------------------------------------------------------------
# PostgreSQL Configuration Module — Locals
# ------------------------------------------------------------------------------

locals {
  configurations = {
    for configuration in var.configurations : configuration.name => {
      name    = configuration.name
      value   = configuration.value
      source  = try(configuration.source, null)
      enabled = try(configuration.enabled, true)
    }
    if try(configuration.enabled, true)
  }

  # Authentication and security-related parameters require explicit opt-in.
  restricted_configuration_names = [
    "authentication",
    "password_encryption",
    "require_secure_transport",
    "ssl_max_protocol_version",
    "ssl_min_protocol_version",
  ]
}
