# Security Scan Exceptions

Documented suppressions for Checkov and Trivy findings. Each entry is classified per platform commissioning review.

**Last reviewed:** 2026-08-03  
**Architecture reference:** `docs/terraform/provider-inheritance.md`, `environments/stage/locals.tf`

## Classification Key

| Class | Meaning |
|-------|---------|
| **False positive** | Scanner evaluates module in isolation; environment composition satisfies control |
| **Development exception** | Intentionally relaxed in `dev` for engineer productivity |
| **Accepted risk** | Known gap tracked for post-commissioning hardening |

---

## Checkov Exceptions (`.checkov.yml`)

### ACR module — False positive / Development exception

| Check | Class | Justification |
|-------|-------|---------------|
| CKV_AZURE_139 | False positive | Private networking enforced via `module.private_endpoint` when `enable_private_endpoints=true` (stage/prod). Module is single-responsibility. |
| CKV_AZURE_163, 164, 166, 167 | Accepted risk | ACR Defender/content trust/retention configured during platform commissioning per subscription policy. |
| CKV_AZURE_165, 233, 237 | Accepted risk | Geo-replication and zone redundancy are prod-only decisions; not enforced at module skeleton. |

### Key Vault module — False positive

| Check | Class | Justification |
|-------|-------|---------------|
| CKV_AZURE_189, CKV_AZURE_109 | False positive | `public_network_access_enabled` and firewall rules set per environment. Stage/prod set `false` with private endpoints. |
| CKV_AZURE_110, CKV_AZURE_42 | Development exception | `purge_protection_enabled` variable defaults allow dev flexibility; prod tfvars enforce protection. |
| CKV2_AZURE_32 | False positive | Private endpoint created by `modules/private-endpoint` in stage/prod roots. |

### Storage module — False positive / Development exception

| Check | Class | Justification |
|-------|-------|---------------|
| CKV_AZURE_35, 36, 59 | False positive | `network_rules` block populated when `var.network_rules` set; stage/prod disable public access. |
| CKV_AZURE_33 | Accepted risk | Queue logging not required for current blob-only workload. |
| CKV_AZURE_206 | Development exception | Dev uses LRS; stage/prod tfvars specify GRS/ZRS. |
| CKV2_AZURE_33, 38, 40, 41 | False positive / Accepted risk | Private endpoints and CMK are environment-level concerns configured in stage/prod promotion. |

### PostgreSQL module — False positive

| Check | Class | Justification |
|-------|-------|---------------|
| CKV_AZURE_136 | Development exception | Geo-redundant backup enabled in prod tfvars; dev uses local redundancy. |
| CKV2_AZURE_57 | False positive | Private endpoint via `module.private_endpoint` when networking enabled. |

---

## Trivy Exceptions (`.trivyignore`)

| ID | Class | Justification |
|----|-------|---------------|
| AVD-AZU-0012 | False positive | Storage `network_rules` optional block; stage/prod pass `default_action=Deny` via variables. Dev omits rules for local testing. |
| AVD-AZU-0013 | False positive | Key Vault network ACL enforced by private endpoint module in stage/prod; base module exposes `public_network_access_enabled` variable. |

---

## Reproduction

```bash
checkov -d . --framework terraform --config-file .checkov.yml
trivy config . --severity HIGH,CRITICAL --ignorefile .trivyignore
```

Both commands should exit 0 with suppressions applied.
