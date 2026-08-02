# Terraform Test Fixtures

Fixtures provide isolated, module-scoped test roots that reference production modules without modifying them.

## Layout

```
fixtures/
├── README.md
└── examples/
    └── role-assignment/
        ├── main.tf
        ├── variables.tf
        ├── versions.tf
        └── terraform.tfvars.json
```

## Usage

```bash
cd tests/fixtures/examples/role-assignment
terraform init -backend=false
terraform validate
terraform plan -var-file=terraform.tfvars.json
```

## Adding a Fixture

1. Create `tests/fixtures/examples/<module-name>/`
2. Add a minimal root module that calls `../../../../modules/<module-name>`
3. Provide deterministic test input values (no real secrets)
4. Wire the fixture into `tests/unit/module-validation.test.sh` if needed

Fixtures must never modify modules under `modules/`.
