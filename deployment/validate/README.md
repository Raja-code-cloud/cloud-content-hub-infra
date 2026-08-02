# Validation

Quality and security validation gates for infrastructure deployment.

All validation must pass before plan or apply. The validation pipeline mirrors GitHub Actions PR checks.

## Validation Pipeline

```
terraform fmt ──▶ terraform validate ──▶ tflint ──▶ checkov ──▶ tfsec ──▶ trivy
     │                    │                  │           │          │         │
   format              syntax            lint       policy      security   IaC scan
```

## Tools

| Tool | Purpose | Config | CI Workflow |
|------|---------|--------|-------------|
| `terraform fmt` | Format consistency | — | `terraform-format.yml` |
| `terraform validate` | Syntax and provider schema | `versions.tf` | `terraform-validate.yml` |
| `terraform plan` | Change preview | `terraform.tfvars` | `terraform-plan.yml` |
| TFLint | Static analysis, best practices | `.tflint.hcl` | `terraform-lint.yml` |
| Checkov | Policy-as-code (Azure) | `.checkov.yml` | `terraform-security.yml` |
| tfsec | Security misconfiguration | `.tfsec.yml` | `terraform-security.yml` |
| Trivy | IaC vulnerability scan | `.trivyignore` | `terraform-security.yml` |
| terraform-docs | Module documentation | `.terraform-docs.yml` | `terraform-docs.yml` |

## Required Versions

| Tool | Version | Source |
|------|---------|--------|
| Terraform | `1.13.0` | Workflow `env.TF_VERSION` |
| TFLint | `v0.50.3` | Workflow `env.TFLINT_VERSION` |
| terraform-docs | `v0.19.0` | Workflow `env.TERRAFORM_DOCS_VERSION` |
| Checkov | Latest (pinned action) | `bridgecrewio/checkov-action@v12` |
| tfsec | Latest (pinned action) | `aquasecurity/tfsec-action@v1.0.3` |
| Trivy | `0.28.0` | `aquasecurity/trivy-action@0.28.0` |

## Run All Validations

```bash
# Full test framework (recommended)
./tests/scripts/run-all.sh

# Full regression with plan validation
./tests/scripts/run-all.sh --suite regression --with-plan --env dev

# Legacy deployment entry point (delegates to tests framework)
./deployment/scripts/validate/run-all.sh dev
```

See [tests/README.md](../../tests/README.md) for the complete testing framework.

## Individual Commands

### terraform fmt

```bash
terraform fmt -recursive -check -diff
# Fix: terraform fmt -recursive
```

**Gate:** Zero diff required. CI fails on formatting drift.

### terraform validate

```bash
cd environments/dev
terraform init -backend=false -input=false
terraform validate
```

**Gate:** Must report `Success! The configuration is valid.`

Also validates all modules via CI matrix in `terraform-validate.yml`.

### terraform plan

```bash
./deployment/scripts/deploy/plan.sh dev
```

**Gate:** Plan must complete without errors. Review `plan.txt` for unexpected changes.

**Note:** Requires backend initialization in Terraform 1.13+.

### TFLint

```bash
tflint --init
tflint --recursive --format compact
```

**Gate:** No errors. Warnings in modules (missing `required_version`) are expected by design.

Config: `.tflint.hcl` with azurerm ruleset.

### Checkov

```bash
checkov -d . --framework terraform --config-file .checkov.yml
```

**Gate:** CI fails on HIGH and CRITICAL findings.

Dev environment may have accepted findings for cost-optimized settings (no private endpoints, purge protection disabled). Document exceptions in `.checkov.yml` or module README.

### tfsec

```bash
tfsec . --minimum-severity HIGH
```

**Gate:** CI fails on HIGH and CRITICAL.

Config: `.tfsec.yml`.

### Trivy

```bash
trivy config . --severity HIGH,CRITICAL --exit-code 1
```

**Gate:** CI fails on HIGH and CRITICAL.

Ignore list: `.trivyignore`.

### terraform-docs

```bash
terraform-docs markdown table --config .terraform-docs.yml modules/<module>
git diff --exit-code modules/<module>/README.md
```

**Gate:** Generated docs must match committed README.

## Validation by Phase

| Phase | Required Gates |
|-------|----------------|
| Pull request | fmt, validate, lint, docs, security, plan |
| Pre-apply | validate |
| Release tag | validate, security, plan (all environments) |
| Local dev | fmt, validate (minimum) |

## Environment-Specific Expectations

| Environment | Security Strictness | Notes |
|-------------|--------------------|----|
| dev | Standard CI gates | Cost-optimized module defaults may trigger Checkov |
| stage | Standard CI gates | Must pass before prod promotion |
| prod | Standard CI gates | No exceptions without ADR |

## Failure Response

| Failure | Action |
|---------|--------|
| fmt | Run `terraform fmt -recursive`, commit |
| validate | Fix syntax/provider issues in environment or module |
| tflint | Fix lint errors; document accepted warnings |
| checkov/tfsec/trivy | Fix or document exception with ADR |
| plan | Investigate unexpected resource changes |

## Related

- [Terraform Test Framework](../../tests/README.md)
- [Validation Script](../scripts/validate/run-all.sh)
- [CI/CD Architecture](../../docs/cicd/README.md)
- [Terraform Standards](../../docs/terraform/standards.md)
