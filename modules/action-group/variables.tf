# ------------------------------------------------------------------------------
# Action Group Module — Variables
# ------------------------------------------------------------------------------

variable "action_groups" {
  description = "List of Azure Monitor action groups. Each entry requires a stable key for for_each identity at scale."
  type = list(object({
    key                 = string
    action_group_name   = string
    resource_group_name = string
    short_name          = string
    enabled             = optional(bool, true)
    tags                = optional(map(string), {})
    email_receivers = optional(list(object({
      name                    = string
      email_address           = string
      use_common_alert_schema = optional(bool, false)
    })), [])
    sms_receivers = optional(list(object({
      name         = string
      country_code = string
      phone_number = string
    })), [])
    voice_receivers = optional(list(object({
      name         = string
      country_code = string
      phone_number = string
    })), [])
    webhook_receivers = optional(list(object({
      name                    = string
      service_uri             = string
      use_common_alert_schema = optional(bool, false)
      aad_auth = optional(object({
        object_id      = string
        identifier_uri = optional(string)
        tenant_id      = optional(string)
      }))
    })), [])
    azure_function_receivers = optional(list(object({
      name                     = string
      function_app_resource_id = string
      function_name            = string
      http_trigger_url         = string
      use_common_alert_schema  = optional(bool, false)
    })), [])
    logic_app_receivers = optional(list(object({
      name                    = string
      resource_id             = string
      callback_url            = string
      use_common_alert_schema = optional(bool, false)
    })), [])
    automation_runbook_receivers = optional(list(object({
      name                    = string
      automation_account_id   = string
      runbook_name            = string
      webhook_resource_id     = string
      service_uri             = string
      is_global_runbook       = optional(bool, false)
      use_common_alert_schema = optional(bool, false)
    })), [])
    arm_role_receivers = optional(list(object({
      name                    = string
      role_id                 = string
      use_common_alert_schema = optional(bool, false)
    })), [])
    eventhub_receivers = optional(list(object({
      name                    = string
      event_hub_namespace     = string
      event_hub_name          = string
      subscription_id         = string
      use_common_alert_schema = optional(bool, false)
    })), [])
    azure_app_push_receivers = optional(list(object({
      name          = string
      email_address = string
    })), [])
    itsm_receivers = optional(list(object({
      name                 = string
      workspace_id         = string
      connection_id        = string
      ticket_configuration = string
      region               = string
    })), [])
  }))
  nullable = false
  default  = []

  validation {
    condition     = length(distinct([for group in var.action_groups : group.key])) == length(var.action_groups)
    error_message = "Each action group key must be unique."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", group.key))
    ])
    error_message = "Each action group key must be 2-64 lowercase alphanumeric characters or hyphens."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      can(regex("^[\\w\\(\\)\\.-]{1,260}$", group.action_group_name))
    ])
    error_message = "Each action_group_name must be 1-260 valid Azure name characters."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      can(regex("^[\\w\\(\\)\\.-]{1,90}$", group.resource_group_name))
    ])
    error_message = "Each resource_group_name must be 1-90 valid Azure name characters."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      can(regex("^[a-zA-Z0-9]{1,12}$", group.short_name))
    ])
    error_message = "Each short_name must be 1-12 alphanumeric characters."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      length(distinct([
        for name in concat(
          [for receiver in try(group.email_receivers, []) : lower(receiver.name)],
          [for receiver in try(group.sms_receivers, []) : lower(receiver.name)],
          [for receiver in try(group.voice_receivers, []) : lower(receiver.name)],
          [for receiver in try(group.webhook_receivers, []) : lower(receiver.name)],
          [for receiver in try(group.azure_app_push_receivers, []) : lower(receiver.name)],
          [for receiver in try(group.arm_role_receivers, []) : lower(receiver.name)],
          [for receiver in try(group.automation_runbook_receivers, []) : lower(receiver.name)],
          [for receiver in try(group.azure_function_receivers, []) : lower(receiver.name)],
          [for receiver in try(group.eventhub_receivers, []) : lower(receiver.name)],
          [for receiver in try(group.logic_app_receivers, []) : lower(receiver.name)],
          [for receiver in try(group.itsm_receivers, []) : lower(receiver.name)],
        ) : name
        ])) == length(concat(
        [for receiver in try(group.email_receivers, []) : lower(receiver.name)],
        [for receiver in try(group.sms_receivers, []) : lower(receiver.name)],
        [for receiver in try(group.voice_receivers, []) : lower(receiver.name)],
        [for receiver in try(group.webhook_receivers, []) : lower(receiver.name)],
        [for receiver in try(group.azure_app_push_receivers, []) : lower(receiver.name)],
        [for receiver in try(group.arm_role_receivers, []) : lower(receiver.name)],
        [for receiver in try(group.automation_runbook_receivers, []) : lower(receiver.name)],
        [for receiver in try(group.azure_function_receivers, []) : lower(receiver.name)],
        [for receiver in try(group.eventhub_receivers, []) : lower(receiver.name)],
        [for receiver in try(group.logic_app_receivers, []) : lower(receiver.name)],
        [for receiver in try(group.itsm_receivers, []) : lower(receiver.name)],
      ))
    ])
    error_message = "Receiver names must be unique within each action group (case-insensitive)."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      alltrue([
        for receiver in try(group.email_receivers, []) :
        can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", receiver.email_address))
      ])
    ])
    error_message = "Each email_receiver email_address must be a valid email format."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      alltrue([
        for receiver in concat(try(group.sms_receivers, []), try(group.voice_receivers, [])) :
        can(regex("^[0-9]{1,3}$", receiver.country_code))
      ])
    ])
    error_message = "Each SMS/voice country_code must be 1-3 digits."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      alltrue([
        for receiver in concat(try(group.sms_receivers, []), try(group.voice_receivers, [])) :
        can(regex("^[0-9]{4,14}$", receiver.phone_number))
      ])
    ])
    error_message = "Each SMS/voice phone_number must be 4-14 digits."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      alltrue([
        for receiver in try(group.webhook_receivers, []) :
        can(regex("^https://", receiver.service_uri))
      ])
    ])
    error_message = "Each webhook_receiver service_uri must start with https://."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      alltrue([
        for receiver in try(group.arm_role_receivers, []) :
        can(regex("^/providers/Microsoft\\.Authorization/roleDefinitions/[0-9a-f-]{36}$", receiver.role_id)) ||
        can(regex("^/subscriptions/[0-9a-f-]{36}/providers/Microsoft\\.Authorization/roleDefinitions/[0-9a-f-]{36}$", receiver.role_id))
      ])
    ])
    error_message = "Each arm_role_receiver role_id must be a valid Azure role definition resource ID."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      alltrue([
        for receiver in try(group.azure_function_receivers, []) :
        can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.Web/sites/[\\w\\(\\)\\.-]+$", receiver.function_app_resource_id))
      ])
    ])
    error_message = "Each azure_function_receiver function_app_resource_id must be a valid Function App resource ID."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      alltrue([
        for receiver in try(group.logic_app_receivers, []) :
        can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.Logic/workflows/[\\w\\(\\)\\.-]+$", receiver.resource_id))
      ])
    ])
    error_message = "Each logic_app_receiver resource_id must be a valid Logic App workflow resource ID."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      alltrue([
        for receiver in try(group.logic_app_receivers, []) :
        can(regex("^https://", receiver.callback_url))
      ])
    ])
    error_message = "Each logic_app_receiver callback_url must start with https://."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      alltrue([
        for receiver in try(group.automation_runbook_receivers, []) :
        can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.Automation/automationAccounts/[\\w\\(\\)\\.-]+$", receiver.automation_account_id))
      ])
    ])
    error_message = "Each automation_runbook_receiver automation_account_id must be a valid Automation Account resource ID."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      alltrue([
        for receiver in try(group.automation_runbook_receivers, []) :
        can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/.+$", receiver.webhook_resource_id))
      ])
    ])
    error_message = "Each automation_runbook_receiver webhook_resource_id must be a valid Azure resource ID."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      alltrue([
        for receiver in try(group.eventhub_receivers, []) :
        can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", receiver.subscription_id))
      ])
    ])
    error_message = "Each eventhub_receiver subscription_id must be a valid UUID."
  }

  validation {
    condition = alltrue([
      for group in var.action_groups :
      alltrue([
        for receiver in try(group.webhook_receivers, []) :
        try(receiver.aad_auth, null) == null ||
        can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", receiver.aad_auth.object_id))
      ])
    ])
    error_message = "webhook aad_auth object_id must be a valid UUID when specified."
  }
}
