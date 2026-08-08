# Scripts

Operational and bootstrap scripts for Cloud Content Hub infrastructure.

## Workstation Readiness

Verify Git configuration and required tooling before running quality gates:

```bash
# Linux / macOS / Git Bash
./scripts/workstation-check.sh
```

```powershell
# Windows PowerShell
.\scripts\workstation-check.ps1
```

### Required tools

| Tool | Purpose |
|------|---------|
| Terraform `>= 1.13.0` | Format, validate, plan |
| terraform-docs | README documentation drift check |
| TFLint | Terraform linting |
| Checkov | IaC security policy (replaces deprecated tfsec) |
| Trivy | IaC misconfiguration scan |
| jq | JSON processing in test scripts |
| Git + Git LFS | Version control |
| Python 3 | Checkov runtime |
| bash | Test framework entry points (Git Bash on Windows) |

### Optional

| Tool | Purpose |
|------|---------|
| Azure CLI | Subscription context for plan/apply workflows |

See [DEPRECATED_TFSEC.md](../docs/terraform/DEPRECATED_TFSEC.md) for tfsec migration notes.

## Guidelines

- Use **bash** (not POSIX `sh`) for cross-platform scripts; test framework requires bash features.
- Include a header comment describing purpose, usage, and prerequisites.
- Never embed secrets; accept credentials via environment variables or Azure CLI context.
- Shell scripts use LF line endings (enforced via `.gitattributes`).

## Planned Scripts

| Script | Description | Status |
|--------|-------------|--------|
| `workstation-check.sh` / `.ps1` | Verify tooling and Git config | Available |
| _TBD_ | Bootstrap Terraform remote state storage | Planned |
| _TBD_ | Validate Azure subscription prerequisites | Planned |
| _TBD_ | Generate terraform.tfvars from template | Planned |
