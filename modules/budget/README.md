# Azure Cost Management Budget Module

Creates **Azure Cost Management Budgets** at **subscription** or **resource group** scope with configurable threshold notifications. Does not create action groups, alerts, policies, or other Azure resources — consume existing action group IDs via `contact_groups`.

## Purpose

- Enforce FinOps guardrails with subscription- and resource-group-level spend limits
- Support multiple budgets per environment via a single reusable module
- Integrate with existing Azure Monitor Action Groups for notifications
- Optional cost filters by dimension or resource tag for scoped budgets

This module creates:

- `azurerm_consumption_budget_subscription` (subscription scope)
- `azurerm_consumption_budget_resource_group` (resource group scope)

## Architecture

```
environments/<env>/
    module "resource_group"   ──▶ scope for RG budgets
    module "action_group"     ──▶ contact_groups (action group IDs)
    module "budget"           ──▶ Cost Management budgets
            │
            └──▶ notifications reference module.action_group.action_group_ids
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 5.0 |

Providers are inherited from the environment root module.

## Inputs

| Name | Required | Description |
|------|:--------:|-------------|
| `budgets` | no | List of budget definitions (default `[]`) |

### Budget object

| Field | Required | Description |
|-------|:--------:|-------------|
| `key` | yes | Stable `for_each` identifier |
| `name` | yes | Budget name (1–63 characters) |
| `scope` | yes | Subscription or resource group resource ID |
| `amount` | yes | Budget amount in currency units (must be > 0) |
| `time_grain` | yes | `Monthly`, `Quarterly`, or `Annually` |
| `start_date` | yes | Budget period start (`YYYY-MM-DD` or ISO 8601) |
| `end_date` | no | Budget period end (optional) |
| `tags` | no | Composition metadata only — **not applied to Azure** (budgets do not support ARM tags) |
| `filter` | no | Optional cost filter by dimension or resource tag |
| `notifications` | yes | At least one notification threshold |

### Notification object

| Field | Required | Description |
|-------|:--------:|-------------|
| `threshold` | yes | Percentage threshold (1–1000) |
| `operator` | yes | `EqualTo`, `GreaterThan`, or `GreaterThanOrEqualTo` |
| `threshold_type` | no | `Actual` (default) or `Forecasted` |
| `contact_emails` | no | Email recipients |
| `contact_groups` | no | Action Group resource IDs |
| `contact_roles` | no | `Owner`, `Contributor`, or `Reader` |
| `enabled` | no | Enable notification (default `true`) |

Each **enabled** notification must specify at least one of `contact_emails`, `contact_groups`, or `contact_roles`.

### Scope formats

| Scope type | Format |
|------------|--------|
| Subscription | `/subscriptions/{subscription-id}` |
| Resource group | `/subscriptions/{subscription-id}/resourceGroups/{rg-name}` |

## Outputs

| Name | Description |
|------|-------------|
| `budget_ids` | Map of budget keys to resource IDs |
| `budget_names` | Map of budget keys to names |
| `budget_amounts` | Map of budget keys to amounts |
| `budget_scopes` | Map of budget keys to scope resource IDs |
| `budget_scope_types` | Map of budget keys to `subscription` or `resource_group` |
| `budgets` | Metadata map for composition |

## Examples

### Development budget (resource group, low amount)

```hcl
module "budget" {
  source = "../../modules/budget"

  budgets = [
    {
      key        = "dev-rg"
      name       = "budget-dev-platform"
      scope      = module.resource_group.resource_id
      amount     = 500
      time_grain = "Monthly"
      start_date = "2026-01-01"
      end_date   = "2026-12-31"

      notifications = [
        {
          threshold      = 80
          operator       = "GreaterThan"
          threshold_type = "Actual"
          contact_groups = [module.action_group.action_group_ids["finops"]]
        },
        {
          threshold      = 100
          operator       = "GreaterThanOrEqualTo"
          threshold_type = "Forecasted"
          contact_groups = [module.action_group.action_group_ids["finops"]]
        },
      ]
    },
  ]
}
```

### Production budget (subscription scope)

```hcl
module "budget" {
  source = "../../modules/budget"

  budgets = [
    {
      key        = "prod-sub"
      name       = "budget-prod-subscription"
      scope      = "/subscriptions/${var.subscription_id}"
      amount     = 25000
      time_grain = "Monthly"
      start_date = "2026-01-01"

      notifications = [
        {
          threshold      = 70
          operator       = "GreaterThan"
          contact_groups = [module.action_group.action_group_ids["finops"]]
          contact_roles  = ["Owner"]
        },
        {
          threshold      = 90
          operator       = "GreaterThan"
          threshold_type = "Forecasted"
          contact_groups = [module.action_group.action_group_ids["finops"]]
        },
      ]
    },
  ]
}
```

### Subscription budget

```hcl
{
  key        = "platform-sub"
  name       = "budget-platform-subscription"
  scope      = data.azurerm_subscription.current.id
  amount     = 10000
  time_grain = "Quarterly"
  start_date = "2026-01-01"
  end_date   = "2026-12-31"

  notifications = [
    {
      threshold      = 85
      operator       = "GreaterThan"
      contact_groups = [var.finops_action_group_id]
    },
  ]
}
```

### Resource group budget

```hcl
{
  key        = "app-rg"
  name       = "budget-app-resource-group"
  scope      = module.resource_group.resource_id
  amount     = 3000
  time_grain = "Monthly"
  start_date = "2026-01-01"

  notifications = [
    {
      threshold      = 75
      operator       = "GreaterThan"
      contact_groups = [module.action_group.action_group_ids["platform"]]
    },
  ]
}
```

### Multiple budget notifications (Actual + Forecasted)

```hcl
{
  key        = "prod-rg"
  name       = "budget-prod-rg"
  scope      = module.resource_group.resource_id
  amount     = 15000
  time_grain = "Monthly"
  start_date = "2026-01-01"

  filter = {
    tags = [{
      name     = "Environment"
      operator = "In"
      values   = ["prod"]
    }]
  }

  notifications = [
    {
      threshold      = 50
      operator       = "GreaterThan"
      threshold_type = "Actual"
      contact_groups = [module.action_group.action_group_ids["finops"]]
    },
    {
      threshold      = 80
      operator       = "GreaterThan"
      threshold_type = "Actual"
      contact_groups = [module.action_group.action_group_ids["finops"]]
      contact_roles  = ["Owner", "Contributor"]
    },
    {
      threshold      = 100
      operator       = "GreaterThanOrEqualTo"
      threshold_type = "Forecasted"
      contact_groups = [module.action_group.action_group_ids["finops"]]
    },
  ]
}
```

## FinOps Guidance

| Practice | Recommendation |
|----------|----------------|
| Layer budgets | Subscription ceiling + resource group budgets for teams |
| Threshold ladder | 50% / 80% / 100% Actual + Forecasted at 100% |
| Action groups | Centralize FinOps notifications; avoid hardcoded emails in Terraform |
| Time grain | Use `Monthly` for operational control; `Quarterly`/`Annually` for caps |
| Filters | Scope budgets by `Environment`, `CostCenter`, or `Project` tags |
| Forecast alerts | Enable `Forecasted` thresholds to catch overspend before month-end |

## Operational Guidance

1. **Deploy action groups first** — Budget notifications reference existing action group IDs.
2. **Align dates with fiscal calendar** — `start_date` changes force budget recreation.
3. **Use variables for amounts** — Keep budget limits in `tfvars` per environment, not in module code.
4. **Review in Cost Management** — Validate budgets appear under Azure Portal → Cost Management → Budgets.
5. **Test notifications** — Trigger a low threshold in dev to confirm action group delivery.

## Cost Optimization Strategy

| Strategy | How this module helps |
|----------|------------------------|
| Visibility | Threshold notifications before overspend |
| Accountability | RG-scoped budgets per workload team |
| Governance | Subscription-level cap as organizational guardrail |
| Tag-based chargeback | Optional `filter.tags` for cost center budgets |
| Dev cost control | Lower dev RG budgets with forecast alerts |

## Security Best Practices

| Practice | Rationale |
|----------|-----------|
| No hardcoded emails | Pass emails via variables or use action groups only |
| No secrets in module | Budget module has no secret inputs |
| Validate action group IDs | Ensures notifications target known Monitor resources |
| Least privilege | Use dedicated FinOps action groups with minimal receivers |

## Related

- [Action Group Module](../action-group/README.md)
- [Resource Group Module](../resource-group/README.md)

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
