# ------------------------------------------------------------------------------
# Action Group Module — Locals
# ------------------------------------------------------------------------------

locals {
  action_groups = {
    for group in var.action_groups : group.key => group
  }

  receiver_names = {
    for key, group in local.action_groups : key => concat(
      [for receiver in try(group.email_receivers, []) : receiver.name],
      [for receiver in try(group.webhook_receivers, []) : receiver.name],
      [for receiver in try(group.sms_receivers, []) : receiver.name],
      [for receiver in try(group.voice_receivers, []) : receiver.name],
      [for receiver in try(group.azure_app_push_receivers, []) : receiver.name],
      [for receiver in try(group.arm_role_receivers, []) : receiver.name],
      [for receiver in try(group.automation_runbook_receivers, []) : receiver.name],
      [for receiver in try(group.azure_function_receivers, []) : receiver.name],
      [for receiver in try(group.event_hub_receivers, []) : receiver.name],
      try(group.logic_app_receiver, null) != null ? [group.logic_app_receiver.name] : [],
      try(group.itsm_receiver, null) != null ? [group.itsm_receiver.name] : [],
    )
  }
}
