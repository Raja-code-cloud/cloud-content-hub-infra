# Versioning

Version policy for releases, modules, providers, and environment compatibility.

## Version Hierarchy

```
Release Tag (v1.2.3)
    └── Git Commit (immutable ref for prod)
            └── Environment Root (environments/<env>/versions.tf)
                    └── Module Interface (variables/outputs)
                            └── Provider Constraints (azurerm ~> 5.0)
```

## Semantic Versioning

```
v<MAJOR>.<MINOR>.<PATCH>[-<pre-release>]

MAJOR — Breaking module interface, state migration, or provider major upgrade
MINOR — New modules, new environment features, non-breaking enhancements
PATCH — Bug fixes, documentation, non-breaking module changes
```

### Tag naming

| Pattern | Purpose | Production Deploy |
|---------|---------|-------------------|
| `v1.2.3` | Standard release | Yes |
| `v1.2.3-rc.1` | Release candidate | No (stage only) |
| `v1.2.3-hotfix.1` | Emergency fix | Yes (emergency workflow) |

## Repository Releases

Created by `release.yml` on tag push:

1. Validate all environments
2. Security scan
3. Plan all environments
4. Publish GitHub Release with artifacts

### Release notes template

[templates/release-notes.md.tpl](../templates/release-notes.md.tpl)

## Module Compatibility

Modules are versioned implicitly via repository Git tags.

| Change Type | Version Bump | Environment Update Required |
|-------------|--------------|----------------------------|
| New optional variable | PATCH | No |
| New required variable | MINOR | Yes — update tfvars |
| Removed/changed output | MAJOR | Yes — update downstream refs |
| New module added | MINOR | Optional adoption |
| Provider attribute change | MAJOR or provider upgrade | Plan review all envs |

Modules are **not** published to a registry. All environments reference relative paths:

```hcl
source = "../../modules/<name>"
```

## Environment Compatibility

All environments deploy the **same module code** at a given release tag. Environment-specific values live in `terraform.tfvars` (not committed).

| Environment | Version Source | May Run Ahead |
|-------------|----------------|---------------|
| dev | Latest `develop` commit | Yes |
| stage | Latest `main` commit | No |
| prod | Release tag only | No |

### Compatibility matrix (example)

| Release Tag | Terraform | azurerm | Environments |
|-------------|-----------|---------|--------------|
| v1.0.0 | 1.13.0 | 5.0.1 | dev, stage, prod |
| v1.1.0 | 1.13.0 | 5.0.1 | dev, stage, prod |

Record compatibility in release notes for each tag.

## Tool Version Pinning

| Tool | Pin Location | Value |
|------|--------------|-------|
| Terraform | `.github/workflows/*.yml` `TF_VERSION` | `1.13.0` |
| Terraform | `deployment/scripts/lib/common.sh` | `1.13.0` |
| TFLint | `.github/workflows/terraform-lint.yml` | See workflow |
| Checkov | `.github/workflows/terraform-security.yml` | See workflow |

### Upgrade process

1. Update pin in all workflow files and `common.sh`
2. Run quality gates on all environments
3. Create PR with validation evidence
4. Follow [provider upgrade runbook](../../docs/runbooks/provider-upgrade.md)

## Provider Lock Files

| Rule | Description |
|------|-------------|
| Commit lock files | `.terraform.lock.hcl` per environment |
| Promotion includes lock | Plan artifacts use lock from pinned git ref |
| Upgrade via PR | `terraform init -upgrade` in controlled change |

## Related

- [Deployment Versioning](../../deployment/versioning/README.md)
- [Artifact Strategy](artifact-strategy.md)
- [Change Management](change-management.md)
