# Staging Deployment

Deployment procedure for the **stage** environment.

## Profile

| Property | Value |
|----------|-------|
| Directory | `environments/stage` |
| State key | `stage.tfstate` |
| Approval gate | **Required** — 1+ reviewer |
| Destroy | Allowed (with confirmation) |
| Purpose | Pre-production validation and integration testing |

## When to Deploy

- Release branch merged to `main` (pre-production soak)
- Promotion from dev after successful dev validation
- Before production deployment (mandatory gate)

## Prerequisites

- [ ] Dev deployment validated and stable
- [ ] Bootstrap complete for stage
- [ ] GitHub Environment `stage` configured with required reviewers
- [ ] All PR CI checks pass on target commit
- [ ] Release tag recommended (see [release/README.md](../release/README.md))

## Deployment Steps

### GitHub Actions (preferred)

1. Create PR from `develop` → `main` (or `release/*` → `main`)
2. Wait for **Pull Request Gate** to pass
3. Merge to `main`
4. Actions → **Terraform Plan** → environment: `stage`
5. Review plan artifact with release engineer
6. Actions → **Terraform Apply** → environment: `stage`, confirmation: `stage`
7. GitHub Environment approval gate — 1+ reviewer approves
8. Apply executes

### Local (break-glass only)

Local apply to stage requires platform admin privileges and is discouraged. If required:

```bash
./deployment/scripts/validate/run-all.sh stage
./deployment/scripts/bootstrap/init-backend.sh stage
./deployment/scripts/deploy/plan.sh stage
# Manual review of plan.txt
./deployment/scripts/deploy/apply.sh stage
```

Document break-glass usage in the change ticket.

## Staging Validation Checklist

After deploy:

- [ ] `terraform output` returns expected values
- [ ] Container App ingress responds on health endpoint
- [ ] Application Insights receiving telemetry
- [ ] Key Vault secrets accessible by workload identity
- [ ] PostgreSQL connectivity verified
- [ ] No unexpected Checkov CRITICAL regressions vs dev

## Promotion to Production

Stage must be stable for the agreed soak period before production promotion. See [release/README.md](../release/README.md).

## Related

- [Approval Gates](approval-gates.md)
- [Production Deployment](prod.md)
