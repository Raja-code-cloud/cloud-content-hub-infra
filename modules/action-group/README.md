# Azure Monitor Action Group Module

Creates **Azure Monitor Action Groups** for alert notification routing. Does not create alerts, diagnostic settings, Log Analytics, dashboards, workbooks, or budgets.

## Purpose

- Define notification channels consumed by Azure Monitor alerts
- Support **all optional receiver types** with zero-to-many receivers per type
- Manage **multiple action groups** in one module call via stable `for_each` keys
- Remain environment-agnostic with no hardcoded emails, URLs, or phone numbers

This module creates **only** `azurerm_monitor_action_group` resources.

## Architecture

```
environments/<env>/
    module "resource_group"   ──▶ resource_group_name
    module "common"           ──▶ tags, naming
    module "action_group"     ──▶ azurerm_monitor_action_group (for_each)
            │
            ▼
    module "monitor_alerts"   ──▶ action_group_ids / resource_ids
    module "diagnostic_settings" (independent — no action group dependency)
```

Action groups are notification endpoints. Alert rules reference action group IDs after both are deployed.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 5.0 |

Providers are inherited from the environment root module.

## Supported Receiver Types

| Receiver | Variable | Cardinality |
|----------|----------|-------------|
| Email | `email_receivers` | 0–n |
| SMS | `sms_receivers` | 0–n |
| Voice | `voice_receivers` | 0–n |
| Webhook | `webhook_receivers` | 0–n (supports `aad_auth` for authenticated webhooks) |
| Azure Function | `azure_function_receivers` | 0–n |
| Logic App | `logic_app_receivers` | 0–n |
| Automation Runbook | `automation_runbook_receivers` | 0–n |
| ARM Role | `arm_role_receivers` | 0–n |
| Event Hub | `eventhub_receivers` | 0–n |
| Azure App Push | `azure_app_push_receivers` | 0–n |
| ITSM | `itsm_receivers` | 0–n |

All receiver types are optional. Receivers are rendered via dynamic blocks — no separate resource per receiver.

## Inputs

### `action_groups`

List of action group objects. Each entry requires a unique `key`.

| Field | Required | Description |
|-------|:--------:|-------------|
| `key` | yes | Stable `for_each` identifier (2–64 lowercase alphanumeric/hyphen) |
| `action_group_name` | yes | Action group name (1–260 chars) |
| `resource_group_name` | yes | Target resource group name |
| `short_name` | yes | SMS prefix (1–12 alphanumeric) |
| `enabled` | no | Enable group (default `true`) |
| `tags` | no | Resource tags |
| `email_receivers` | no | Email notification receivers |
| `sms_receivers` | no | SMS receivers |
| `voice_receivers` | no | Voice call receivers |
| `webhook_receivers` | no | HTTPS webhook receivers |
| `azure_function_receivers` | no | Azure Function trigger receivers |
| `logic_app_receivers` | no | Logic App callback receivers |
| `automation_runbook_receivers` | no | Automation runbook receivers |
| `arm_role_receivers` | no | Azure RBAC role receivers |
| `eventhub_receivers` | no | Event Hub receivers |
| `azure_app_push_receivers` | no | Azure mobile app push receivers |
| `itsm_receivers` | no | ITSM integration receivers |

### Validations

| Check | Rule |
|-------|------|
| Action group name | 1–260 valid Azure characters |
| Short name | 1–12 alphanumeric |
| Email | Valid email format |
| Phone (SMS/voice) | Country code 1–3 digits; number 4–14 digits |
| Webhook URI | Must start with `https://` |
| Logic App callback | Must start with `https://` |
| ARM role ID | Valid role definition resource ID |
| Function App ID | Valid `Microsoft.Web/sites` resource ID |
| Logic App ID | Valid `Microsoft.Logic/workflows` resource ID |
| Automation Account ID | Valid `Microsoft.Automation/automationAccounts` resource ID |
| Receiver names | Unique within each action group (case-insensitive) |

## Outputs

| Name | Description |
|------|-------------|
| `action_group_ids` | Map of keys to action group resource IDs |
| `resource_ids` | Map of keys to Azure resource IDs |
| `action_group_names` | Map of keys to action group names |
| `short_names` | Map of keys to SMS short names |
| `receiver_summary` | Per-group receiver counts by channel (non-sensitive) |
| `action_groups` | Metadata map including `receiver_summary` per group |

## Examples

### Development email notifications

```hcl
module "action_group" {
  source = "../../modules/action-group"

  action_groups = [
    {
      key                 = "dev-alerts"
      action_group_name   = module.common.resource_names["action_group"]
      resource_group_name = module.resource_group.name
      short_name          = "devalerts"
      enabled             = true
      tags                = module.common.tags

      email_receivers = [
        {
          name          = "developer"
          email_address = var.dev_alert_email
        },
      ]
    },
  ]
}
```

### Production multiple email recipients

```hcl
module "action_group" {
  source = "../../modules/action-group"

  action_groups = [
    {
      key                 = "prod-critical"
      action_group_name   = "ag-prod-critical"
      resource_group_name = module.resource_group.name
      short_name          = "critical"
      tags                = module.common.tags

      email_receivers = [
        {
          name                    = "oncall-primary"
          email_address           = var.oncall_primary_email
          use_common_alert_schema = true
        },
        {
          name                    = "oncall-secondary"
          email_address           = var.oncall_secondary_email
          use_common_alert_schema = true
        },
        {
          name                    = "platform-leads"
          email_address           = var.platform_leads_email
          use_common_alert_schema = true
        },
      ]
    },
  ]
}
```

### Webhook receiver (with optional AAD authentication)

```hcl
module "action_group" {
  source = "../../modules/action-group"

  action_groups = [
    {
      key                 = "pagerduty"
      action_group_name   = "ag-pagerduty"
      resource_group_name = module.resource_group.name
      short_name          = "pagerduty"
      tags                = module.common.tags

      webhook_receivers = [
        {
          name                    = "pagerduty-events"
          service_uri             = var.pagerduty_webhook_url
          use_common_alert_schema = true
          aad_auth = {
            object_id = var.pagerduty_aad_object_id
          }
        },
      ]
    },
  ]
}
```

### Logic App receiver

```hcl
module "action_group" {
  source = "../../modules/action-group"

  action_groups = [
    {
      key                 = "incident-logic-app"
      action_group_name   = "ag-incident-logic-app"
      resource_group_name = module.resource_group.name
      short_name          = "incident"
      tags                = module.common.tags

      logic_app_receivers = [
        {
          name                    = "incident-workflow"
          resource_id             = var.incident_logic_app_id
          callback_url            = var.incident_logic_app_callback_url
          use_common_alert_schema = true
        },
      ]
    },
  ]
}
```

### Azure Function receiver

```hcl
module "action_group" {
  source = "../../modules/action-group"

  action_groups = [
    {
      key                 = "alert-function"
      action_group_name   = "ag-alert-function"
      resource_group_name = module.resource_group.name
      short_name          = "alertfn"
      tags                = module.common.tags

      azure_function_receivers = [
        {
          name                     = "process-alert"
          function_app_resource_id = var.alert_function_app_id
          function_name            = "ProcessAlert"
          http_trigger_url         = var.alert_function_trigger_url
          use_common_alert_schema  = true
        },
      ]
    },
  ]
}
```

### Mixed notification channels

```hcl
module "action_group" {
  source = "../../modules/action-group"

  action_groups = [
    {
      key                 = "platform-ops"
      action_group_name   = "ag-platform-ops"
      resource_group_name = module.resource_group.name
      short_name          = "platops"
      tags                = module.common.tags

      email_receivers = [
        { name = "ops-email", email_address = var.ops_email },
      ]

      webhook_receivers = [
        { name = "teams-webhook", service_uri = var.teams_webhook_url },
      ]

      sms_receivers = [
        {
          name         = "oncall-sms"
          country_code = "1"
          phone_number = var.oncall_phone
        },
      ]

      arm_role_receivers = [
        {
          name    = "monitoring-contributor"
          role_id = "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
        },
      ]
    },
  ]
}
```

## Operational Guidance

1. **Deploy before alerts** — Action groups must exist before `monitor-alerts` references them.
2. **Use variables for endpoints** — Pass emails, webhook URLs, and phone numbers via tfvars or Key Vault; never hardcode in module source.
3. **Separate severity groups** — Use distinct action groups for critical vs warning routes.
4. **Test in dev first** — Validate email/webhook delivery before promoting to production groups.
5. **Import existing groups** — `terraform import azurerm_monitor_action_group.example /subscriptions/.../providers/Microsoft.Insights/actionGroups/{name}`

## Best Practices

| Practice | Rationale |
|----------|-----------|
| `use_common_alert_schema = true` for webhooks | Standardized JSON payload for integrations |
| Keep `short_name` ≤ 12 chars | Azure SMS display limit |
| Unique receiver names per group | Azure requirement (case-insensitive) |
| One module call, many groups | Batch via `action_groups` list for maintainability |
| Authenticated webhooks via `aad_auth` | Extension point for secure webhook delivery |

## Security

- Webhook URLs, function trigger URLs, and runbook URIs are supplied by callers — **never commit secrets**
- Module outputs exclude endpoint URLs and phone numbers (`receiver_summary` is counts only)
- HTTPS required for webhook and Logic App callback URLs (validated)
- `aad_auth` block supports authenticated webhook extension without embedding credentials in Terraform state beyond object IDs

## Cost Considerations

Action groups have **no direct Azure charge**. Costs apply to notification delivery:

| Channel | Cost Driver |
|---------|-------------|
| Email | Usually negligible |
| SMS | Per-message regional rates |
| Voice | Per-call regional rates |
| Webhook / Function / Logic App | Downstream service costs |

Use email/webhook in development; reserve SMS/voice for production critical paths.

## Related

- [Monitor Alerts Module](../monitor-alerts/README.md)
- [Diagnostic Settings Module](../diagnostic-settings/README.md)
