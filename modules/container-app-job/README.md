# Container App Job Module

Creates a manual-trigger Azure Container Apps Job. Used by Cloud Content Hub AI for Alembic database migrations (`alembic upgrade head`).

## Usage

```hcl
module "container_app_job_migrate" {
  source = "../../modules/container-app-job"

  job_name                     = module.common.resource_names["migrate"]
  resource_group_name          = module.resource_group.name
  location                     = module.common.location
  container_app_environment_id = module.container_app_environment.id
  tags                         = module.common.tags

  identity = {
    type         = "UserAssigned"
    identity_ids = [module.managed_identity.resource_id]
  }

  registries = [{
    server   = module.acr.login_server
    identity = module.managed_identity.resource_id
  }]

  containers = [{
    name    = "migrate"
    image   = local.api_container_image
    cpu     = 0.5
    memory  = "1.0Gi"
    command = ["alembic"]
    args    = ["upgrade", "head"]
  }]
}
```

## Notes

- Trigger type is always manual (start via Azure CLI / portal / deployment scripts).
- Secret values are ignored in lifecycle to support Key Vault references without drift.
