# Development Deployment

Deployment procedure for the **dev** environment.

## Profile

| Property | Value |
|----------|-------|
| Directory | `environments/dev` |
| State key | `dev.tfstate` |
| Approval gate | Optional |
| Destroy | Allowed (with confirmation) |
| Target cost | < $150/month |
| Scale | Single user, scale-to-zero |

## When to Deploy

- Feature branch merged to `develop`
- Manual iteration during module integration
- After successful PR validation (all CI checks pass)

## Prerequisites

- [ ] Bootstrap complete ([bootstrap/README.md](../bootstrap/README.md))
- [ ] `environments/dev/backend.hcl` configured
- [ ] `environments/dev/terraform.tfvars` configured
- [ ] Azure authentication active
- [ ] Container image pushed to ACR (for Container App to start)

## Deployment Steps

### Option A — Local

```bash
# Full pipeline
./deployment/scripts/validate/run-all.sh dev --skip-backend
./deployment/scripts/bootstrap/init-backend.sh dev
./deployment/scripts/deploy/plan.sh dev
./deployment/scripts/deploy/apply.sh dev
```

### Option B — GitHub Actions

1. Merge PR to `develop`
2. Actions → **Terraform Plan** → environment: `dev`
3. Review plan artifact
4. Actions → **Terraform Apply** → environment: `dev`, confirmation: `dev`

## Dev-Specific Settings

Applied in `environments/dev/main.tf`:

| Resource | Setting |
|----------|---------|
| Log Analytics | 1 GB/day quota, 30-day retention |
| Application Insights | 50% sampling |
| ACR | Basic SKU, admin disabled |
| Key Vault | Purge protection disabled |
| PostgreSQL | Burstable B1ms |
| Container App | Scale 0–3 |

## Rollback

Dev rollback is low-risk. See [rollback/README.md](../rollback/README.md).

Quick recovery:

```bash
git checkout <previous-tag-or-commit>
./deployment/scripts/deploy/plan.sh dev
./deployment/scripts/deploy/apply.sh dev
```

## Related

- [Environment README](../../environments/dev/README.md)
- [Integration Review](../../docs/terraform/dev-integration-review.md)
