# ------------------------------------------------------------------------------
# Naming Module — Locals
# ------------------------------------------------------------------------------

locals {
  allowed_regions = {
    eastus             = "eus"
    eastus2            = "eus2"
    centralus          = "cus"
    westus2            = "wus2"
    westus3            = "wus3"
    northeurope        = "neu"
    westeurope         = "weu"
    uksouth            = "uks"
    ukwest             = "ukw"
    swedencentral      = "swc"
    francecentral      = "frc"
    germanywestcentral = "gwc"
    australiaeast      = "aue"
    southeastasia      = "sea"
    japaneast          = "jpe"
    brazilsouth        = "brs"
  }

  environment_abbreviations = {
    dev   = "dev"
    stage = "stg"
    prod  = "prd"
  }

  resource_catalog = {
    acr = {
      slug              = "acr"
      max_length        = 50
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
    cae = {
      slug              = "cae"
      max_length        = 60
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
    api = {
      slug              = "api"
      max_length        = 32
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
    worker = {
      slug              = "worker"
      max_length        = 32
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
    beat = {
      slug              = "beat"
      max_length        = 32
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
    migrate = {
      slug              = "migrate"
      max_length        = 32
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
    storage = {
      slug              = "storage"
      max_length        = 24
      delimiter         = ""
      include_location  = true
      alphanumeric_only = true
    }
    postgres = {
      slug              = "postgres"
      max_length        = 63
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
    redis = {
      slug              = "redis"
      max_length        = 63
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
    key_vault = {
      slug              = "kv"
      max_length        = 24
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
    vnet = {
      slug              = "vnet"
      max_length        = 64
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
    subnet = {
      slug              = "snet"
      max_length        = 80
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
    identity = {
      slug              = "id"
      max_length        = 128
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
    log_analytics = {
      slug              = "log"
      max_length        = 63
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
    app_insights = {
      slug              = "appi"
      max_length        = 260
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
    monitor = {
      slug              = "mon"
      max_length        = 260
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
    alerts = {
      slug              = "alert"
      max_length        = 260
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
    budget = {
      slug              = "budget"
      max_length        = 63
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
    resource_group = {
      slug              = "rg"
      max_length        = 90
      delimiter         = "-"
      include_location  = false
      alphanumeric_only = false
    }
  }

  location_short        = coalesce(var.location_short, local.allowed_regions[var.location])
  environment_short     = local.environment_abbreviations[var.environment]
  resource_prefix       = "${var.project_name}-${var.environment}"
  resource_prefix_short = "${var.project_name}${local.environment_short}"

  standard_labels = {
    project     = var.project_name
    application = var.application_name
    environment = var.environment
    location    = var.location
  }

  naming_requests = merge(
    var.resources,
    var.resource_type == null ? {} : {
      default = {
        resource_type    = var.resource_type
        instance         = var.instance
        include_location = var.include_location
      }
    }
  )

  raw_names = {
    for key, cfg in local.naming_requests : key => join(
      local.resource_catalog[cfg.resource_type].delimiter,
      compact([
        local.resource_catalog[cfg.resource_type].alphanumeric_only ? local.resource_prefix_short : local.resource_prefix,
        coalesce(cfg.include_location, local.resource_catalog[cfg.resource_type].include_location) ? local.location_short : null,
        local.resource_catalog[cfg.resource_type].slug,
        cfg.instance != "" ? cfg.instance : null,
      ])
    )
  }

  names = {
    for key, cfg in local.naming_requests : key => substr(
      local.resource_catalog[cfg.resource_type].alphanumeric_only ? regexreplace(lower(local.raw_names[key]), "[^a-z0-9]", "") : lower(local.raw_names[key]),
      0,
      local.resource_catalog[cfg.resource_type].max_length
    )
  }
}
