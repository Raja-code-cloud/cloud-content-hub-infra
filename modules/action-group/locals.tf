# ------------------------------------------------------------------------------
# Action Group Module — Locals
# ------------------------------------------------------------------------------

locals {
  action_groups = {
    for group in var.action_groups : group.key => group
  }

  receiver_summary = {
    for key, group in local.action_groups : key => {
      email              = length(try(group.email_receivers, []))
      sms                = length(try(group.sms_receivers, []))
      voice              = length(try(group.voice_receivers, []))
      webhook            = length(try(group.webhook_receivers, []))
      azure_function     = length(try(group.azure_function_receivers, []))
      logic_app          = length(try(group.logic_app_receivers, []))
      automation_runbook = length(try(group.automation_runbook_receivers, []))
      arm_role           = length(try(group.arm_role_receivers, []))
      eventhub           = length(try(group.eventhub_receivers, []))
      azure_app_push     = length(try(group.azure_app_push_receivers, []))
      itsm               = length(try(group.itsm_receivers, []))
      total = (
        length(try(group.email_receivers, [])) +
        length(try(group.sms_receivers, [])) +
        length(try(group.voice_receivers, [])) +
        length(try(group.webhook_receivers, [])) +
        length(try(group.azure_function_receivers, [])) +
        length(try(group.logic_app_receivers, [])) +
        length(try(group.automation_runbook_receivers, [])) +
        length(try(group.arm_role_receivers, [])) +
        length(try(group.eventhub_receivers, [])) +
        length(try(group.azure_app_push_receivers, [])) +
        length(try(group.itsm_receivers, []))
      )
    }
  }
}
