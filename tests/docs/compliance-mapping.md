# Compliance Mapping

Maps test framework gates to enterprise and Azure governance standards.

## Repository Standards

Source: `tests/config/compliance-rules.json`, `docs/terraform/standards.md`

| Gate | Standard | Validation |
|------|----------|------------|
| Module structure | Required files per module | `run-compliance-tests.sh` |
| Environment structure | Required files per environment | `run-compliance-tests.sh` |
| Provider inheritance | No `providers.tf` in modules | Compliance check |
| Forbidden files | No committed `terraform.tfvars` | Git ls-files scan |
| Naming module | Centralized naming | `modules/naming` exists |

## Terraform Best Practices

| ID | Practice | Test Coverage |
|----|----------|---------------|
| TP-001 | Explicit variable types | tflint `terraform_typed_variables` |
| TP-002 | Output descriptions | tflint `terraform_documented_outputs` |
| TP-003 | Provider inheritance | Compliance module check |
| TP-004 | Format consistency | `terraform fmt -check` |
| TP-005 | Documentation currency | terraform-docs diff check |

## Azure Well-Architected Framework

| ID | Pillar | Topic | Test |
|----|--------|-------|------|
| WAF-SEC-001 | Security | Secrets management | Secret pattern scan |
| WAF-SEC-002 | Security | Secure configuration | Checkov, tfsec, Trivy |
| WAF-REL-001 | Reliability | Valid infrastructure | terraform validate (modules + envs) |
| WAF-OPS-001 | Operational Excellence | Documentation | terraform-docs |
| WAF-GOV-001 | Governance | Policy as code | Checkov + policy modules (assign separately) |

## Azure Cloud Adoption Framework

| ID | Domain | Topic | Test |
|----|--------|-------|------|
| CAF-GOV-001 | Governance | Policy as code | Checkov |
| CAF-GOV-002 | Governance | Resource organization | Naming module compliance |
| CAF-SEC-001 | Security | Secure configuration | tfsec + Trivy |
| CAF-OPS-001 | Operations | Automated validation | CI test framework |

## Policy Compliance

Governance modules (`policy-assignment`, `policy-initiative`, `policy-exemption`) are validated as standard modules. Assignment compliance is evaluated in Azure Policy at runtime, not by this framework.

## Exception Process

1. Document finding and business justification
2. Add ADR under `docs/adr/`
3. Add scoped skip to `.checkov.yml`, `.tfsec.yml`, or `.trivyignore`
4. Reference ADR in skip comment

## Report Artifacts

| Report | Path |
|--------|------|
| Compliance summary | `tests/reports/compliance-summary.md` |
| Security summary | `tests/reports/security-summary.md` |
| Module health | `tests/reports/module-health-summary.md` |
| Framework summary | `tests/reports/test-framework-summary.md` |
