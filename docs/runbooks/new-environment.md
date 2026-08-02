# Runbook: New Environment

Provision a new Terraform environment (dev, stage, or prod) from scratch.

## Scope

This runbook covers environment bootstrap and first deployment. It does **not** create Azure resources directly — all infrastructure is created via Terraform apply.

## Prerequisites

| Requirement | Owner |
|-------------|-------|
| Azure subscription allocated | Platform team |
| State storage account bootstrapped | Platform team |
| GitHub Environment configured | DevOps team |
| OIDC app registration (when enabled) | Security team |
| RBAC for deploying identity | Platform team |

## Procedure

### 1. Verify environment directory

```bash
ls environments/<env>/
# Expected: main.tf, variables.tf, outputs.tf, locals.tf,
#           versions.tf, providers.tf, backend.tf,
#           terraform.tfvars.example, backend.hcl.example
```

For a net-new environment, copy from an existing environment and adjust `variables.tf` validation and sizing in `main.tf`.

### 2. Configure backend

```bash
cp environments/<env>/backend.hcl.example environments/<env>/backend.hcl
# Edit with real storage account values
```

State key must be unique:

| Environment | Key |
|-------------|-----|
| dev | `dev.tfstate` |
| stage | `stage.tfstate` |
| prod | `prod.tfstate` |

### 3. Configure variables

```bash
cp environments/<env>/terraform.tfvars.example environments/<env>/terraform.tfvars
# Edit — never commit terraform.tfvars
```

Required values:

- `subscription_id`
- `project_name`, `application_name`, `location`
- `owner`, `business_unit`, `cost_center`
- `postgresql_admin_password` (via env var or tfvars)
- `deployment_principal_id` (OIDC SP object ID)

### 4. Bootstrap Terraform

```bash
./deployment/scripts/bootstrap/select-environment.sh <env>
./deployment/scripts/bootstrap/init-backend.sh <env>
./deployment/scripts/bootstrap/validate-providers.sh <env>
```

### 5. Validate

```bash
./deployment/scripts/validate/run-all.sh <env>
```

### 6. First deployment

```bash
./deployment/scripts/deploy/plan.sh <env>
# Review environments/<env>/plan.txt
./deployment/scripts/deploy/apply.sh <env>
```

### 7. Verify outputs

```bash
cd environments/<env>
terraform output
```

### 8. Configure GitHub Environment

Settings → Environments → Create `<env>`:

- Add secrets (see [approval-gates.md](../../deployment/deploy/approval-gates.md))
- Configure required reviewers
- Restrict deployment branches

### 9. Document

- [ ] Update environment README
- [ ] Record state storage details in platform inventory
- [ ] Notify team in #platform-engineering

## Rollback

If first apply fails, see [rollback.md](rollback.md). Do not destroy until state is diagnosed.

## Estimated Time

| Phase | Duration |
|-------|----------|
| Configuration | 30 minutes |
| Bootstrap + validate | 15 minutes |
| First plan + apply | 30–60 minutes |
| Verification | 15 minutes |

## Related

- [Bootstrap Guide](../../deployment/bootstrap/README.md)
- [New Environment](../../deployment/bootstrap/README.md)
- [Backend Strategy](../terraform/backend-strategy.md)
