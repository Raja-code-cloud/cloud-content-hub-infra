# Integration Tests

Integration tests validate that environment root modules compose reusable modules successfully.

## Scope

| Test | Script | Validates |
|------|--------|-------------|
| Environment composition | `environment-composition.test.sh` | `dev`, `stage`, `prod` init + validate |
| Plan validation | `../scripts/run-plan-validation.sh` | Plan succeeds with example tfvars |
| Regression | `../scripts/run-regression-tests.sh` | Full repository quality gates |

## Run

```bash
./tests/integration/environment-composition.test.sh
./tests/scripts/run-environment-tests.sh
./tests/scripts/run-plan-validation.sh dev
```

Integration tests use `terraform init -backend=false` and do not require Azure credentials for validate-only checks.

Plan validation requires provider initialization and example variable files only.
