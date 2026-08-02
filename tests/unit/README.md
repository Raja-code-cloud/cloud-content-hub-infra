# Unit Tests

Unit tests validate individual modules and fixture-based compositions without touching production module source.

## Included Tests

| Test | Script | Purpose |
|------|--------|---------|
| Module validation | `../scripts/run-module-tests.sh` | `terraform validate` for every module |
| Fixture validation | `module-validation.test.sh` | Validate fixture roots under `tests/fixtures/examples/` |

## Run

```bash
./tests/unit/module-validation.test.sh
./tests/scripts/run-module-tests.sh
./tests/scripts/run-module-tests.sh role-assignment
```

## Adding Module Tests

1. Add or update a fixture under `tests/fixtures/examples/<module>/`
2. Ensure the fixture uses deterministic placeholder values
3. Run `terraform validate` locally
4. Optionally add module-specific assertions in a new `tests/unit/<module>.test.sh`

Do not modify files under `modules/` when adding tests.
