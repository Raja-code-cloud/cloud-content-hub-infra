# Adding New Tests

## New Module Checklist

When adding a module under `modules/<name>/`:

1. Ensure required files exist (see `tests/config/compliance-rules.json`)
2. Add `_schema_test.tf` with provider pin for standalone validation
3. Run `./tests/scripts/run-module-tests.sh <name>`
4. Optionally add a fixture under `tests/fixtures/examples/<name>/`
5. Update module README via `terraform-docs`

Modules are auto-discovered — CI matrices update automatically via discover scripts.

## New Fixture

```bash
mkdir -p tests/fixtures/examples/my-module
```

Create:

| File | Purpose |
|------|---------|
| `main.tf` | Calls `../../../../modules/my-module` |
| `variables.tf` | Typed inputs for the fixture |
| `versions.tf` | Provider pin |
| `terraform.tfvars.json` | Deterministic test values |

Validate:

```bash
cd tests/fixtures/examples/my-module
terraform init -backend=false
terraform validate
```

## New Environment

1. Scaffold from `templates/environment-root-module.tf.template`
2. Add required files listed in compliance rules
3. Provide `terraform.tfvars.example`
4. Run `./tests/scripts/run-environment-tests.sh <env>`

## New Compliance Rule

1. Add rule to `tests/config/compliance-rules.json`
2. Implement check in `tests/scripts/run-compliance-tests.sh`
3. Document mapping in `tests/docs/compliance-mapping.md`

## New Security Pattern

Add regex patterns to `tests/config/secret-patterns.txt` with a comment describing the threat.

## New CI Gate

1. Add script under `tests/scripts/`
2. Wire into `run-all.sh` and `run-regression-tests.sh`
3. Add job to `.github/workflows/terraform-test-framework.yml`
4. Document in `tests/docs/testing-strategy.md`

## Do Not

- Modify production modules solely to satisfy tests
- Commit real secrets or `terraform.tfvars`
- Disable scanners without ADR justification
