# Testing Strategy

## Objectives

The testing framework ensures every change to **cloud-content-hub-infra** meets enterprise quality, security, and governance standards before promotion across environments.

## Test Layers

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 5: Plan Validation                                    │
│ terraform plan, replacement analysis, provider checks       │
├─────────────────────────────────────────────────────────────┤
│ Layer 4: Integration                                        │
│ Environment composition (dev, stage, prod)                  │
├─────────────────────────────────────────────────────────────┤
│ Layer 3: Compliance                                         │
│ Repository structure, WAF/CAF mapping, forbidden files      │
├─────────────────────────────────────────────────────────────┤
│ Layer 2: Security                                           │
│ Checkov, tfsec, Trivy, secrets, sensitive outputs           │
├─────────────────────────────────────────────────────────────┤
│ Layer 1: Static Analysis                                    │
│ fmt, tflint, terraform-docs, terraform validate             │
└─────────────────────────────────────────────────────────────┘
```

## Quality Gates by Event

| Event | Required Gates |
|-------|----------------|
| Pull request | static, modules, environments, security, compliance, plan |
| Main branch push | static, modules, environments, security, compliance |
| Release branch | full regression + plan (all environments) |
| Manual dispatch | configurable suite via workflow input |

## Module Testing Strategy

- Every module under `modules/` must pass standalone `terraform validate`
- Modules use `_schema_test.tf` for provider pinning during validation
- Fixture-based examples under `tests/fixtures/examples/` validate composition patterns
- New modules are auto-discovered — no manual CI matrix edits required

## Environment Testing Strategy

- Each environment root (`dev`, `stage`, `prod`) must pass `terraform validate`
- Composition tests verify module wiring without Azure credentials
- Plan tests use `terraform.tfvars.example` only — never committed secrets

## Security Strategy

- No secrets in source (pattern scan + review)
- Sensitive outputs must declare `sensitive = true`
- IaC scanners enforce HIGH/CRITICAL severity in CI
- Documented exceptions require ADR references in scanner config files

## Regression Strategy

The regression suite runs all non-plan gates by default. Enable plan validation with `--with-plan` for release readiness checks.

## Reporting

All suites write JSONL results to `tests/reports/*-results.jsonl` and markdown summaries consumed by CI artifacts and the module health summary.

## Future Extensions

- Terratest or native Terraform test framework (`terraform test`) for module behavior tests
- Policy compliance integration with `modules/policy-assignment`
- Drift detection correlation with `release/scripts/detect-drift.sh`
- Baseline plan comparison for unexpected resource changes
