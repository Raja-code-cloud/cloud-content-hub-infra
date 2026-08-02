# Environment Validation

## Scope

Environment root modules under `environments/`:

| Environment | Purpose |
|-------------|---------|
| `dev` | Fully composed development stack |
| `stage` | Pre-production composition |
| `prod` | Production composition |

## Validation Commands

```bash
# Validate all environments
./tests/scripts/run-environment-tests.sh

# Single environment
./tests/scripts/run-environment-tests.sh dev

# Composition integration test
./tests/integration/environment-composition.test.sh

# Plan validation with example tfvars
./tests/scripts/run-plan-validation.sh dev
```

## Required Environment Files

| File | Purpose |
|------|---------|
| `main.tf` | Module composition |
| `locals.tf` | Derived values and module inputs |
| `variables.tf` | Environment inputs |
| `outputs.tf` | Exported values |
| `versions.tf` | Provider version constraints |
| `providers.tf` | Provider configuration (no secrets) |
| `backend.tf` | Remote state configuration |
| `terraform.tfvars.example` | Documented placeholder values |

## Composition Checks

The integration test verifies:

1. Environment directory exists with `main.tf`
2. `terraform init -backend=false` succeeds
3. `terraform validate` succeeds
4. Module blocks are present (warns if skeleton only)

## Plan Validation

Plan gates verify:

| Check | Description |
|-------|-------------|
| Plan succeeds | Exit code 0 or 2 |
| Provider init | No provider configuration errors |
| Replacement analysis | Optional forced replacement threshold |
| Example tfvars only | Uses `terraform.tfvars.example` |

Configure thresholds in `tests/config/manifest.json` under `plan_gates`.

## Environment Promotion Alignment

Release promotion (`release/scripts/quality-gates.sh`) should pass the same validate gates before plan/apply in deployment pipelines.

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Validate fails on module ref | Broken module source path | Fix `source` in environment `main.tf` |
| Plan fails on missing var | Incomplete example tfvars | Update `terraform.tfvars.example` |
| Circular dependency | Module `depends_on` loop | Refactor composition in `locals.tf` |
