# Scripts

Operational and bootstrap scripts for Cloud Content Hub infrastructure.

## Guidelines

- Use POSIX-compatible shell (`bash`) unless Windows-specific functionality is required.
- Include a header comment describing purpose, usage, and prerequisites.
- Never embed secrets; accept credentials via environment variables or Azure CLI context.
- Add scripts here as operational procedures are defined.

## Planned Scripts

| Script | Description | Status |
|--------|-------------|--------|
| _TBD_ | Bootstrap Terraform remote state storage | Planned |
| _TBD_ | Validate Azure subscription prerequisites | Planned |
| _TBD_ | Generate terraform.tfvars from template | Planned |
