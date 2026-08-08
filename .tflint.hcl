tflint {
  required_version = ">= 0.50.0"
}

config {
  call_module_type    = "local"
  force               = false
  disabled_by_default = false
}

plugin "terraform" {
  enabled = true
  preset  = "none"
}

plugin "azurerm" {
  enabled = true
  version = "0.30.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

# Provider inheritance: modules do not declare required_version/required_providers.
# See docs/terraform/provider-inheritance.md
rule "terraform_required_version" {
  enabled = false
}

rule "terraform_required_providers" {
  enabled = false
}
