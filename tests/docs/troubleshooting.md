# Troubleshooting

## Common Failures

### terraform fmt

**Symptom:** `terraform fmt -check` reports diff

**Fix:**

```bash
terraform fmt -recursive
git add -u && git commit -m "chore: apply terraform fmt"
```

### terraform validate (module)

**Symptom:** `Error: Missing required provider`

**Fix:** Add `_schema_test.tf` with `required_providers` block (see `modules/container-app/_schema_test.tf`).

### terraform validate (environment)

**Symptom:** Module source not found

**Fix:** Verify relative `source` paths in environment `main.tf` point to `../../modules/<name>`.

### tflint

**Symptom:** `terraform_required_version` warning in `_schema_test.tf`

**Fix:** Include `required_version = ">= 1.13.0"` in `_schema_test.tf`.

### terraform-docs

**Symptom:** README diff after generation

**Fix:**

```bash
terraform-docs markdown table --config .terraform-docs.yml modules/<module>
```

### Checkov / tfsec / Trivy

**Symptom:** HIGH/CRITICAL finding

**Fix:**

1. Remediate configuration if valid finding
2. If accepted risk, document ADR and add scoped skip to scanner config

### Secret scan

**Symptom:** `Potential secret pattern in file`

**Fix:**

- Remove hardcoded credentials
- Use environment variables or GitHub Actions secrets
- Ensure examples use placeholders only in `*.example` files

### Plan validation

**Symptom:** Plan exit code 1

**Fix:**

- Review `tests/reports/plan-<env>.log`
- Update `terraform.tfvars.example` with missing variables
- Fix provider/module configuration errors

**Symptom:** Forced replacements detected

**Fix:** Review `tests/reports/plan-analysis-<env>.md`. Adjust `plan_gates` in manifest or fix unintended resource attribute changes.

### Compliance structure check

**Symptom:** Missing required file in module/environment

**Fix:** Add missing file per `tests/config/compliance-rules.json`.

## Local Tool Installation

| Tool | Install |
|------|---------|
| Terraform 1.13.0 | `hashicorp/setup-terraform` or choco |
| tflint | https://github.com/terraform-linters/tflint |
| terraform-docs | https://terraform-docs.io |
| checkov | `pip install checkov` |
| tfsec | https://github.com/aquasecurity/tfsec |
| trivy | https://aquasecurity.github.io/trivy |
| jq | System package manager |

## CI Debugging

1. Download workflow artifacts from the Actions run
2. Review `tests/reports/test-framework-summary.md`
3. Check individual `*-summary.md` suite reports
4. Reproduce locally with the same suite command from `tests/README.md`

## Getting Help

- [Testing strategy](testing-strategy.md)
- [Terraform standards](../../docs/terraform/standards.md)
- [Deployment validation](../../deployment/validate/README.md)
