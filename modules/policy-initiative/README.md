# Azure Policy Initiative Module

Creates **Azure Policy Initiatives** (Policy Set Definitions) by grouping multiple policy definitions into reusable governance bundles. Does not create policy definitions, assignments, exemptions, management groups, subscriptions, or other Azure resources.

## Purpose

- Group built-in and custom **policy definitions** into reusable initiatives
- Support multiple initiatives via stable `for_each` keys
- Configure initiative parameters, metadata, policy groups, and per-definition parameter values
- Enable versioned, composable governance baselines for platform and workload teams

This module creates **only** Azure Policy Initiative resources:

- `azurerm_policy_set_definition` (subscription-scoped custom initiatives)
- `azurerm_management_group_policy_set_definition` (management group-scoped initiatives)

## Architecture

```
policies/definitions/              ──▶ policy_definition_id (existing, not created here)
environments/<env>/locals.tf     ──▶ initiatives list (definitions, groups, parameters)
        │
        ▼
module "policy_initiative"       ──▶ policy set definition (for_each)
        │
        ▼
module "policy_assignment"       ──▶ initiative assignment (separate module)
        │
        ▼
Azure Policy engine              ──▶ Compliance evaluation at assigned scopes
```

Policy definitions and assignment scopes must already exist. Assign initiatives using `modules/policy-assignment`.

When `management_group_id` is omitted, the initiative is created at **subscription scope** via `azurerm_policy_set_definition`. When `management_group_id` is provided, the initiative is created at **management group scope**.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 5.0 |

Providers are inherited from the environment root module.

## Inputs

### `initiatives`

List of policy initiative objects. Each entry requires a unique `key` for stable Terraform state at scale.

| Field | Required | Description |
|-------|:--------:|-------------|
| `key` | yes | Stable identifier for `for_each` (2–64 chars, lowercase alphanumeric/hyphen) |
| `name` | yes | Azure Policy Initiative resource name (1–64 chars; unique across module) |
| `display_name` | yes | Human-readable initiative display name (1–128 chars) |
| `policy_type` | yes | `BuiltIn`, `Custom`, `NotSpecified`, or `Static` (use `Custom` for Terraform-managed initiatives) |
| `policy_definitions` | yes | List of referenced policy definitions (minimum one; no duplicates) |
| `description` | no | Initiative description (1–2048 chars) |
| `management_group_id` | no | Management group ARM ID; omit for subscription-scoped initiatives |
| `metadata` | no | Initiative metadata map (JSON-encoded; include version/category attributes) |
| `parameters` | no | Initiative-level parameter schema map (JSON-encoded) |
| `policy_groups` | no | Logical groupings for referenced policies |

#### `policy_definitions` object

| Field | Required | Description |
|-------|:--------:|-------------|
| `policy_definition_id` | yes | Built-in or custom policy definition resource ID |
| `reference_id` | no | Stable reference ID within the initiative (unique per initiative) |
| `parameters` | no | Parameter values for the referenced policy (auto-wrapped as `{ value = ... }`) |
| `group_names` | no | Policy group names this definition belongs to |
| `version` | no | Policy definition version pin (for versioned built-in policies) |

#### `policy_groups` object

| Field | Required | Description |
|-------|:--------:|-------------|
| `name` | yes | Unique group name within the initiative |
| `display_name` | no | Group display name |
| `description` | no | Group description |
| `category` | no | Group category label |
| `additional_metadata_resource_id` | no | ARM resource ID for additional group metadata |

### Parameter semantics

| Level | Purpose | Example |
|-------|---------|---------|
| Initiative `parameters` | Defines initiative-level parameter schema exposed at assignment time | Allowed locations list passed into multiple member policies |
| Policy `parameters` | Sets member policy parameter values within the initiative | `{ effect = { value = "Deny" } }` |

## Outputs

| Name | Description |
|------|-------------|
| `initiative_ids` | Map of keys to initiative resource IDs |
| `initiative_names` | Map of keys to initiative resource names |
| `policy_definition_counts` | Map of keys to number of referenced policy definitions |
| `policy_definition_references` | Map of keys to referenced policy definition metadata |
| `initiatives` | Metadata object map for downstream composition |

## Examples

### Security Baseline

```hcl
module "policy_initiative_security_baseline" {
  source = "../../modules/policy-initiative"

  initiatives = [{
    key          = "security-baseline"
    name         = "cch-security-baseline"
    display_name = "Cloud Content Hub Security Baseline"
    description  = "Core security controls for storage, Key Vault, and container registry"
    policy_type  = "Custom"
    metadata = {
      category = "Security"
      version  = "1.0.0"
    }
    policy_groups = [
      {
        name         = "Storage"
        display_name = "Storage Security"
        category     = "Security"
      },
      {
        name         = "KeyVault"
        display_name = "Key Vault Security"
        category     = "Security"
      },
      {
        name         = "ContainerRegistry"
        display_name = "Container Registry Security"
        category     = "Security"
      },
    ]
    policy_definitions = [
      {
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c5141-0f2d-4551-877a-3fce8836795f"
        reference_id         = "storage-require-https"
        group_names          = ["Storage"]
        parameters = {
          effect = { value = "Deny" }
        }
      },
      {
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1e66d121-f668-4a87-b644-9453d13e7fe6"
        reference_id         = "kv-soft-delete"
        group_names          = ["KeyVault"]
        parameters = {
          effect = { value = "Deny" }
        }
      },
      {
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/86d03658-43ea-4626-89a5-d18a17848185"
        reference_id         = "acr-admin-disabled"
        group_names          = ["ContainerRegistry"]
        parameters = {
          effect = { value = "Deny" }
        }
      },
    ]
  }]
}
```

### Cost Optimization

```hcl
module "policy_initiative_cost_optimization" {
  source = "../../modules/policy-initiative"

  initiatives = [{
    key          = "cost-optimization"
    name         = "cch-cost-optimization"
    display_name = "Cloud Content Hub Cost Optimization"
    description  = "Controls to reduce unnecessary spend"
    policy_type  = "Custom"
    metadata = {
      category = "Cost"
      version  = "1.0.0"
    }
    policy_definitions = [
      {
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/7433c107-153d-44f5-ac69-a8e9a6661898"
        reference_id         = "storage-allowed-skus"
        parameters = {
          listOfAllowedSKUs = { value = ["Standard_LRS", "Standard_GRS"] }
          effect            = { value = "Audit" }
        }
      },
      {
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/06a78e20-9358-41c9-923c-fb736d382a12"
        reference_id         = "disk-premium-restrict"
        parameters = {
          effect = { value = "Audit" }
        }
      },
    ]
  }]
}
```

### Monitoring Baseline

```hcl
module "policy_initiative_monitoring_baseline" {
  source = "../../modules/policy-initiative"

  initiatives = [{
    key          = "monitoring-baseline"
    name         = "cch-monitoring-baseline"
    display_name = "Cloud Content Hub Monitoring Baseline"
    description  = "Diagnostic and monitoring guardrails"
    policy_type  = "Custom"
    metadata = {
      category = "Monitoring"
      version  = "1.0.0"
    }
    policy_groups = [{
      name         = "Diagnostics"
      display_name = "Diagnostic Settings"
      category     = "Monitoring"
    }]
    policy_definitions = [
      {
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/04d53dbb-906c-4499-b5b0-124718077f47"
        reference_id         = "kv-deploy-diagnostics"
        group_names          = ["Diagnostics"]
        parameters = {
          effect = { value = "AuditIfNotExists" }
        }
      },
      {
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/7f89b1eb-583c-4297-9a8d-4af8017dbb89"
        reference_id         = "storage-deploy-diagnostics"
        group_names          = ["Diagnostics"]
        parameters = {
          effect = { value = "AuditIfNotExists" }
        }
      },
    ]
  }]
}
```

### Tagging Baseline

```hcl
module "policy_initiative_tagging_baseline" {
  source = "../../modules/policy-initiative"

  initiatives = [{
    key                 = "tagging-baseline"
    name                = "cch-tagging-baseline"
    display_name        = "Cloud Content Hub Tagging Baseline"
    description         = "Required tags for resource groups and resources"
    management_group_id = "/providers/Microsoft.Management/managementGroups/contoso-platform"
    policy_type         = "Custom"
    metadata = {
      category = "Tags"
      version  = "1.0.0"
    }
    policy_groups = [{
      name         = "RequiredTags"
      display_name = "Required Tags"
      category     = "Tags"
    }]
    policy_definitions = [
      {
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d94-1749-438a-b928-8cac33af9950"
        reference_id         = "require-environment-tag-rg"
        group_names          = ["RequiredTags"]
        parameters = {
          tagName = { value = "Environment" }
          effect  = { value = "Deny" }
        }
      },
      {
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-4786-b786-892b0f293203"
        reference_id         = "require-owner-tag-rg"
        group_names          = ["RequiredTags"]
        parameters = {
          tagName = { value = "Owner" }
          effect  = { value = "Deny" }
        }
      },
    ]
  }]
}
```

### Networking Baseline

```hcl
module "policy_initiative_networking_baseline" {
  source = "../../modules/policy-initiative"

  initiatives = [{
    key          = "networking-baseline"
    name         = "cch-networking-baseline"
    display_name = "Cloud Content Hub Networking Baseline"
    description  = "Network access and endpoint protection controls"
    policy_type  = "Custom"
    metadata = {
      category = "Networking"
      version  = "1.0.0"
    }
    policy_definitions = [
      {
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1c6e92d9-99f0-4e55-9bc6-29639ee1286c"
        reference_id         = "storage-public-access-disabled"
        parameters = {
          effect = { value = "Deny" }
        }
      },
      {
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0a370103-6492-439e-b056-1fd0575961b5"
        reference_id         = "keyvault-public-access-disabled"
        parameters = {
          effect = { value = "Deny" }
        }
      },
    ]
  }]
}
```

### Cloud Content Hub Platform Baseline

```hcl
module "policy_initiative_platform_baseline" {
  source = "../../modules/policy-initiative"

  initiatives = local.platform_policy_initiatives
}

# environments/<env>/locals.tf
locals {
  platform_policy_initiatives = [{
    key                 = "cch-platform-baseline"
    name                = "cch-platform-baseline-v1"
    display_name        = "Cloud Content Hub Platform Baseline v1"
    description         = "Consolidated platform governance for Cloud Content Hub workloads"
    management_group_id = "/providers/Microsoft.Management/managementGroups/contoso-platform"
    policy_type         = "Custom"
    metadata = {
      category    = "Platform"
      version     = "1.0.0"
      owner       = "platform-engineering"
      environment = "all"
    }
    parameters = {
      allowedLocations = {
        type = "Array"
        metadata = {
          displayName  = "Allowed locations"
          description  = "Approved Azure regions for Cloud Content Hub resources"
          strongType   = "location"
        }
      }
    }
    policy_groups = [
      { name = "Security", display_name = "Security Controls", category = "Security" },
      { name = "Tags", display_name = "Tagging Controls", category = "Tags" },
      { name = "Networking", display_name = "Network Controls", category = "Networking" },
    ]
    policy_definitions = [
      {
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49bd-b67c-b17fd847b4a7"
        reference_id         = "allowed-locations"
        group_names          = ["Security"]
        parameters = {
          listOfAllowedLocations = { value = ["eastus", "eastus2", "centralus"] }
          effect                 = { value = "Deny" }
        }
      },
      {
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d94-1749-438a-b928-8cac33af9950"
        reference_id         = "require-environment-tag"
        group_names          = ["Tags"]
        parameters = {
          tagName = { value = "Environment" }
          effect  = { value = "Deny" }
        }
      },
      {
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1c6e92d9-99f0-4e55-9bc6-29639ee1286c"
        reference_id         = "storage-public-access-disabled"
        group_names          = ["Networking"]
        parameters = {
          effect = { value = "Deny" }
        }
      },
    ]
  }]
}
```

Assign the resulting initiative with `modules/policy-assignment`:

```hcl
module "policy_assignment_platform_baseline" {
  source = "../../modules/policy-assignment"

  assignments = [{
    key                  = "cch-platform-baseline-assignment"
    name                 = "cch-platform-baseline"
    display_name         = "Cloud Content Hub Platform Baseline"
    scope                = data.azurerm_subscription.current.id
    policy_definition_id = module.policy_initiative_platform_baseline.initiative_ids["cch-platform-baseline"]
  }]
}
```

## Governance Strategy

| Baseline | Scope | Typical assignment |
|----------|-------|-------------------|
| Security | Management group | All landing zone subscriptions |
| Cost | Subscription | Non-production subscriptions first |
| Monitoring | Subscription | Platform and workload subscriptions |
| Tagging | Management group | Entire tenant hierarchy |
| Networking | Management group | Production landing zones |
| Platform | Management group | Cloud Content Hub platform MG |

Recommended workflow:

1. Define initiatives with this module at the highest reusable scope (management group when shared across subscriptions).
2. Assign initiatives with `modules/policy-assignment` using report-only enforcement first.
3. Review compliance, tune parameters, and increment `metadata.version`.
4. Enable enforcement on assignments after validation.
5. Split large initiatives into focused baselines to reduce blast radius and simplify ownership.

## Best Practices

1. **Use descriptive reference IDs** — Stable `reference_id` values simplify non-compliance messages and assignment overrides.
2. **Group related policies** — Use `policy_groups` to organize initiatives for portal navigation and selective compliance reporting.
3. **Version in metadata** — Set `metadata.version` (for example `1.0.0`) and create new initiative names for breaking changes.
4. **Avoid duplicate definitions** — Each policy should appear once per initiative; use parameters for effect variance.
5. **Keep initiatives focused** — Prefer multiple small baselines over one monolithic initiative.
6. **Separate definition from assignment** — This module creates initiatives only; assignments remain in `policy-assignment`.
7. **Pin built-in policy versions** — Use `version` on references when Microsoft updates built-in policy behavior.
8. **Validate group membership** — Ensure every `group_names` entry maps to a declared `policy_groups.name`.

## Versioning Guidance

| Change type | Approach |
|-------------|----------|
| Parameter default change | Update initiative in place; bump `metadata.version` patch (for example `1.0.0` → `1.0.1`) |
| Add policy to initiative | Update in place if non-breaking; bump minor version (for example `1.0.0` → `1.1.0`) |
| Remove or replace policy | Create new initiative name (for example `cch-platform-baseline-v2`); migrate assignments |
| Effect change (Audit → Deny) | Test via assignment `enforcement_mode` before changing initiative parameters |

Terraform initiative `name` changes force resource replacement. Prefer immutable name versioning (`-v1`, `-v2`) for major baseline revisions.

Store initiative definitions in environment `locals.tf` or dedicated governance tfvars files. Reference output `initiative_ids` when wiring `policy-assignment`.

## Related Resources

- [Azure Policy initiative documentation](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure-basics)
- [Policy set definition structure](https://learn.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure#policy-sets)
- Repository `modules/policy-assignment` for initiative assignments
- Repository `policies/` directory for custom policy definitions

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
