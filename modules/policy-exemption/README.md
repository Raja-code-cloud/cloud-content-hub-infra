# Azure Policy Exemption Module

Creates **Azure Policy Exemptions** to exclude scopes from policy assignment evaluation. Does not create policy definitions, initiatives, assignments, or other Azure resources — consume existing assignment IDs from the `policy-assignment` module.

## Purpose

- Grant time-bound or documented exceptions to policy assignments
- Support waiver and mitigated exemption categories
- Exempt entire scopes or specific initiative member definitions
- Encourage governance documentation via metadata and expiration dates

This module creates:

- `azurerm_management_group_policy_exemption`
- `azurerm_subscription_policy_exemption`
- `azurerm_resource_group_policy_exemption`
- `azurerm_resource_policy_exemption`

## Architecture

```
environments/<env>/
    module "policy_assignment"   ──▶ policy_assignment_ids
    module "policy_exemption"    ──▶ exemptions referencing assignment IDs
            │
            └──▶ scoped exemption at MG / sub / RG / resource
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
| `exemptions` | no | List of exemption definitions (default `[]`) |
| `require_expiration_dates` | no | Require `expires_on` on every exemption (default `false`; set `true` in production) |

### Exemption object

| Field | Required | Description |
|-------|:--------:|-------------|
| `key` | yes | Stable `for_each` identifier |
| `name` | yes | Exemption name (1–64 characters) |
| `scope` | yes | Management group, subscription, resource group, or resource ID |
| `policy_assignment_id` | yes | Parent policy assignment resource ID |
| `exemption_category` | yes | `Waiver` or `Mitigated` |
| `display_name` | no | Human-readable display name |
| `description` | no | Exemption justification (max 1024 characters) |
| `policy_definition_reference_ids` | no | Initiative member reference IDs to exempt (omit to exempt all) |
| `expires_on` | no | Expiration date (`YYYY-MM-DD` or ISO 8601) — **strongly recommended** |
| `metadata` | no | Key-value metadata for audit trail (required when `expires_on` is omitted) |

### Scope formats

| Scope type | Format |
|------------|--------|
| Management group | `/providers/Microsoft.Management/managementGroups/{name}` |
| Subscription | `/subscriptions/{subscription-id}` |
| Resource group | `/subscriptions/{subscription-id}/resourceGroups/{rg-name}` |
| Resource | `/subscriptions/.../providers/{provider}/{type}/{name}` |

### Exemption categories

| Category | Use when |
|----------|----------|
| `Waiver` | Policy cannot be met; risk accepted with compensating controls |
| `Mitigated` | Alternative control satisfies policy intent |

## Outputs

| Name | Description |
|------|-------------|
| `exemption_ids` | Map of exemption keys to resource IDs |
| `exemption_names` | Map of exemption keys to names |
| `scopes` | Map of exemption keys to scope IDs |
| `policy_assignment_ids` | Map of exemption keys to assignment IDs |
| `expiration_dates` | Map of exemption keys to expiration dates |
| `exemptions` | Metadata map for composition |

## Examples

### Development environment waiver

```hcl
module "policy_exemption" {
  source = "../../modules/policy-exemption"

  exemptions = [
    {
      key                  = "dev-storage-network"
      name                 = "exempt-dev-storage-network"
      display_name         = "Dev storage network policy waiver"
      description          = "Development uses public storage endpoints during initial build-out."
      scope                = module.resource_group.resource_id
      policy_assignment_id = module.policy_assignment.assignment_ids["storage-network-restrict"]
      exemption_category   = "Waiver"
      expires_on           = "2026-12-31"
      metadata = {
        owner       = "platform-engineering"
        ticket      = "GOV-1042"
        environment = "dev"
      }
    },
  ]
}
```

### Temporary production exception

```hcl
module "policy_exemption" {
  source = "../../modules/policy-exemption"

  require_expiration_dates = true

  exemptions = [
    {
      key                  = "prod-kv-exception"
      name                 = "exempt-prod-kv-legacy"
      display_name         = "Temporary KV policy exception"
      description          = "Legacy application requires public KV access until private endpoint migration completes."
      scope                = module.key_vault.resource_id
      policy_assignment_id = module.policy_assignment.assignment_ids["key-vault-network"]
      exemption_category   = "Mitigated"
      expires_on           = "2026-06-30"
      metadata = {
        approved_by = "security-architect"
        ticket      = "INC-8821"
        review_date = "2026-05-01"
      }
    },
  ]
}
```

### Single policy reference exemption (initiative member)

```hcl
{
  key                  = "initiative-member-only"
  name                 = "exempt-storage-member"
  scope                = module.resource_group.resource_id
  policy_assignment_id = module.policy_assignment.assignment_ids["platform-initiative"]
  exemption_category   = "Waiver"
  expires_on           = "2026-09-30"
  policy_definition_reference_ids = [
    "storageSecureTransfer",
  ]
  metadata = {
    reason = "Third-party tool requires HTTP during migration window"
  }
}
```

### Resource group exemption

```hcl
{
  key                  = "rg-exemption"
  name                 = "exempt-rg-policy"
  display_name         = "RG-level policy exemption"
  scope                = module.resource_group.resource_id
  policy_assignment_id = module.policy_assignment.assignment_ids["storage-secure-transfer"]
  exemption_category   = "Mitigated"
  expires_on           = "2026-12-31"
  description          = "Compensating control: NSG restricts inbound traffic to approved CIDRs."
}
```

### Resource-level exemption

```hcl
{
  key                  = "storage-account-exemption"
  name                 = "exempt-legacy-storage"
  scope                = module.storage.resource_id
  policy_assignment_id = module.policy_assignment.assignment_ids["storage-network-restrict"]
  exemption_category   = "Waiver"
  expires_on           = "2026-03-31"
  metadata = {
    asset_id = "legacy-import-blob"
    owner    = "data-platform"
  }
}
```

## Governance Strategy

| Principle | Implementation |
|-----------|----------------|
| Least exemption | Exempt narrowest scope (resource > RG > subscription) |
| Time-bound | Always set `expires_on`; use `require_expiration_dates = true` in prod |
| Documented | Populate `description` and `metadata` with owner, ticket, review date |
| Initiative precision | Use `policy_definition_reference_ids` to exempt only required members |
| Review cadence | Track `expiration_dates` output; renew or remove before expiry |
| Category accuracy | `Waiver` = cannot comply; `Mitigated` = alternative control in place |

## Operational Guidance

1. **Create assignments first** — Exemptions reference `policy_assignment_id` from the assignment module.
2. **Set expiration** — Azure does not auto-remove expired exemptions from Terraform state; plan renewals or destroy expired exemptions.
3. **Monitor compliance** — Exempted resources appear as exempt in Azure Policy compliance dashboards.
4. **Audit trail** — Store ticket IDs and approvers in `metadata`.
5. **Import** — `terraform import azurerm_resource_group_policy_exemption.this["key"] {scope}/providers/Microsoft.Authorization/policyExemptions/{name}`

## Best Practices

| Practice | Rationale |
|----------|-----------|
| Prefer `Mitigated` with evidence | Demonstrates compensating controls |
| Never exempt at MG unless necessary | MG exemptions have wide blast radius |
| Align expiry with change ticket | Governance review before renewal |
| Use initiative reference IDs | Avoid over-exempting entire initiatives |
| Set `require_expiration_dates` in prod | Prevents accidental permanent exemptions |

## Lifecycle Management

```
Request → Approve → Terraform apply → Monitor expiry → Renew or remove
```

| Phase | Action |
|-------|--------|
| Create | PR with justification, ticket, and expiry |
| Active | Monitor compliance; verify compensating controls |
| Pre-expiry | Review 30 days before `expires_on` |
| Expired | Remove exemption from Terraform or renew with new approval |
| Audit | Export `exemptions` output for governance reporting |

## Related

- [Policy Assignment Module](../policy-assignment/README.md)
- [Policy Initiative Module](../policy-initiative/README.md)

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
