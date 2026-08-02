# Runbook: Deploy

Standard infrastructure deployment procedure for all environments.

## Overview

| Step | Tool / Script | Gate |
|------|---------------|------|
| 1. Validate | `validate/run-all.sh` | Automated |
| 2. Plan | `deploy/plan.sh` | Review plan.txt |
| 3. Approve | GitHub Environment | Human |
| 4. Apply | `deploy/apply.sh` | Confirmation phrase |
| 5. Verify | `terraform output` | Operator |

## Before You Begin

- [ ] Change ticket created (stage/prod)
- [ ] Target commit identified (branch or tag)
- [ ] Previous deployment status known (no stuck locks)
- [ ] Secrets available in GitHub Environment or local env vars

## Deployment by Environment

### Development

```bash
git checkout develop && git pull
./deployment/scripts/validate/run-all.sh dev --skip-backend
./deployment/scripts/bootstrap/init-backend.sh dev
./deployment/scripts/deploy/plan.sh dev
./deployment/scripts/deploy/apply.sh dev
```

Or via GitHub Actions: **Terraform Apply** → `dev` → confirmation: `dev`

### Staging

Via GitHub Actions (preferred):

1. Merge to `main`
2. **Terraform Plan** → `stage`
3. Review artifact
4. **Terraform Apply** → `stage` → confirmation: `stage`
5. 1+ reviewer approves

### Production

Via GitHub Actions only (except break-glass):

1. Push tag `v*.*.*`
2. Verify `release.yml` passed
3. **Terraform Apply** → `prod` → confirmation: `prod`
4. 2+ reviewers approve
5. Use plan artifact from release workflow when possible

## Post-Deploy Verification

```bash
cd environments/<env>
terraform output
```

| Check | Expected |
|-------|----------|
| `container_app_url` | HTTPS URL responds |
| `acr_login_server` | ACR accessible |
| `key_vault_uri` | Vault reachable |
| `postgresql_fqdn` | DNS resolves |
| Application Insights | Telemetry flowing |

## Failure Handling

| Failure Point | Action |
|---------------|--------|
| Validation fails | Fix code, do not proceed |
| Plan shows unexpected changes | Stop — investigate before apply |
| Apply fails mid-run | See [rollback.md](rollback.md) |
| Outputs missing | Check state: `terraform state list` |

## Escalation

| Severity | Contact |
|----------|---------|
| dev failure | Developer on-call |
| stage failure | Release engineer |
| prod failure | Platform admin + on-call |

## Related

- [Deployment Framework](../../deployment/deploy/README.md)
- [Approval Gates](../../deployment/deploy/approval-gates.md)
