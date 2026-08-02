# Module Validation

## Automatic Validation

Every directory under `modules/` containing `main.tf` is validated:

```bash
./tests/scripts/run-module-tests.sh
./tests/scripts/run-module-tests.sh policy-initiative
```

Each module runs:

```bash
terraform init -backend=false -input=false
terraform validate
```

## Expected Module Structure

| File | Required | Notes |
|------|:--------:|-------|
| `main.tf` | yes | Primary resources |
| `variables.tf` | yes | Typed inputs with descriptions |
| `outputs.tf` | yes | Documented outputs |
| `versions.tf` | yes | Provider inheritance comment |
| `README.md` | yes | Purpose, examples, terraform-docs markers |
| `_schema_test.tf` | recommended | Provider pin for standalone validate |
| `providers.tf` | **no** | Violates provider inheritance standard |

## Fixture-Based Testing

Fixtures wrap modules with test inputs without changing module source:

```
tests/fixtures/examples/<module>/
  main.tf          → module "test" { source = "../../../../modules/<module>" }
  terraform.tfvars.json
```

Run fixture tests:

```bash
./tests/unit/module-validation.test.sh
```

## Static Analysis Coverage

| Tool | Module Scope |
|------|--------------|
| tflint | All `.tf` files recursively |
| Checkov | `modules/` included in repo scan |
| terraform-docs | Each module README must match generated docs |

## Module Health Summary

After test runs, review:

```
tests/reports/module-health-summary.md
```

This report lists validate status and documentation presence per module.

## Troubleshooting Module Validate Failures

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Provider not found | Missing `_schema_test.tf` | Add provider pin file |
| Invalid variable type | Schema mismatch | Fix `variables.tf` types |
| Unknown resource attribute | Provider version drift | Align with environment `~> 5.0` |
