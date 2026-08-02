# CI/CD Architecture

Enterprise GitHub Actions CI/CD foundation for **cloud-content-hub-infra**.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Pull Request (terraform-pr.yml)                  │
├──────────┬──────────┬───────────┬───────────┬───────────┬──────────────┤
│  Format  │   Lint   │ Validate  │   Docs    │ Security  │     Plan     │
│          │          │           │           │ (3 scans) │ (dev/stage/  │
│          │          │           │           │           │    prod)     │
└──────────┴──────────┴───────────┴───────────┴───────────┴──────────────┘
                                    │
                                    ▼
                            PR Gate (must pass)

┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  Manual Apply    │    │  Manual Destroy  │    │  Tag Release     │
│ (workflow_disp.) │    │ (workflow_disp.) │    │  (v*.*.*)        │
│  + approval gate │    │  prod blocked    │    │  validate+plan   │
└──────────────────┘    └──────────────────┘    └──────────────────┘
```

## Workflows

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| Pull Request | `terraform-pr.yml` | PR → `main`, `develop` | Orchestrates all PR checks |
| Format | `terraform-format.yml` | Push, `workflow_dispatch`, `workflow_call` | `terraform fmt -check` |
| Validate | `terraform-validate.yml` | Push, `workflow_dispatch`, `workflow_call` | `init` + `validate` all environments and modules |
| Lint | `terraform-lint.yml` | Push, `workflow_dispatch`, `workflow_call` | TFLint static analysis |
| Documentation | `terraform-docs.yml` | Push, `workflow_dispatch`, `workflow_call` | Verify module README docs |
| Security | `terraform-security.yml` | Push, `workflow_dispatch`, `workflow_call` | Checkov, tfsec, Trivy |
| Plan | `terraform-plan.yml` | `workflow_dispatch`, `workflow_call` | Generate and upload plan artifacts |
| Apply | `terraform-apply.yml` | Manual only | Apply with approval gate (disabled until OIDC) |
| Destroy | `terraform-destroy.yml` | Manual only | Destroy non-prod (disabled until OIDC) |
| Release | `release.yml` | Tag `v*.*.*` | Validate, scan, plan, publish release |

## Execution Order

### Pull Request

1. **Format** and **Lint** run in parallel
2. **Validate**, **Docs**, and **Security** run after format passes
3. **Plan** runs after validate, lint, docs, and security pass
4. **PR Gate** evaluates all job results — any failure blocks merge

### Manual Apply

1. Operator confirms environment name via workflow input
2. **Pre-apply validation** runs via reusable validate workflow
3. GitHub Environment approval gate (when configured)
4. Plan artifact downloaded (optional) or fresh plan generated
5. Apply step executes *(disabled until OIDC is configured)*

### Manual Destroy

1. Production is blocked at workflow guard
2. Operator must type `destroy-<environment>` to confirm
3. Pre-destroy validation runs
4. GitHub Environment approval gate (when configured)
5. Destroy step executes *(disabled until OIDC is configured)*

### Release

1. Tag push triggers validate + security in parallel
2. Plan all environments after validation passes
3. Generate release notes and publish GitHub Release
4. Archive plan artifacts with release

## Reusable Components

### Composite Actions

| Action | Path | Purpose |
|--------|------|---------|
| Setup Terraform | `.github/actions/setup-terraform` | Install Terraform with plugin cache |
| Setup TFLint | `.github/actions/setup-tflint` | Install TFLint with plugin cache |

### Reusable Workflows

All workflow files support `workflow_call` and are invoked by:

- `terraform-pr.yml` — full PR pipeline
- `terraform-apply.yml` — pre-apply validation
- `terraform-destroy.yml` — pre-destroy validation
- `release.yml` — release validation pipeline

## Caching

| Cache | Path | Key |
|-------|------|-----|
| Terraform plugins | `~/.terraform.d/plugin-cache` | Terraform version + hash of `versions.tf` / lock files |
| Environment providers | `environments/<env>/.terraform` | Environment path + hash of version files |
| TFLint plugins | `~/.tflint.d` | Hash of `.tflint.hcl` |

Environment variable `TF_PLUGIN_CACHE_DIR` is set for provider deduplication across runs.

## Artifacts

| Artifact | Source Workflow | Retention |
|----------|-----------------|-----------|
| `tfplan-<env>-<run_id>` | Plan | 30 days |
| `checkov-report` | Security | 30 days |
| `tfsec-report` | Security | 30 days |
| `trivy-report` | Security | 30 days |
| `security-summary` | Security | 30 days |
| `validate-log-<env>` | Validate | 14 days |
| `tflint-report` | Lint | 14 days |
| `terraform-docs-<module>` | Docs | 14 days |
| `pr-validation-summary-<run_id>` | PR | 14 days |
| `release-<tag>` | Release | 90 days |

SARIF reports are uploaded to GitHub Code Scanning where permissions allow.

## Branch Strategy

| Branch | Purpose | Protection |
|--------|---------|------------|
| `main` | Production-ready infrastructure | Protected — require PR + CI |
| `develop` | Integration branch | Protected — require PR + CI |
| `feature/*` | Feature development | PR into `develop` |
| `release/*` | Release preparation | PR into `main` |
| `hotfix/*` | Emergency fixes | PR into `main` |

### Recommended Branch Protection (GitHub Settings)

- Require pull request before merging
- Require status check: **Pull Request Gate** (`terraform-pr.yml`)
- Require conversation resolution
- Restrict pushes to `main` and `develop`

## GitHub Environments

Configure these environments in **Settings → Environments**:

| GitHub Environment | Terraform Directory | Approval | Apply | Destroy | Plan |
|--------------------|--------------------|----------|-------|---------|------|
| `dev` | `environments/dev` | Optional | Yes | Yes | Yes |
| `stage` | `environments/stage` | Required (1+ reviewers) | Yes | Yes | Yes |
| `prod` | `environments/prod` | Required (2+ reviewers) | Yes | **Blocked** | Yes |

Environment names in workflows match directory names (`dev`, `stage`, `prod`).

## OIDC Preparation

Workflows include OIDC-compatible permissions but **do not configure Azure authentication yet**.

```yaml
permissions:
  id-token: write   # Required for GitHub OIDC token
  contents: read
```

### Future Secrets (Placeholders)

Configure these when OIDC is implemented:

| Secret / Variable | Purpose |
|-------------------|---------|
| `AZURE_CLIENT_ID` | App registration client ID for federated credentials |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription per environment |
| `TF_STATE_RESOURCE_GROUP` | Backend storage resource group |
| `TF_STATE_STORAGE_ACCOUNT` | Backend storage account name |
| `TF_STATE_CONTAINER` | State container name (default: `tfstate`) |

### Future OIDC Apply Step

```yaml
- name: Azure Login (OIDC)
  uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

- name: Terraform Apply
  run: terraform apply -input=false -auto-approve tfplan
```

Apply and destroy steps are currently disabled with placeholder notices.

## Required Tool Versions

| Tool | Version | Configured In |
|------|---------|---------------|
| Terraform | `1.13.0` | Workflow `env.TF_VERSION` |
| TFLint | `v0.50.3` | Workflow `env.TFLINT_VERSION` |
| terraform-docs | `v0.19.0` | Workflow `env.TERRAFORM_DOCS_VERSION` |
| Checkov | Latest (action pin) | `bridgecrewio/checkov-action@v12` |
| tfsec | Latest (action pin) | `aquasecurity/tfsec-action@v1.0.3` |
| Trivy | `0.28.0` (action pin) | `aquasecurity/trivy-action@0.28.0` |

## Security Policy

Security workflows fail on **HIGH** and **CRITICAL** findings:

| Scanner | Config | SARIF |
|---------|--------|-------|
| Checkov | `.checkov.yml` | Yes |
| tfsec | `.tfsec.yml` | Yes |
| Trivy | `.trivyignore` | Yes |

## Manual Workflow Usage

### Plan a single environment

```
Actions → Terraform Plan → Run workflow → Select environment
```

### Apply to an environment

```
Actions → Terraform Apply → Run workflow
  - environment: dev
  - confirmation: dev
  - use_plan_artifact: <optional run ID>
```

### Destroy a non-production environment

```
Actions → Terraform Destroy → Run workflow
  - environment: dev
  - confirmation: destroy-dev
```

## Related Documentation

- [Deployment Framework](../../deployment/README.md) — bootstrap, deploy, rollback, destroy, validate
- [Terraform Standards](../terraform/standards.md)
- [Backend Strategy](../terraform/backend-strategy.md)
- [Provider Inheritance](../terraform/provider-inheritance.md)
- [CONTRIBUTING.md](../../CONTRIBUTING.md)
