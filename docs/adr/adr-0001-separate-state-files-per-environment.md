# ADR-0001: Separate State Files Per Environment

- **Status:** Accepted
- **Date:** 2026-08-02
- **Deciders:** Platform Engineering

## Context

The Cloud Content Hub infrastructure repository manages three environments: `dev`, `stage`, and `prod`. We need a remote state strategy that supports enterprise security, CI/CD automation, and operational safety.

Terraform offers two common multi-environment patterns:

1. **Separate directories with separate state files** (one root module per environment)
2. **Terraform workspaces** (one root module, multiple workspace-scoped state instances)

## Decision

We will use **separate environment directories** (`environments/dev`, `environments/stage`, `environments/prod`) each with its own **azurerm backend key**:

- `dev.tfstate`
- `stage.tfstate`
- `prod.tfstate`

We will **not** use Terraform workspaces.

## Consequences

### Positive

- **Blast radius isolation** — state corruption or accidental destroy in one environment cannot affect others.
- **Independent RBAC** — Azure Storage blob-level permissions can restrict prod state access to platform admins.
- **Unambiguous CI/CD** — each pipeline targets an explicit directory; no workspace selection step.
- **Subscription alignment** — environments can target different Azure subscriptions without workspace switching.
- **Clear audit trail** — state blob names appear directly in storage logs and backup policies.

### Negative

- Some configuration is duplicated across environment directories (mitigated by shared modules).
- Three backend configurations must be maintained (mitigated by identical structure and templates).

## Alternatives Considered

### Terraform Workspaces

Rejected because:

- All workspaces share a backend configuration, making per-environment RBAC harder.
- `terraform workspace select` introduces human error risk in manual operations.
- Workspace names are not visible in Azure Storage blob paths by default.
- CI/CD must inject workspace selection, adding an implicit step.

### Separate Repositories Per Environment

Rejected because:

- Module sharing requires cross-repo dependencies or duplication.
- Standards enforcement across repos is harder.
- A monorepo with environment directories provides the same isolation with simpler module reuse.

## Related

- [Backend Strategy](../terraform/backend-strategy.md)
- [Terraform Foundation](../terraform/README.md)
