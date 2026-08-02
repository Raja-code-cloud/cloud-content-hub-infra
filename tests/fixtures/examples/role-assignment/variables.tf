variable "assignments" {
  description = "Role assignments under test."
  type = list(object({
    key                  = string
    principal_id         = string
    principal_type       = optional(string)
    scope                = string
    role_definition_name = optional(string)
    role_definition_id   = optional(string)
    description          = optional(string)
  }))
  nullable = false
}
