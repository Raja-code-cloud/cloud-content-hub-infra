# Azure Policy Assignment Module

Creates **Azure Policy Assignments** at any supported scope. Does not create policy definitions, initiatives, exemptions, management groups, subscriptions, or other Azure resources.

## Purpose

- Assign built-in and custom **policy definitions** and **policy initiatives** at scale
- Support hundreds of assignments via stable `for_each` keys
- Configure parameters, enforcement mode, managed identity, and non-compliance messages
- Enable enterprise governance across management groups, subscriptions, resource groups, and individual resources

This module creates **only** Azure Policy Assignment resources:

- `azurerm_management_group_policy_assignment`
- `azurerm_subscription_policy_assignment`
- `azurerm_resource_group_policy_assignment`
- `azurerm_resource_policy_assignment`

## Architecture

```
policies/definitions/          ──▶ policy_definition_id (existing, not created here)
policies/initiatives/          ──▶ policy_definition_id (existing, not created here)
environments/<env>/locals.tf   ──▶ assignments list (scope, parameters, identity)
        │
        ▼
module "policy_assignment"     ──▶ scope-specific policy assignment (for_each)
        │
        ▼
Azure Policy engine            ──▶ Audit / Deny / DeployIfNotExists / Modify / Disabled
```

Policy definitions, initiatives, and scopes must already exist. This module never creates them.

The module routes each assignment to the correct Terraform resource based on the ARM scope ID:

| Scope type | Scope format | Terraform resource |
|------------|--------------|-------------------|
| Management group | `/providers/Microsoft.Management/managementGroups/{id}` | `azurerm_management_group_policy_assignment` |
| Subscription | `/subscriptions/{subscription-id}` | `azurerm_subscription_policy_assignment` |
| Resource group | `/subscriptions/{id}/resourceGroups/{name}` | `azurerm_resource_group_policy_assignment` |
| Resource | `/subscriptions/{id}/resourceGroups/{name}/providers/...` | `azurerm_resource_policy_assignment` |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 5.0 |

Providers are inherited from the environment root module.

## Inputs

### `assignments`

List of policy assignment objects. Each entry requires a unique `key` for stable Terraform state at scale.

| Field | Required | Description |
|-------|:--------:|-------------|
| `key` | yes | Stable identifier for `for_each` (2–64 chars, lowercase alphanumeric/hyphen) |
| `name` | yes | Azure Policy Assignment name (1–64 chars; letters, numbers, hyphens, underscores, periods) |
| `scope` | yes | Management group, subscription, resource group, or resource ARM ID |
| `policy_definition_id` | yes | Built-in or custom policy definition or initiative resource ID |
| `display_name` | no | Human-readable assignment display name |
| `description` | no | Assignment description |
| `parameters` | no | Policy parameters map; values are auto-wrapped as `{ value = ... }` when needed |
| `enforcement_mode` | no | `Default` (enforced) or `DoNotEnforce` (assigned but not enforced) |
| `location` | conditional | Azure region; **required** when `identity` is configured |
| `identity` | no | Managed identity for DeployIfNotExists and Modify effects |
| `non_compliance_messages` | no | Custom messages shown in compliance reports |

#### `identity` object

| Field | Required | Description |
|-------|:--------:|-------------|
| `type` | yes | `SystemAssigned` or `UserAssigned` |
| `identity_ids` | conditional | User-assigned identity resource IDs; required when `type = UserAssigned` |

#### `non_compliance_messages` object

| Field | Required | Description |
|-------|:--------:|-------------|
| `content` | yes | Non-compliance message text (1–4096 characters) |
| `policy_definition_reference_id` | no | Policy reference ID within an initiative |

### Supported policy effects

This module does not hardcode enforcement behavior. Policy effect is determined by the assigned definition or initiative parameters (for example `Audit`, `Deny`, `DeployIfNotExists`, `Modify`, `Disabled`).

Use `enforcement_mode = "DoNotEnforce"` to assign a policy in report-only mode without changing the underlying effect definition.

## Outputs

| Name | Description |
|------|-------------|
| `assignment_ids` | Map of keys to policy assignment resource IDs |
| `assignment_names` | Map of keys to policy assignment names |
| `policy_definition_ids` | Map of keys to assigned policy or initiative definition IDs |
| `scopes` | Map of keys to assignment scopes |
| `identity_principal_ids` | Map of keys to managed identity principal IDs (null when no identity) |
| `assignments` | Metadata object map for downstream composition |

## Examples

### Require HTTPS on Storage Accounts

```hcl
module "policy_assignment_storage_https" {
  source = "../../modules/policy-assignment"

  assignments = [{
    key                  = "storage-require-https"
    name                 = "storage-require-https"
    display_name         = "Require HTTPS on Storage Accounts"
    description          = "Deny or audit storage accounts that do not require secure transfer"
    scope                = data.azurerm_subscription.current.id
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c5141-0f2d-4551-877a-3fce8836795f"
    parameters = {
      effect = {
        value = "Deny"
      }
    }
    non_compliance_messages = [{
      content = "Storage accounts must require secure transfer (HTTPS)."
    }]
  }]
}
```

### Allowed Azure Locations

```hcl
module "policy_assignment_allowed_locations" {
  source = "../../modules/policy-assignment"

  assignments = [{
    key                  = "allowed-locations"
    name                 = "allowed-locations"
    display_name         = "Allowed Azure Locations"
    description          = "Restrict resource deployment to approved regions"
    scope                = "/providers/Microsoft.Management/managementGroups/contoso-platform"
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49bd-b67c-b17fd847b4a7"
    parameters = {
      listOfAllowedLocations = {
        value = ["eastus", "eastus2", "centralus"]
      }
      effect = {
        value = "Deny"
      }
    }
  }]
}
```

### Allowed SKUs

```hcl
module "policy_assignment_allowed_skus" {
  source = "../../modules/policy-assignment"

  assignments = [{
    key                  = "storage-allowed-skus"
    name                 = "storage-allowed-skus"
    display_name         = "Allowed Storage Account SKUs"
    scope                = azurerm_resource_group.platform.id
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/7433c107-153d-44f5-ac69-a8e9a6661898"
    parameters = {
      listOfAllowedSKUs = {
        value = ["Standard_LRS", "Standard_GRS"]
      }
      effect = {
        value = "Deny"
      }
    }
  }]
}
```

### Required Resource Tags

```hcl
module "policy_assignment_required_tags" {
  source = "../../modules/policy-assignment"

  assignments = [{
    key                  = "require-environment-tag"
    name                 = "require-environment-tag"
    display_name         = "Require Environment Tag on Resource Groups"
    scope                = data.azurerm_subscription.current.id
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d94-1749-438a-b928-8cac33af9950"
    parameters = {
      tagName = {
        value = "Environment"
      }
      effect = {
        value = "Deny"
      }
    }
    non_compliance_messages = [{
      content = "Resource groups must include the Environment tag."
    }]
  }]
}
```

### Key Vault Soft Delete

```hcl
module "policy_assignment_key_vault_soft_delete" {
  source = "../../modules/policy-assignment"

  assignments = [{
    key                  = "kv-soft-delete"
    name                 = "kv-soft-delete"
    display_name         = "Key Vault Soft Delete Required"
    scope                = data.azurerm_subscription.current.id
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1e66d121-f668-4a87-b644-9453d13e7fe6"
    parameters = {
      effect = {
        value = "Deny"
      }
    }
  }]
}
```

### Container Registry Admin Disabled

```hcl
module "policy_assignment_acr_admin_disabled" {
  source = "../../modules/policy-assignment"

  assignments = [{
    key                  = "acr-admin-disabled"
    name                 = "acr-admin-disabled"
    display_name         = "Container Registry Admin Account Disabled"
    scope                = azurerm_resource_group.platform.id
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/86d03658-43ea-4626-89a5-d18a17848185"
    parameters = {
      effect = {
        value = "Deny"
      }
    }
  }]
}
```

### Public Network Access Restrictions

```hcl
module "policy_assignment_storage_public_access" {
  source = "../../modules/policy-assignment"

  assignments = [{
    key                  = "storage-public-access-disabled"
    name                 = "storage-public-access-disabled"
    display_name         = "Storage Public Network Access Disabled"
    scope                = data.azurerm_subscription.current.id
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1c6e92d9-99f0-4e55-9bc6-29639ee1286c"
    parameters = {
      effect = {
        value = "Deny"
      }
    }
    enforcement_mode = "Default"
  }]
}
```

### DeployIfNotExists with System-Assigned Identity

```hcl
module "policy_assignment_dine_identity" {
  source = "../../modules/policy-assignment"

  assignments = [{
    key                  = "deploy-diagnostic-settings"
    name                 = "deploy-diagnostic-settings"
    display_name         = "Deploy Diagnostic Settings to Key Vault"
    scope                = data.azurerm_subscription.current.id
    policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/04d53dbb-906c-4499-b5b0-124718077f47"
    location             = "eastus"
    identity = {
      type = "SystemAssigned"
    }
    parameters = {
      effect = {
        value = "DeployIfNotExists"
      }
    }
  }]
}
```

### Multiple Assignments at Scale

```hcl
module "policy_assignment_platform" {
  source = "../../modules/policy-assignment"

  assignments = local.platform_policy_assignments
}
```

Define `local.platform_policy_assignments` in environment `locals.tf` and pass subscription or management group scopes from existing data sources.

## Best Practices

1. **Assign at the highest appropriate scope** — Use management group or subscription scope for platform-wide guardrails; use resource group scope for workload-specific exceptions.
2. **Use stable keys** — Never use array indices as `for_each` keys. Use descriptive, immutable keys such as `storage-require-https`.
3. **Parameterize effects deliberately** — Set `effect` in parameters per environment (`Audit` in dev, `Deny` in prod) rather than hardcoding in the module.
4. **Use `enforcement_mode` for safe rollout** — Assign with `DoNotEnforce` first, validate compliance in Azure Policy, then switch to `Default`.
5. **Configure identity only when required** — System-assigned identity is required for DeployIfNotExists and Modify policies that deploy or alter resources.
6. **Add non-compliance messages** — Provide actionable remediation guidance for operators reviewing compliance dashboards.
7. **Keep definitions separate** — Maintain custom definitions and initiatives in `policies/`; use this module only for assignments.
8. **Avoid duplicate assignments** — One assignment per policy per scope; use initiatives to bundle related policies.

## Operational Guidance

| Activity | Recommendation |
|----------|----------------|
| Plan review | Confirm scope, policy ID, and parameters before apply |
| Compliance monitoring | Use Azure Policy compliance blade and `azurerm_policy_remediation` (outside this module) for DINE/Modify |
| Identity permissions | After assignment, grant the policy identity required roles on target scopes |
| Drift detection | Reconcile Terraform state when assignments are changed in the portal |
| Removal | Destroying an assignment does not revert resources modified by Modify or DINE policies |

## Governance Strategy

| Layer | Scope | Example policies |
|-------|-------|------------------|
| Landing zone | Management group | Allowed locations, required tags, public access restrictions |
| Subscription | Subscription | Key Vault soft delete, HTTPS on storage, ACR admin disabled |
| Workload | Resource group | Allowed SKUs, environment-specific tag values |
| Resource | Individual resource | Targeted exceptions or supplemental controls |

Recommended rollout:

1. Define or select built-in/custom policies and initiatives (outside this module).
2. Assign at management group with `enforcement_mode = "DoNotEnforce"`.
3. Review compliance and remediate parameter mismatches.
4. Enable enforcement (`Default`) per policy based on change risk.
5. Grant managed identity RBAC for remediation policies.
6. Integrate compliance alerts with Azure Monitor (via separate modules).

## Related Resources

- [Azure Policy documentation](https://learn.microsoft.com/en-us/azure/governance/policy/)
- [Built-in policy definitions index](https://learn.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies)
- [Policy as Code with Terraform](https://learn.microsoft.com/en-us/azure/governance/policy/tutorials/create-and-manage-resources-with-terraform)
- Repository `policies/` directory for custom definitions and initiatives

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
