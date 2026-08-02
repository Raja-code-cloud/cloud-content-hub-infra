# Shared Terraform Foundation

Repository-wide naming, tagging, and configuration standards for **cloud-content-hub-infra**.

Every Azure module and environment root module should consume the shared foundation via `modules/common` and `modules/naming`.

## Architecture

```
environments/<env>/
    └── module "common" ──▶ modules/common/
                                ├── variables (org + env config)
                                ├── locals (merged tags, labels)
                                ├── checks (validation assertions)
                                └── module "naming" ──▶ modules/naming/
                                                            ├── resource catalog
                                                            ├── region abbreviations
                                                            └── name generation

Future resource modules (acr, postgres, ...)
    └── module "common" (tags, names, prefix)
```

## Modules

| Module | Path | Purpose |
|--------|------|---------|
| Common | `modules/common` | Tags, shared variables, pre-computed names, metadata |
| Naming | `modules/naming` | Deterministic Azure resource naming |

Neither module creates Azure resources.

---

## Naming Strategy

### Pattern

Standard resources use hyphenated names:

```
<project>-<environment>-<resource-type>[-<instance>]
```

| Segment | Example | Description |
|---------|---------|-------------|
| `project` | `cch` | Short project code (2–8 chars) |
| `environment` | `dev` | Environment identifier |
| `resource-type` | `acr` | Catalog slug for the Azure service |
| `instance` | `api` | Optional disambiguator |

### Examples

| Resource | Generated Name |
|----------|----------------|
| Container Registry | `cch-dev-acr` |
| Container Apps Environment | `cch-dev-cae` |
| Container App | `cch-dev-api` |
| Storage Account | `cchdeveusstorage` *(globally unique, no hyphens)* |
| PostgreSQL | `cch-dev-postgres` |
| Resource Group | `cch-dev-rg` |

### Globally Unique Names

Resources requiring global uniqueness (e.g. storage accounts) use:

- No hyphens
- Compact prefix: `<project><env-abbr>` (e.g. `cchdev`)
- Location short code when required: `cchdeveusstorage`

### Resource Catalog

Supported `resource_type` keys and constraints are defined in `modules/naming/locals.tf`:

| Key | Slug | Max Length | Location in Name |
|-----|------|------------|------------------|
| `acr` | acr | 50 | No |
| `cae` | cae | 60 | No |
| `api` | api | 32 | No |
| `storage` | storage | 24 | Yes |
| `postgres` | postgres | 63 | No |
| `redis` | redis | 63 | No |
| `key_vault` | kv | 24 | No |
| `resource_group` | rg | 90 | No |

Extend the catalog by adding entries to `local.resource_catalog` in the naming module.

### Single-Name Mode

```hcl
module "acr_name" {
  source = "../../modules/naming"

  project_name     = "cch"
  application_name = "cloud-content-hub"
  environment      = "dev"
  location         = "eastus"
  resource_type    = "acr"
}

# module.acr_name.name => "cch-dev-acr"
```

### Batch Mode

```hcl
module "platform_names" {
  source = "../../modules/naming"

  project_name     = "cch"
  application_name = "cloud-content-hub"
  environment      = "dev"
  location         = "eastus"

  resources = {
    acr      = { resource_type = "acr" }
    postgres = { resource_type = "postgres" }
    api      = { resource_type = "api", instance = "api" }
  }
}

# module.platform_names.names["acr"] => "cch-dev-acr"
```

---

## Tagging Strategy

### Base Tags

Every resource receives a merged tag set from `modules/common`:

| Tag Key | Source Variable | Example |
|---------|-----------------|---------|
| `Project` | `project_name` | `cch` |
| `Application` | `application_name` | `cloud-content-hub` |
| `Environment` | `environment` | `dev` |
| `Owner` | `owner` | `platform-engineering` |
| `ManagedBy` | `managed_by` | `terraform` |
| `Repository` | `repository_name` | `cloud-content-hub-infra` |
| `Terraform` | static | `true` |
| `CostCenter` | `cost_center` | `ENG-001` |
| `BusinessUnit` | `business_unit` | `engineering` |
| `CreatedBy` | `created_by` | `platform-engineering` |

### Merge Order

```
base_tags → additional_tags → tags
```

Module-specific tags should be passed via `additional_tags` at the environment or module level:

```hcl
module "common" {
  source = "../../modules/common"
  # ...
  additional_tags = {
    Workload = "platform"
  }
}
```

### Required Tags

When `enforce_required_tags = true` (default), the common module validates that all organizational tag keys are non-empty via a `check` block.

---

## Common Variables

All shared variables are defined in `modules/common/variables.tf`:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `project_name` | Yes | — | Project code for naming and tags |
| `application_name` | Yes | — | Application identifier |
| `environment` | Yes | — | `dev`, `stage`, or `prod` |
| `location` | Yes | — | Azure region |
| `location_short` | No | computed | Region abbreviation override |
| `resource_prefix` | No | computed | Prefix override |
| `owner` | Yes | — | Resource owner |
| `business_unit` | Yes | — | Business unit |
| `cost_center` | Yes | — | Cost center code |
| `repository_name` | No | `cloud-content-hub-infra` | Source repo |
| `managed_by` | No | `terraform` | Lifecycle manager |
| `created_by` | No | `platform-engineering` | Creator identity |
| `tags` | No | `{}` | Additional tags |
| `additional_tags` | No | `{}` | Supplementary tags |
| `standard_resource_names` | No | platform defaults | Pre-computed name map |
| `enforce_required_tags` | No | `true` | Tag validation toggle |

Every variable includes `description`, `type`, `nullable`, and `validation` where appropriate.

---

## Common Locals

Computed in `modules/common/locals.tf`:

| Local | Description |
|-------|-------------|
| `computed_resource_prefix` | `<project>-<environment>` or override |
| `base_tags` | Organizational tag set |
| `merged_tags` | Final tags after all merges |
| `environment_short` | `dev`, `stg`, `prd` |
| `standard_labels` | Combined naming + org metadata |

Avoid duplicating these expressions in resource modules — consume `module.common` outputs instead.

---

## Environment Configuration

### Standard Pattern

Each environment supplies values via `terraform.tfvars` (never committed):

```
environments/
├── dev/terraform.tfvars.example
├── stage/terraform.tfvars.example
└── prod/terraform.tfvars.example
```

### Required Values Per Environment

| Value | dev | stage | prod |
|-------|-----|-------|------|
| `environment` | `dev` | `stage` | `prod` |
| `subscription_id` | non-prod sub | non-prod sub | prod sub |
| `project_name` | from org standard | same | same |
| `location` | per env policy | per env policy | per env policy |
| `owner` | team name | team name | team name |
| `cost_center` | chargeback code | chargeback code | chargeback code |

No environment-specific values are hardcoded in Terraform source. The environment root module validates that `var.environment` matches the folder name.

### Supply Methods

| Method | Use Case |
|--------|----------|
| `terraform.tfvars` | Local development |
| `-var-file` | CI/CD pipelines |
| GitHub Environment variables | Per-environment secrets and config |
| `TF_VAR_*` environment variables | Automation |

---

## Validation Rules

| Rule | Location | Behavior |
|------|----------|----------|
| Allowed environments | Variable validation | `dev`, `stage`, `prod` only |
| Allowed Azure regions | Variable validation | 16 supported regions |
| Project name format | Variable validation | 2–8 lowercase alphanumeric |
| Resource prefix length | `check` block | Max 24 characters |
| Required tags | `check` block | Non-empty organizational tags |
| Resource type catalog | Variable validation | Must be known catalog key |
| Instance suffix format | Variable validation | Lowercase alphanumeric + hyphens |

---

## Outputs

### Common Module Outputs

| Output | Description |
|--------|-------------|
| `resource_prefix` | Standard name prefix |
| `tags` | Merged tag map |
| `resource_names` | Pre-computed platform names |
| `metadata` | Deployment metadata aggregate |
| `standard_labels` | Labels for diagnostics |
| `naming` | Advanced naming module outputs |

Secrets are never exposed through shared outputs.

---

## Usage in Future Modules

```hcl
module "common" {
  source = "../../modules/common"
  # ... pass through environment variables
}

module "acr" {
  source = "../../modules/acr"

  name     = module.common.resource_names["acr"]
  location = module.common.location
  tags     = module.common.tags
}
```

---

## Best Practices

1. **Always consume `module.common`** in environment roots — never duplicate tag or naming logic.
2. **Use the naming catalog** — add new resource types to `modules/naming/locals.tf` before use.
3. **Pass module tags via `additional_tags`** — do not rebuild base tags in resource modules.
4. **Keep tfvars out of git** — use `.example` files as templates only.
5. **Validate early** — rely on variable validation and `check` blocks to fail at plan time.
6. **Extend, don't fork** — propose catalog additions via PR rather than local naming overrides.

## Related

- [Terraform Standards](standards.md)
- [Provider Inheritance](provider-inheritance.md)
- [CI/CD Architecture](../cicd/README.md)
- [Example: Common Usage](../../examples/common-usage/README.md)
