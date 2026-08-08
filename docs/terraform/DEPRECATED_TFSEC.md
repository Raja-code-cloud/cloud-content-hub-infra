# tfsec Deprecation Notice

**Status:** Deprecated as of 2026-08-03  
**Replacement:** [Checkov](https://www.checkov.io/) with `.checkov.yml`

## Summary

This repository previously used **tfsec** alongside Checkov for Terraform security scanning. tfsec has been merged into Trivy and is no longer maintained as a standalone tool for this platform.

All security policy enforcement now flows through:

| Scanner | Config | Severity gate |
|---------|--------|---------------|
| **Checkov** | `.checkov.yml` | HIGH, CRITICAL |
| **Trivy** | `.trivyignore` | HIGH, CRITICAL |

## Migration

| Former tfsec usage | Current replacement |
|--------------------|---------------------|
| `.tfsec.yml` exclusions | `.checkov.yml` `skip-check` entries with ADR references |
| `tests/scripts/run-security-tests.sh` tfsec gate | Checkov gate only |
| CI `tfsec` job in `terraform-security.yml` | Removed; Checkov + Trivy remain |
| `minimum_severity: HIGH` in `.tfsec.yml` | `hard_fail_on: HIGH,CRITICAL` in Checkov CI action |

## `.tfsec.yml`

The file is retained for historical reference only. **Do not install or run tfsec.** Any exclusions previously intended for tfsec must be added to `.checkov.yml` with documented justification.

## Compliance mapping

- **CAF-SEC-001** validation key updated from `tfsec_trivy_pass` to `checkov_trivy_pass` in `tests/config/compliance-rules.json`.
- **WAF-SEC-002** (least privilege) is validated by Checkov + Trivy passing at HIGH/CRITICAL severity.
