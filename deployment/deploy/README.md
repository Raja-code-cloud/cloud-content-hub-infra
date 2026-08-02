# Deploy

Infrastructure deployment procedures for all environments.

Deployment follows a strict **validate → plan → review → apply** sequence. No apply may proceed without a successful plan and the appropriate approval gate.

## Deployment Flow

```
Validate ──▶ Plan ──▶ Review ──▶ Approval Gate ──▶ Apply ──▶ Verify
   │           │          │              │            │          │
   │           │          │              │            │          └── outputs check
   │           │          │              │            └── state updated
   │           │          │              └── GitHub Environment
   │           │          └── plan artifact archived
   │           └── tfplan binary saved
   └── fmt/validate/lint/security
```

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/deploy/plan.sh` | Generate and save plan artifact |
| `scripts/deploy/apply.sh` | Apply saved plan with confirmation |

## Environment Procedures

| Environment | Document | Approval | Auto-approve |
|-------------|----------|----------|--------------|
| Development | [dev.md](dev.md) | Optional | Allowed after plan review |
| Staging | [stage.md](stage.md) | 1+ reviewer | Never |
| Production | [prod.md](prod.md) | 2+ reviewers | Never |

See [approval-gates.md](approval-gates.md) for gate configuration.

## Standard Deployment

### Local (operator workstation)

```bash
# 1. Validate
./deployment/scripts/validate/run-all.sh dev

# 2. Plan
./deployment/scripts/deploy/plan.sh dev

# 3. Review plan output in environments/dev/plan.txt

# 4. Apply
./deployment/scripts/deploy/apply.sh dev
```

### GitHub Actions

| Action | Workflow |
|--------|----------|
| Plan | Actions → **Terraform Plan** → select environment |
| Apply | Actions → **Terraform Apply** → confirm environment name |

Apply workflow requires typing the environment name as confirmation and passes through the GitHub Environment approval gate.

## Plan Requirements

Every plan must:

1. Run against the correct environment directory
2. Use the environment-specific `terraform.tfvars`
3. Use initialized remote backend
4. Produce a saved plan file (`tfplan`)
5. Archive plan output as text for audit

```bash
./deployment/scripts/deploy/plan.sh dev
# Creates: environments/dev/tfplan
#           environments/dev/plan.txt
```

## Apply Requirements

Every apply must:

1. Use a plan generated from the **same commit** and **same variables**
2. Pass pre-apply validation
3. Satisfy the environment approval gate
4. Never use `-auto-approve` without a saved plan in production

```bash
./deployment/scripts/deploy/apply.sh dev
# Applies: environments/dev/tfplan
```

## Post-Deploy Verification

After apply, verify:

```bash
cd environments/dev
terraform output
```

| Check | Command / Output |
|-------|------------------|
| State consistent | `terraform state list` |
| Outputs present | `terraform output` |
| Container App URL | `terraform output container_app_url` |
| Key Vault accessible | `terraform output key_vault_uri` |
| No drift | `./deployment/scripts/validate/run-all.sh dev` (optional plan-only) |

## Secrets and Variables

| Variable | Supply Method |
|----------|---------------|
| `subscription_id` | `terraform.tfvars` or GitHub Environment variable |
| `postgresql_admin_password` | `TF_VAR_postgresql_admin_password` (GitHub secret) |
| `api_key_placeholder` | `TF_VAR_api_key_placeholder` (GitHub secret) |
| `deployment_principal_id` | GitHub Environment variable (OIDC SP object ID) |

Never commit `terraform.tfvars` with real secrets.

## CI/CD Parity Matrix

| Step | Local Script | GitHub Workflow | Artifact |
|------|--------------|-----------------|----------|
| Format | `validate/run-all.sh` | `terraform-format.yml` | — |
| Validate | `bootstrap/validate-providers.sh` | `terraform-validate.yml` | validate log |
| Lint | `validate/run-all.sh` | `terraform-lint.yml` | tflint report |
| Security | `validate/run-all.sh` | `terraform-security.yml` | SARIF |
| Plan | `deploy/plan.sh` | `terraform-plan.yml` | `tfplan-<env>-<run_id>` |
| Apply | `deploy/apply.sh` | `terraform-apply.yml` | apply log |

## Related

- [Approval Gates](approval-gates.md)
- [Development Deployment](dev.md)
- [Staging Deployment](stage.md)
- [Production Deployment](prod.md)
- [Deploy Runbook](../../docs/runbooks/deploy.md)
