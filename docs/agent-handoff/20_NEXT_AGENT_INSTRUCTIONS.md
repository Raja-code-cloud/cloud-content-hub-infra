# Next Agent Instructions — Cloud Content Hub Infrastructure

**Audience:** Codex, Antigravity, or any successor coding agent  
**Repository:** `cloud-content-hub-infra`  
**Document type:** Operational handoff (documentation only)  
**Source of truth:** Actual repository state on disk — not historical chat summaries  
**Handoff date basis:** 2026-08-08 (code and docs as of audit remediation 2026-08-03 plus local quality-gate WIP)

---

## Standing orders (read first)

Before changing anything:

1. **Do not redesign architecture.** The tiered environment model, module boundaries, provider inheritance, and separate state files are settled.
2. **Do not recreate completed work.** Modules, environment roots, deployment/release frameworks, and CI workflows already exist.
3. **Do not treat historical blockers as current blockers without verification.** Critical/High audit items (C1–C6, H1–H10) are marked remediated in code. Confirm against the repo and live Azure/GitHub config before acting.
4. **Use actual repository state as the source of truth.** Prefer `environments/*/main.tf`, workflows, and modules over stale README lines.
5. **Verify before modifying.** Run validate/lint/security locally or inspect CI before “fixing” something that may already be correct.
6. **Preserve existing patterns.** Provider blocks only in environment roots; modules never declare providers/backends; compose via variables/outputs.
7. **Do not create duplicate modules.** Extend or wire existing modules; do not fork parallel “v2” stacks.
8. **Do not introduce unnecessary dependencies.** No app frameworks, no extra Terraform providers unless an Azure resource gap is proven.

---

## 1. What the project is

Enterprise **Infrastructure as Code** for the **Cloud Content Hub** platform on **Microsoft Azure**.

| Fact | Detail |
|------|--------|
| Scope | **Infrastructure only** — no application code, business logic, or runtime services |
| IaC | Terraform `>= 1.13.0` |
| Cloud | Microsoft Azure (`azurerm ~> 5.0`, `azapi ~> 2.0`, `random`, `time`) |
| CI/CD | GitHub Actions with OIDC-oriented workflows |
| State | One Azure Storage state file per environment (`dev.tfstate`, `stage.tfstate`, `prod.tfstate`); **no workspaces** ([ADR-0001](../adr/adr-0001-separate-state-files-per-environment.md)) |
| Auth model | GitHub Actions OIDC + federated credentials per GitHub Environment |

This repo provisions and governs the platform plane (networking, identity, data, containers, secrets, monitoring, policy). Application repositories consume outputs and images; they are out of band.

---

## 2. Current architecture

### Principles in force

- Environment isolation: separate roots under `environments/{dev,stage,prod}/`
- Provider centralization: only `environments/*/providers.tf`
- Single-responsibility modules under `modules/`
- Shared naming/tags via `modules/common` (and `naming`)
- Tiered composition: **dev = minimal**; **stage/prod = expanded** (private networking, PE, governance, monitoring)

### Environment composition (implemented)

| Capability | dev | stage | prod |
|------------|:---:|:-----:|:----:|
| Core (RG, LA, App Insights, MI, ACR, KV, Storage, PostgreSQL, CAE, Container App) | Yes | Yes | Yes |
| PostgreSQL database | Yes | Yes | Yes |
| PostgreSQL configuration | No | Yes | Yes |
| Storage containers | No | Yes | Yes |
| Private networking / DNS / private endpoints | No | Gated | Gated |
| Governance (policy assignment, budget) | No | Gated | Gated |
| Custom policy initiative | No | No | Gated |
| Monitoring (action group, alerts, diagnostics) | No | Gated | Gated |
| Resource lock | No | Yes | Yes |
| Redis | **Not composed** | **Not composed** | **Not composed** |

Canonical overview: [`docs/architecture/README.md`](../architecture/README.md).

### Supporting frameworks

| Area | Location | Role |
|------|----------|------|
| Deploy HOW | `deployment/` | Bootstrap, plan/apply, validate, state, rollback, destroy |
| Promote HOW | `release/` | Dev→Stage→Prod checklists, scripts, audit templates |
| Tests | `tests/` | Static, security, compliance, regression, module/env suites |
| CI | `.github/workflows/` | PR gates, plan/apply/destroy/drift, release promotion |
| Policies dir | `policies/` | Scaffold only (`.gitkeep` + README); live governance uses Terraform modules |
| Standards | `docs/terraform/`, `docs/adr/`, `docs/runbooks/`, `docs/cicd/` | Conventions and operations |

### Security scanners (current enforcement)

- **Active in CI:** Checkov + Trivy (`.github/workflows/terraform-security.yml`)
- **Deprecated:** tfsec — see [`docs/terraform/DEPRECATED_TFSEC.md`](../terraform/DEPRECATED_TFSEC.md) and stub `.tfsec.yml`
- Exceptions: [`.checkov.yml`](../../.checkov.yml), [`.trivyignore`](../../.trivyignore), [`SECURITY_SCAN_EXCEPTIONS.md`](../terraform/SECURITY_SCAN_EXCEPTIONS.md)

---

## 3. What is already complete

Treat these as **done unless verification proves otherwise**:

### Modules

All active modules under `modules/` have implementations (`main.tf` present), including:

`common`, `naming`, `resource-group`, `resource-lock`, `networking`, `private-dns`, `private-endpoint`, `managed-identity`, `key-vault`, `key-vault-secrets`, `storage`, `storage-containers`, `acr`, `container-app-environment`, `container-app`, `postgresql-flexible-server`, `postgresql-database`, `postgresql-configuration`, `log-analytics`, `application-insights`, `role-assignment`, `diagnostic-settings`, `action-group`, `monitor-alerts`, `budget`, `policy-assignment`, `policy-initiative`, `policy-exemption`

**Deprecated (do not use in new compositions):** `postgres`, `monitor`, `alerts` — each has `DEPRECATED.md`. `redis` is implemented and composed for Cloud Content Hub AI.

### Environments

`environments/dev|stage|prod/` each include root module files, `backend.hcl` / examples, `terraform.tfvars.example`, lock files, and README. No committed `terraform.tfvars` (correct).

### Delivery machinery

- Deployment scripts under `deployment/scripts/` (bootstrap, plan, apply, validate, rollback, destroy)
- Release scripts under `release/scripts/` (promote, quality gates, drift, rollback, audit)
- Promotion checklists: `release/checklists/dev-to-stage.md`, `stage-to-prod.md`
- GitHub workflows for format, validate, lint, docs, security, plan, apply, destroy, drift, test framework, release, promotion, rollback, emergency
- Composite actions: `azure-terraform`, `setup-terraform`, `setup-tflint`, `run-test-suite`
- Audit remediation report: [`AUDIT_REMEDIATION.md`](../terraform/AUDIT_REMEDIATION.md) — Critical/High closed; verdict **READY WITH OPERATIONAL PREREQUISITES**
- Dev composition review: [`dev-integration-review.md`](../terraform/dev-integration-review.md)

### Quality configs present

`.checkov.yml`, `.tflint.hcl`, `.tfsec.yml` (deprecation stub), `.trivyignore`, Dependabot, CODEOWNERS.

---

## 4. What has been verified

| Evidence | Status | Notes |
|----------|--------|-------|
| `terraform validate` (dev/stage/prod) | Pass (documented 2026-08-03) | Per audit remediation |
| Module validate | Pass (local test reports) | Includes deprecated modules |
| Format / TFLint | Pass / pass with expected warnings | Module `required_providers` intentionally disabled |
| Checkov + Trivy with suppressions | Pass when configs applied | See `SECURITY_SCAN_EXCEPTIONS.md` |
| Dev integration composition review | Pass | Wiring/order/providers reviewed |
| Critical/High audit findings | Remediated in code | Do not re-open without new evidence |
| Live `terraform plan` / `apply` against Azure | **Not verified in-repo** | Needs backend bootstrap + Azure/OIDC auth |
| GitHub Environment secrets / federated creds | **Not proven by this repo alone** | Fail-fast exists in apply workflow; secrets are external |
| Full test suite green | **Partial** | Last local reports showed compliance/docs/structure failures; re-run before acting |
| Redis in environments | Verified **absent** | Architecture says not implemented; module code exists but unwired |

**Rule:** If a claim is only in conversation history, re-verify against files and commands before changing code.

---

## 5. What remains for staging

Stage **composition is already in Terraform**. Remaining work is commissioning and proof:

1. **Bootstrap remote state** — run `deployment/scripts/bootstrap/provision-state-storage.sh` (or confirm existing `rg-cch-tfstate` / `stcchtfstate` / `tfstate` container).
2. **Configure GitHub Environment `stage`** — `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `TF_STATE_*`; federated credential for `environment:stage`.
3. **Provide real stage tfvars/secrets** — subscription, passwords, contacts, networking flags; never commit secrets.
4. **First successful stage plan + apply** with private networking / PE path enabled as designed.
5. **Application prerequisites** — container image present in ACR; app→PostgreSQL connectivity (firewall/private path) validated.
6. **Complete** [`release/checklists/dev-to-stage.md`](../../release/checklists/dev-to-stage.md) — approvals, audit record, start soak (≥24h before prod).
7. **Doc drift cleanup (non-blocking but recommended)** — remove stale “tfsec required” and “apply disabled until OIDC” claims where CI already implements Checkov/Trivy + gated apply.

---

## 6. What remains for GA (production)

All staging prerequisites, plus:

1. Stage soak complete and stable; no open HIGH/CRITICAL security findings.
2. Release tag `v*.*.*` via `release.yml`; identify rollback tag.
3. Set required **`deployment_principal_id`** (OIDC SP object ID) for prod.
4. Complete [`release/checklists/stage-to-prod.md`](../../release/checklists/stage-to-prod.md) — two-person approval, FinOps/change advisory as required.
5. Promote **only** via `release-promotion.yml` (`promotion_target=prod`, tagged ref). Direct `terraform-apply.yml` to prod is blocked by design.
6. Post-apply: outputs, health checks, monitoring review, audit record, release notes.
7. Accepted commissioning items still open for GA hardening (not blockers to first apply if checklists accept them): ACR Defender/content trust/geo-replication, storage CMK, queue logging — see §9 and `SECURITY_SCAN_EXCEPTIONS.md`.
8. Deferred maturity (v1.1+): Terratest, Infracost, naming catalog gaps, tag enforcement — not GA blockers unless product mandates them.

---

## 7. Current blockers

### Treat as current only after re-verification

| Blocker | Why it is current | How to clear |
|---------|-------------------|--------------|
| Remote state not proven live | Plan/apply need bootstrapped Azure Storage backend | Run/confirm `provision-state-storage.sh`; init with `backend.hcl` |
| GitHub OIDC secrets not proven configured | Apply fail-fast requires `AZURE_*` / `TF_STATE_*` | Configure per-environment secrets + federated credentials |
| No evidenced successful stage apply | GA path requires stage validation + soak | Complete stage apply and checklist |
| Local test compliance/docs gates (last report) | May fail PR/release validate | Re-run `tests/scripts/run-all.sh`; fix only confirmed failures |

### Do **not** treat as current without new evidence

- Historical Critical/High audit findings (C1–C6, H1–H10) — remediated 2026-08-03
- “Apply/destroy disabled until OIDC” as absolute truth — workflows and `azure-terraform` action exist; they are **secret-gated**, not absent
- “tfsec missing from CI” as a defect — tfsec is **intentionally deprecated**

---

## 8. Accepted risks

Documented and intentional for v1.0 commissioning (do not “fix” without product/security sign-off):

- ACR Defender, content trust, retention, geo-replication, zone redundancy deferred to commissioning (`SECURITY_SCAN_EXCEPTIONS.md`)
- Storage queue logging (CKV_AZURE_33) not required for blob-only workload
- CMK deferred to post-commissioning hardening
- Dev-relaxed controls: purge protection flexibility, LRS, public access patterns for engineer productivity
- PostgreSQL administrator password present in Terraform state — mitigated by runbook [`docs/runbooks/postgresql-credentials.md`](../runbooks/postgresql-credentials.md)
- Duplicate Checkov/Trivy coverage accepted as defense-in-depth for v1.0 (M9)
- Windows test runner unused in CI (L7 accepted)

---

## 9. Known technical debt

| Item | Status | Guidance |
|------|--------|----------|
| Duplicate `id` / `resource_id` outputs (M1) | Deferred v2.0 | Do not break interfaces in v1 |
| Module `public_network_access_enabled` defaults true (M4) | Deferred; stage/prod override | Keep env overrides |
| Naming catalog / tag enforcement gaps (M5/M6) | Deferred v1.1 | Extend `naming`/`common` later |
| `policy-exemption` unwired | Deferred optional | Wire only if exemption required |
| `resource-lock` standalone unused | Embedded in `resource-group` by design | Do not duplicate |
| Unused `azapi` provider | Reserved | Do not remove casually; do not add resources without need |
| Deprecated modules retained | Until v2.0 | Do not compose; do not delete without migration plan |
| `modules/redis` | Implemented and wired into dev/stage/prod for `CCH_REDIS_URL` | Keep SKU/private-endpoint alignment |
| `policies/` directory empty | Scaffold | Prefer Terraform policy modules unless PaC files are required |
| Doc drift (README apply/OIDC; cicd/release still mention tfsec) | Open | Safe parallel cleanup |
| Root README module table incomplete vs disk | Open | Doc-only sync |
| Inconsistent `_schema_test.tf` (L1) | Deferred | Low priority |
| No Terratest / Infracost | Deferred v1.1 | Optional spikes only |

---

## 10. Infrastructure gaps

- Redis caching layer not in any environment composition
- `policies/` Policy-as-Code file tree not populated (governance via modules instead)
- Dev intentionally omits VNet/PE/governance/monitoring — do not “fix” by copying prod into dev without a decision
- PostgreSQL private connectivity / firewall path for workloads needs operational validation at apply time
- Live Azure resources not evidenced from this repository alone

---

## 11. Security gaps

- Stage/prod hardening depends on feature flags + real tfvars, not module defaults alone — verify at plan time
- Many Checkov skips are classified false-positive or accepted risk; do not blanket-remove suppressions
- OIDC/backend configuration is an external control plane gap until proven in GitHub + Azure
- Prod App Insights connection string must stay in Key Vault pattern (do not re-export sensitive connection string)
- Secret material must never be committed (`terraform.tfvars`, passwords, client secrets)

---

## 12. Operational gaps

- Bootstrap and promotion paths are **code-complete**; execution and GitHub Environment approvals may still be unset
- Soak, audit records, and two-person prod approval are process gates, not Terraform modules
- Drift workflow exists; prod drift is configured to fail — ensure it is scheduled/enabled in GitHub
- Some docs still claim bootstrap/apply are “planned” or “disabled” while scripts/workflows exist — trust scripts + workflows after verification
- Workstation helpers: `scripts/workstation-check.sh` / `.ps1` (may be local WIP — verify before relying)

---

## 13. Product integration gaps

- This repo does not own application code
- Container Apps use configurable/placeholder image references — real tags must come from the app pipeline into ACR
- Key Vault secrets are provisioned; full app secret surface (beyond patterns like App Insights in prod) may still be incomplete relative to the application’s needs
- Redis is composed; ensure ACR images for API/worker are published before apply
- Consumers must honor breaking output migrations documented in `AUDIT_REMEDIATION.md` (`managed_identity.id`, `log_analytics.id`, `key_vault_secrets` URI vs ID)

---

## 14. Tasks that can run in parallel

Safe concurrent tracks (no architecture redesign):

1. **Doc sync** — align README / `docs/cicd` / `release` with Checkov+Trivy and OIDC-gated apply; reconcile Redis narrative
2. **Test framework hygiene** — re-run suite; fix confirmed compliance/docs/structure failures only
3. **Exception hygiene** — review Checkov/Trivy suppressions with security; do not silently drop accepted risks
4. **Examples / workstation-check polish** — local DX only
5. **v1.1 spikes** — Terratest, Infracost (non-blocking)
6. **PaC under `policies/`** — only if governance requires file-based definitions in addition to Terraform modules

---

## 15. Tasks that must wait (sequential)

Ordered critical path:

1. Confirm or create **state storage** in target subscription(s)
2. Configure **GitHub Environments + OIDC** secrets/federated credentials
3. Successful **dev** apply (optional but lowest blast radius) or proceed carefully to stage if policy allows
4. Successful **stage** apply with private networking validated
5. App image + DB connectivity smoke on stage
6. Soak + complete **dev→stage** checklist artifacts
7. Tag release + complete **stage→prod** checklist
8. **Prod promotion** via `release-promotion.yml` only

Do not attempt prod apply before stage soak and two-person approval.

---

## 16. What the next agent should NOT touch

Without an explicit human redesign request:

- ADR-0001 (separate state files / no workspaces)
- Provider-only-at-environment-root rule
- Modules declaring providers, backends, or `required_providers`
- Tiered env model (forcing full prod stack into dev)
- Linear promotion model / prod apply guard
- Reintroducing **tfsec** as a required gate
- Composing deprecated modules (`postgres`, `monitor`, `alerts`) into environments
- Creating parallel duplicate modules for already-covered Azure services
- “Fixing” accepted risks and deferred Medium/Low audit items as if they were blockers
- Rewriting completed active module interfaces without a migration guide and consumer update
- Adding application code, Node/Python services, or unrelated package managers to this repo
- Committing secrets, real passwords, or production tfvars
- Force-pushing, rewriting git history, or skipping hooks

---

## 17. What should be done first

Priority order for the next agent:

1. **Orient from disk** — read `README.md`, `docs/architecture/README.md`, `docs/terraform/AUDIT_REMEDIATION.md`, this file.
2. **Verify operational prerequisites** — GitHub Environment secrets present? State storage exist? (Ask humans / use `gh` + Azure CLI; do not invent credentials.)
3. **Re-run local quality gates** — `terraform fmt`, validate per env (`init -backend=false` if needed), tflint, checkov, trivy; optionally `tests/scripts/run-all.sh`.
4. **Unblock stage commissioning** — bootstrap → OIDC → stage plan → stage apply → checklist.
5. **Only then** pursue GA promotion path.
6. Parallelize doc/test cleanup only when it does not delay commissioning.

---

## IMMEDIATE NEXT OBJECTIVE

**Commission stage:** prove remote state + OIDC, produce a reviewed stage plan, apply stage with the designed private networking path, and complete `release/checklists/dev-to-stage.md` through soak start.

If Azure/GitHub access is unavailable in the agent environment, restrict work to verified doc/test hygiene and leave apply steps for a human with credentials — do not invent bootstrap resources in code that already exist.

---

## DEPENDENCIES

| Dependency | Owner / location | Required for |
|------------|------------------|--------------|
| Azure subscription(s) + permissions | Platform / cloud ops | Bootstrap, plan, apply |
| State RG/account/container | `provision-state-storage.sh` / existing `backend.hcl` names | Remote state |
| GitHub Environments `dev` / `stage` / `prod` | Repo settings | OIDC apply/promote |
| Federated credentials on Azure AD app | Identity team | OIDC login |
| Secrets: `AZURE_*`, `TF_STATE_*` | GitHub Environment secrets | Plan/apply/drift |
| `deployment_principal_id` (prod) | Prod tfvars / CI vars | Prod apply |
| Container images in ACR | Application CI | Meaningful Container App deploy |
| DB credentials / Key Vault ops | Secrets process + runbooks | PostgreSQL + app runtime |
| Human approvals (stage 1, prod 2) | Release process | Promotion workflows |
| Bash-capable shell (Git Bash/WSL on Windows) | Developer workstation | `deployment/` and `release/` scripts |

---

## DO NOT TOUCH

- Settled architecture (ADR-0001, provider inheritance, tiered envs, promotion model)
- Completed active modules’ public interfaces without explicit migration work
- Deprecated modules (except documenting or eventual v2 removal plan)
- Re-adding tfsec
- Secrets and real backend credentials in git
- Application repositories / business logic
- Unnecessary new modules or providers
- Accepted-risk suppressions without security sign-off

---

## VERIFICATION REQUIRED

Before claiming done on any infra change:

1. `terraform fmt -recursive -check`
2. `terraform init -backend=false && terraform validate` in each touched environment
3. `tflint --recursive` (expect designed module warnings)
4. `checkov` with `.checkov.yml` and `trivy config` with `.trivyignore`
5. Confirm no providers/backends added inside modules
6. Confirm deprecated modules not newly composed
7. For apply claims: evidence of successful workflow run or local apply log — not documentation alone
8. For “blocker cleared”: show the verifying command/output or GitHub/Azure config fact

Re-verify historical audit items only if new failures appear; do not re-implement their remediations preemptively.

---

## GA EXIT CRITERIA

GA / v1.0 production readiness is met when **all** of the following are true:

1. Remote state bootstrapped and used for **stage** and **prod**
2. GitHub OIDC configured for **stage** and **prod**; apply/promote workflows succeed with secrets present
3. Stage apply succeeded with private networking / PE path as designed
4. Stage soak ≥24 hours with no active incident blocking release
5. `release/checklists/dev-to-stage.md` and `stage-to-prod.md` completed and signed
6. Release tag `v*.*.*` published; `release.yml` succeeded
7. Prod promotion via `release-promotion.yml` succeeded (not direct apply)
8. Two-person approval recorded; rollback tag identified
9. Prod outputs verified; health checks and monitoring review completed; audit record uploaded
10. No open HIGH/CRITICAL security findings (accepted risks remain documented, not silent)
11. `deployment_principal_id` set for prod; no secrets in git
12. Repository quality gates required for the release path are green on the tagged commit

**Audit posture:** code scored **READY WITH OPERATIONAL PREREQUISITES** (87/100). GA is an **operational and promotion** finish line, not a greenfield rebuild.

---

## Quick reference paths

| Need | Path |
|------|------|
| Architecture | `docs/architecture/README.md` |
| Audit / remediation | `docs/terraform/AUDIT_REMEDIATION.md` |
| Security exceptions | `docs/terraform/SECURITY_SCAN_EXCEPTIONS.md` |
| tfsec deprecation | `docs/terraform/DEPRECATED_TFSEC.md` |
| Dev composition review | `docs/terraform/dev-integration-review.md` |
| CI/CD | `docs/cicd/README.md` |
| Deploy scripts | `deployment/README.md` |
| Release / promotion | `release/README.md` |
| Stage checklist | `release/checklists/dev-to-stage.md` |
| Prod checklist | `release/checklists/stage-to-prod.md` |
| PG credentials | `docs/runbooks/postgresql-credentials.md` |

---

*End of next-agent instructions. Prefer repository evidence over narrative. Commission stage before GA. Do not redesign.*
