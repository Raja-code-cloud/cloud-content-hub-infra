# Runbook: Provider Upgrade

Upgrade Terraform providers (primarily `azurerm`) safely across all environments.

## Overview

Provider upgrades affect resource schemas and attribute mappings. This runbook ensures zero-downtime upgrades where possible.

## Current Versions

| Provider | Constraint | Lock File |
|----------|------------|-----------|
| `azurerm` | `~> 5.0` | `environments/<env>/.terraform.lock.hcl` |
| `azapi` | `~> 2.0` | Same |
| `random` | `~> 3.6` | Same |
| `time` | `~> 0.12` | Same |

## Pre-Upgrade Checklist

- [ ] Review provider changelog (breaking changes)
- [ ] Review module `locals.tf` for deprecated attribute mappings
- [ ] All environments passing validation on current version
- [ ] State backups current
- [ ] Change ticket created

## Upgrade Procedure

### 1. Create upgrade branch

```bash
git checkout develop
git pull
git checkout -b chore/provider-upgrade-azurerm-x.y
```

### 2. Update constraint (if major version)

Edit `environments/*/versions.tf` if changing constraint (e.g., `~> 5.0` → `~> 6.0`).

### 3. Upgrade lock files

For each environment:

```bash
cd environments/dev
terraform init -upgrade -backend=false
cd ../stage && terraform init -upgrade -backend=false
cd ../prod && terraform init -upgrade -backend=false
```

### 4. Validate

```bash
./deployment/scripts/validate/run-all.sh dev --skip-backend
./deployment/scripts/validate/run-all.sh stage --skip-backend
./deployment/scripts/validate/run-all.sh prod --skip-backend
```

### 5. Plan (requires backend)

```bash
./deployment/scripts/deploy/plan.sh dev
./deployment/scripts/deploy/plan.sh stage
# Review for unexpected changes — provider upgrades should show minimal diffs
```

### 6. Apply in order

```
dev → stage → prod
```

```bash
./deployment/scripts/deploy/apply.sh dev
# Validate dev, then stage, then prod with approvals
```

### 7. Update documentation

- [ ] Update `deployment/versioning/README.md` if constraint changed
- [ ] Update `docs/terraform/provider-inheritance.md`
- [ ] Update module README provider tables if needed
- [ ] Record in ADR if breaking change

## azurerm v5 Migration Notes

The repository migrated from azurerm v4 to v5. Key attribute renames handled in module locals:

| v4 Attribute | v5 Attribute |
|-------------|-------------|
| `enable_rbac_authorization` | `rbac_authorization_enabled` |
| `internet_query_enabled` | `internet_query_enabled` (access type enums) |
| Various bool flags | `*_enabled` suffix pattern |

If upgrading to v6+, audit all module `locals.tf` files for deprecated mappings.

## Rollback

If upgrade causes plan failures or apply errors:

```bash
git checkout develop
# Restore previous lock files from git
terraform init -backend=false
./deployment/scripts/validate/run-all.sh dev --skip-backend
```

If already applied:

```bash
./deployment/scripts/rollback/rollback.sh dev <pre-upgrade-tag>
```

## Testing Matrix

| Environment | Validate | Plan | Apply | Verify |
|-------------|----------|------|-------|--------|
| dev | Required | Required | Required | Outputs + health |
| stage | Required | Required | Required | Integration tests |
| prod | Required | Required | Required + 2 approvers | Full verification |

## Schedule

| Activity | Recommended Frequency |
|----------|----------------------|
| Patch provider upgrade | Monthly (automated PR) |
| Minor provider upgrade | Quarterly |
| Major provider upgrade | Annually with ADR |

## Related

- [Versioning Policy](../../deployment/versioning/README.md)
- [Provider Inheritance](../terraform/provider-inheritance.md)
- [Validation Gates](../../deployment/validate/README.md)
