# ------------------------------------------------------------------------------
# Provider Configuration — dev
#
# Providers are configured exclusively at the environment root level.
# Child modules inherit these providers automatically.
#
# Authentication is NOT configured here. CI/CD authenticates via
# GitHub Actions OpenID Connect (OIDC). See .github/actions/azure-terraform.
#
# See: docs/terraform/provider-inheritance.md
# ------------------------------------------------------------------------------

provider "azurerm" {
  subscription_id = var.subscription_id

  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }

    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }

    log_analytics_workspace {
      permanently_delete_on_destroy = false
    }

    cognitive_account {
      purge_soft_delete_on_destroy = false
    }
  }
}

provider "azapi" {}

provider "random" {}

provider "time" {}
