# Execution Flow

## Local Execution

```mermaid
flowchart TD
  A[run-all.sh] --> B{Suite}
  B -->|static| C[run-static-analysis.sh]
  B -->|modules| D[run-module-tests.sh]
  B -->|environments| E[run-environment-tests.sh]
  B -->|security| F[run-security-tests.sh]
  B -->|compliance| G[run-compliance-tests.sh]
  B -->|plan| H[run-plan-validation.sh]
  B -->|regression| I[run-regression-tests.sh]
  C --> J[generate-report.sh]
  D --> J
  E --> J
  F --> J
  G --> J
  H --> J
  I --> J
  J --> K[tests/reports/]
```

## CI Execution

```mermaid
flowchart LR
  PR[Pull Request] --> TF[terraform-test-framework.yml]
  MAIN[Main Push] --> TF
  REL[Release Branch] --> TF
  MAN[Manual Dispatch] --> TF
  TF --> DISC[Discover modules/environments]
  DISC --> STATIC[Static Analysis]
  DISC --> MOD[Module Matrix]
  DISC --> ENV[Environment Matrix]
  STATIC --> SEC[Security]
  MOD --> COMP[Compliance]
  ENV --> COMP
  SEC --> PLAN[Plan Validation]
  COMP --> REPORT[Generate Reports]
  PLAN --> REPORT
  REPORT --> ART[Upload Artifacts]
```

## Suite Dependencies

| Suite | Depends On | Produces |
|-------|------------|----------|
| Static | terraform, tflint, terraform-docs | `static-summary.md` |
| Modules | terraform | `modules-summary.md` |
| Environments | terraform | `environments-summary.md` |
| Security | checkov, tfsec, trivy (optional locally) | `security-summary.md`, scanner JSON |
| Compliance | jq, git | `compliance-summary.md` |
| Plan | terraform, jq | `plan-analysis-*.md` |
| Regression | all above | `regression-summary.md` |

## Discover Scripts

Used by CI for dynamic matrices:

```bash
./tests/scripts/discover-modules.sh --json
./tests/scripts/discover-environments.sh --github
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All gates passed |
| 1 | One or more gates failed |

Terraform plan exit code `2` (changes present) is treated as success for plan validation gates.
