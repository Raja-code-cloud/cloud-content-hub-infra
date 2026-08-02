# Azure Monitor Action Group Module

Creates **Azure Monitor Action Groups** for alert notification routing. Does not create alert rules, Log Analytics, or external notification infrastructure.

## Purpose

- Centralize notification channels for platform and application alerts
- Support multiple receiver types (email, webhook, SMS, voice, and more)
- Manage **multiple action groups** via stable `for_each` keys
- Consume existing Azure resources only — no hardcoded destinations

This module creates **only** `azurerm_monitor_action_group` resources.

## Architecture

```
environments/<env>/
    module "resource_group"     ──▶ resource_group_name
    module "action_group"       ──▶ azurerm_monitor_action_group (for_each)
            │
            ▼
    module "monitor_alerts"     ──▶ action_group_id references
```

Action groups must be created before metric alerts that reference them.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 5.0 |

Providers are inherited from the environment root module.

## Inputs

### `action_groups`

List of action group objects. Each entry requires a unique `key`.

| Field | Required | Description |
|-------|:--------:|-------------|
| `key` | yes | Stable `for_each` identifier |
| `name` | yes | Action group name (1–260 chars) |
| `resource_group_name` | yes | Resource group name |
| `short_name` | yes | Short name for SMS (1–12 alphanumeric) |
| `enabled` | no | Enable action group (default `true`) |
| `tags` | no | Resource tags |
| `email_receivers` | no | Email notification receivers |
| `webhook_receivers` | no | HTTPS webhook receivers |
| `sms_receivers` | no | SMS receivers |
| `voice_receivers` | no | Voice call receivers |
| `azure_app_push_receivers` | no | Azure mobile app push receivers |
| `arm_role_receivers` | no | Azure Resource Manager role receivers |
| `automation_runbook_receivers` | no | Automation runbook receivers |
| `azure_function_receivers` | no | Azure Function receivers |
| `event_hub_receivers` | no | Event Hub receivers |
| `logic_app_receiver` | no | Logic App receiver (single) |
| `itsm_receiver` | no | ITSM integration receiver (single) |

At least **one receiver** must be defined per action group. Receiver names must be unique within a group (case-insensitive).

## Outputs

| Name | Description |
|------|-------------|
| `action_group_ids` | Map of keys to action group resource IDs |
| `action_group_names` | Map of keys to action group names |
| `short_names` | Map of keys to SMS short names |
| `action_groups` | Non-sensitive metadata map |

## Examples

### Platform email alerts

```hcl
module "action_group" {
  source = "../../modules/action-group"

  action_groups = [
    {
      key                 = "platform-ops"
      name                = module.common.resource_names["action_group"]
      resource_group_name = module.resource_group.name
      short_name          = "platops"
      tags                = module.common.tags

      email_receivers = [
        {
          name                    = "platform-team"
          email_address           = var.platform_alert_email
          use_common_alert_schema = true
        },
      ]
    },
  ]
}
```

### Email + webhook

```hcl
module "action_group" {
  source = "../../modules/action-group"

  action_groups = [
    {
      key                 = "incident-routing"
      name                = "ag-incident-routing"
      resource_group_name = module.resource_group.name
      short_name          = "incident"
      tags                = module.common.tags

      email_receivers = [
        {
          name          = "oncall-email"
          email_address = "oncall@example.com"
        },
      ]

      webhook_receivers = [
        {
          name                    = "pagerduty"
          service_uri             = var.pagerduty_webhook_url
          use_common_alert_schema = true
        },
      ]
    },
  ]
}
```

### Multiple action groups

```hcl
module "action_group" {
  source = "../../modules/action-group"

  action_groups = [
    {
      key                 = "critical"
      name                = "ag-critical"
      resource_group_name = module.resource_group.name
      short_name          = "critical"
      tags                = module.common.tags
      email_receivers     = [{ name = "critical", email_address = "critical@example.com" }]
    },
    {
      key                 = "warning"
      name                = "ag-warning"
      resource_group_name = module.resource_group.name
      short_name          = "warning"
      tags                = module.common.tags
      email_receivers     = [{ name = "warning", email_address = "warning@example.com" }]
    },
  ]
}
```

## Best Practices

| Practice | Rationale |
|----------|-----------|
| Separate critical and warning groups | Route severity-0/1 alerts to on-call channels |
| Use `use_common_alert_schema = true` | Standardized payload for webhooks and ITSM |
| Keep `short_name` ≤ 12 chars | Azure SMS display limit |
| Do not hardcode emails in module | Pass via variables or Key Vault |
| One module call per environment | Batch all action groups in a single list |

## Security

- Webhook URLs and function trigger URLs are supplied by the caller — never commit secrets
- Module does not expose sensitive receiver configuration in outputs
- Use HTTPS webhook endpoints only (validated)

## Cost Considerations

Action groups themselves have no direct cost. SMS and voice receivers incur per-notification charges.

## Related

- [Monitor Alerts Module](../monitor-alerts/README.md)
- [Diagnostic Settings Module](../diagnostic-settings/README.md)
