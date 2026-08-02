# Terraform Testing Framework

Repository-wide testing architecture for **cloud-content-hub-infra**.

## Purpose

Validate infrastructure quality automatically across:

| Category | Suites |
|----------|--------|
| Static analysis | fmt, tflint, terraform-docs |
| Validation | Module and environment `terraform validate` |
| Security | Checkov, tfsec, Trivy, secret scan |
| Compliance | Repository standards, Azure WAF/CAF mapping |
| Integration | Environment composition |
| Regression | Combined quality gates |
| Plan validation | Plan success, replacement analysis |

## Directory Structure

```
tests/
├── config/           # Central manifest and compliance rules
├── docs/             # Testing strategy and guides
├── fixtures/         # Module fixture roots (do not modify modules/)
├── integration/      # Environment composition tests
├── reports/          # Generated reports (gitignored)
├── scripts/          # Orchestration and gate scripts
└── unit/             # Module and fixture unit tests
```

## Quick Start

```bash
# Full suite (no plan)
./tests/scripts/run-all.sh

# Full suite with plan validation
./tests/scripts/run-all.sh --with-plan

# Individual suites
./tests/scripts/run-all.sh --suite static
./tests/scripts/run-all.sh --suite modules
./tests/scripts/run-all.sh --suite environments
./tests/scripts/run-all.sh --suite security
./tests/scripts/run-all.sh --suite compliance
./tests/scripts/run-all.sh --suite plan --env dev
./tests/scripts/run-all.sh --suite regression --with-plan
```

## CI Integration

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `terraform-test-framework.yml` | PR, main, release, manual | Unified test orchestrator |
| `terraform-pr.yml` | Pull requests | PR gate (calls existing + framework) |
| `terraform-validate.yml` | Push/workflow_call | Dynamic module/environment matrix |

Reports are uploaded as GitHub Actions artifacts from `tests/reports/`.

## Documentation

| Document | Description |
|----------|-------------|
| [Testing Strategy](docs/testing-strategy.md) | Overall approach and quality gates |
| [Execution Flow](docs/execution-flow.md) | How suites run locally and in CI |
| [Adding New Tests](docs/adding-new-tests.md) | Extend coverage for new modules |
| [Module Validation](docs/module-validation.md) | Module testing guidance |
| [Environment Validation](docs/environment-validation.md) | Environment testing guidance |
| [Compliance Mapping](docs/compliance-mapping.md) | WAF, CAF, and repo standards |
| [Troubleshooting](docs/troubleshooting.md) | Common failures and fixes |

## Design Principles

1. **Do not modify modules for testing** — use fixtures and validation-only checks
2. **Single manifest** — `tests/config/manifest.json` for tool versions and gates
3. **Auto-discovery** — modules and environments discovered from filesystem
4. **Reusable scripts** — same commands locally and in CI
5. **Actionable reports** — markdown summaries and JSONL result logs

## Related

- [Deployment validation](../deployment/validate/README.md)
- [Terraform standards](../docs/terraform/standards.md)
- [Release quality gates](../release/scripts/quality-gates.sh)
