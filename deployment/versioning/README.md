# Versioning

Version policy for Terraform, providers, modules, and releases.

## Version Hierarchy

```
Release Tag (v1.2.3)
    └── Environment Root (environments/<env>/versions.tf)
            └── Module Interface (variables/outputs — semver implied by repo tag)
                    └── Provider Constraints (azurerm ~> 5.0)
```

## Terraform Version Policy

| Policy | Value |
|--------|-------|
| Required version | `>= 1.13.0` |
| CI/CD pinned version | `1.13.0` |
| Local development | Match CI pin (`1.13.0`) |
| Upgrade cadence | Quarterly review; patch upgrades anytime |

### Upgrade process

1. Update `env.TF_VERSION` in all `.github/workflows/*.yml`
2. Update `REQUIRED_TERRAFORM_VERSION` in `deployment/scripts/lib/common.sh`
3. Run full validation suite on all environments
4. Update [provider-upgrade.md](../../docs/runbooks/provider-upgrade.md) changelog
5. Create PR with validation evidence

### Version file locations

```
environments/dev/versions.tf     → required_version = ">= 1.13.0"
.github/workflows/*.yml          → env.TF_VERSION = "1.13.0"
deployment/scripts/lib/common.sh → REQUIRED_TERRAFORM_VERSION
```

## Provider Version Policy

Providers are declared **only** in environment root `versions.tf`. Modules inherit providers.

| Provider | Constraint | Upgrade Policy |
|----------|------------|----------------|
| `azurerm` | `~> 5.0` | Minor upgrades via lock file refresh; major requires integration review |
| `azapi` | `~> 2.0` | Upgrade when azurerm gap exists |
| `random` | `~> 3.6` | Low risk |
| `time` | `~> 0.12` | Low risk |

### Provider upgrade process

1. Run `terraform init -upgrade` in each environment
2. Review `.terraform.lock.hcl` diff
3. Run `terraform validate` and `terraform plan` for all environments
4. Check provider changelog for breaking changes
5. Update module attribute mappings if deprecated (see module locals)
6. Follow [Provider Upgrade Runbook](../../docs/runbooks/provider-upgrade.md)

### Lock file policy

| Rule | Description |
|------|-------------|
| Commit lock files | `.terraform.lock.hcl` committed per environment |
| CI provider cache | `TF_PLUGIN_CACHE_DIR` for deduplication |
| No manual edits | Lock files updated only via `terraform init -upgrade` |

## Module Versioning

Modules in this repository are **not** published to a registry. Versioning is implicit via Git tags.

| Concept | Implementation |
|---------|----------------|
| Module source | Relative path: `source = "../../modules/<name>"` |
| Module version | Git commit / release tag of the repository |
| Interface stability | Breaking variable/output changes require ADR |
| Promotion | Same module code across dev → stage → prod |

### Module change rules

| Change Type | Requirement |
|-------------|-------------|
| New optional variable | Patch release |
| New required variable | Minor release + environment update |
| Removed output | Major release + ADR |
| Resource attribute change | Provider upgrade runbook |

## Release Tagging

### Semantic versioning

```
v<MAJOR>.<MINOR>.<PATCH>

MAJOR — breaking module interface or state migration
MINOR — new modules, new environment features
PATCH — bug fixes, doc updates, non-breaking module changes
```

### Tag workflow

```bash
git tag -a v1.2.3 -m "Release v1.2.3 — add container app environment"
git push origin v1.2.3
```

Triggers `release.yml`:

1. Validate repository
2. Security scan
3. Plan all environments
4. Publish GitHub Release with artifacts

### Tag naming rules

| Pattern | Purpose |
|---------|---------|
| `v*.*.*` | Standard release |
| `v*.*.*-rc.*` | Release candidate (no auto-deploy) |
| `v*.*.*-hotfix.*` | Emergency fix |

## Environment Version Alignment

All environments should deploy from the **same release tag** for production. Dev may run ahead on `develop`.

| Branch | Environment | Version Source |
|--------|-------------|----------------|
| `develop` | dev | Latest commit on develop |
| `main` | stage | Latest commit on main |
| `v*.*.*` tag | prod | Specific release tag |

## Related

- [Release Strategy](../release/README.md)
- [Provider Inheritance](../../docs/terraform/provider-inheritance.md)
- [Provider Upgrade Runbook](../../docs/runbooks/provider-upgrade.md)
