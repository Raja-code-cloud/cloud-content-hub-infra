# Contributing to cloud-content-hub-infra

Thank you for contributing to the Cloud Content Hub infrastructure repository.

## Scope

This repository contains **Infrastructure as Code only**:

- Terraform modules and environment configurations
- Azure governance policies
- CI/CD pipelines
- Operational scripts and documentation

Do **not** submit application code, business logic, or runtime dependencies (Python, FastAPI, frontend, etc.).

## Branching Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready infrastructure state |
| `develop` | Integration branch for staged changes |
| `feature/*` | New modules, environment updates, docs |
| `fix/*` | Bug fixes and corrections |
| `chore/*` | Tooling, CI, and non-functional updates |

## Development Workflow

1. Create a feature branch from `develop` (or `main` for hotfixes).
2. Make changes following [Terraform Standards](docs/terraform/standards.md).
3. Run the local validation pipeline:

   ```bash
   terraform fmt -recursive -check -diff
   tflint --init && tflint --recursive
   cd environments/dev && terraform init -backend=false && terraform validate
   terraform-docs markdown table --config .terraform-docs.yml modules/<module-name>
   checkov -d environments/ -d modules/
   ```

   See [CI/CD Architecture](docs/cicd/README.md) for the full pipeline.

4. Open a pull request with a clear description and linked work item.
5. Ensure all CI checks pass and obtain required approvals.
6. Merge using squash merge unless otherwise specified.

## Terraform Conventions

Full standards: **[docs/terraform/standards.md](docs/terraform/standards.md)**

### Environment Root Modules

Each environment (`environments/dev`, `stage`, `prod`) is an independent root module:

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform `>= 1.13.0` and provider version constraints |
| `backend.tf` | Remote state backend (azurerm, placeholder values) |
| `providers.tf` | Provider configuration (azurerm, azapi, random, time) |
| `variables.tf` | Input variables |
| `locals.tf` | Derived values and merged tags |
| `main.tf` | Module composition |
| `outputs.tf` | Output values |

### Module Rules

Every module must include:

```
modules/<name>/
├── main.tf
├── variables.tf
├── outputs.tf
├── locals.tf
├── versions.tf      # comment-only — no provider configuration
└── README.md
```

Modules must **never** declare:

- `provider "..." {}` blocks
- `required_providers` blocks
- `terraform { backend ... }` blocks

See [Provider Inheritance](docs/terraform/provider-inheritance.md).

### Variables

Every variable requires `description`, `type`, and `nullable`. Use `validation` for enums and constraints. No hardcoded environment values.

### Outputs

Every output requires `description`. Mark secrets with `sensitive = true`. Never expose credentials in plain outputs.

### Locals

Use locals for naming, derived values, reusable expressions, and merged tags only.

## Environment Changes

- Never hardcode secrets; use Azure Key Vault references or GitHub Secrets.
- Environment values belong in `terraform.tfvars` (gitignored) or CI-injected variables.
- Production changes require additional reviewer approval.

## Documentation

- Update module `README.md` when inputs, outputs, or behavior change.
- Add ADRs in `docs/adr/` for significant architectural decisions.
- Update runbooks in `docs/runbooks/` for operational procedures.

## Pull Request Checklist

- [ ] `terraform fmt -recursive` applied
- [ ] `terraform validate` passes for affected environments
- [ ] TFLint passes with no new warnings
- [ ] Module README updated (if applicable)
- [ ] No secrets, credentials, or real backend values committed
- [ ] No provider blocks added to modules
- [ ] Changes scoped to infrastructure only
- [ ] CI pipeline passes ([CI/CD docs](docs/cicd/README.md))

## Code Review

Reviewers should verify:

- **Provider inheritance** — no provider configuration in modules
- **Security** — no public exposure of sensitive resources by default
- **Idempotency** — changes are safe to re-apply
- **Modularity** — logic belongs in modules, not duplicated across environments
- **Cost** — resource SKUs and scaling settings are appropriate for the target environment
- **Standards compliance** — variables, outputs, and locals follow documented conventions

## Questions

Open a discussion or contact the Platform Engineering team for guidance on module design, environment strategy, or Azure governance.
