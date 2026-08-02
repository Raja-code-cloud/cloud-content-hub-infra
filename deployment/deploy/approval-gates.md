# Approval Gates

Approval gate configuration for infrastructure deployments.

## Gate Model

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Automated   │────▶│   Human      │────▶│   Apply      │
│  CI Gates    │     │   Approval   │     │   Execution  │
└──────────────┘     └──────────────┘     └──────────────┘
  fmt/validate/         GitHub Env           terraform apply
  lint/security         reviewers
  plan artifact
```

## Automated Gates (CI)

All must pass before human approval:

| Gate | Tool | Failure Action |
|------|------|----------------|
| Format | `terraform fmt -check` | Block merge / block apply |
| Validate | `terraform validate` | Block merge / block apply |
| Lint | TFLint | Block merge / block apply |
| Documentation | terraform-docs | Block merge |
| Security | Checkov, tfsec, Trivy | Block merge (HIGH/CRITICAL) |
| Plan | `terraform plan` | Block apply if plan changed |

Orchestrated by `terraform-pr.yml` on pull requests.

## Human Approval Gates

Configured in **GitHub → Settings → Environments**:

| Environment | Required Reviewers | Wait Timer | Deployment Branches |
|-------------|-------------------|------------|---------------------|
| `dev` | 0 (optional) | None | `develop`, `main` |
| `stage` | 1+ | Optional 5 min | `main`, `release/*` |
| `prod` | 2+ | Recommended 15 min | `main` only |

### Environment secrets (per environment)

| Secret / Variable | Purpose |
|-------------------|---------|
| `AZURE_CLIENT_ID` | OIDC federated app registration |
| `AZURE_TENANT_ID` | Azure AD tenant |
| `AZURE_SUBSCRIPTION_ID` | Target subscription |
| `TF_STATE_RESOURCE_GROUP` | Backend storage RG |
| `TF_STATE_STORAGE_ACCOUNT` | Backend storage account |
| `TF_VAR_postgresql_admin_password` | Database password |
| `TF_VAR_api_key_placeholder` | Application secret placeholder |
| `TF_VAR_deployment_principal_id` | OIDC SP object ID |

## Confirmation Inputs

Workflows require typed confirmation to prevent mis-clicks:

| Workflow | Input | Required Value |
|----------|-------|----------------|
| Apply | `confirmation` | Environment name (`dev`, `stage`, `prod`) |
| Destroy | `confirmation` | `destroy-<environment>` |

Local scripts mirror this via `confirm_phrase` in `common.sh`.

## Apply Authorization Matrix

| Actor | dev | stage | prod |
|-------|-----|-------|------|
| Developer | Plan + Apply | Plan only | Plan only |
| Release engineer | Plan + Apply | Plan + Apply | Plan + Apply (with approval) |
| Platform admin | Full | Full | Full |
| CI service principal | Apply (OIDC) | Apply (OIDC) | Apply (OIDC) |

## Gate Bypass Policy

Gate bypass is **never** permitted for production.

Break-glass procedures for stage/dev require:

1. Change ticket with justification
2. Platform admin approval
3. Post-incident review within 24 hours

## Related

- [CI/CD Architecture](../../docs/cicd/README.md)
- [Deploy Runbook](../../docs/runbooks/deploy.md)
