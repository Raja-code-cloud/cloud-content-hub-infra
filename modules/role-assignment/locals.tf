# ------------------------------------------------------------------------------
# Role Assignment Module - Locals
# ------------------------------------------------------------------------------

locals {
  assignments = {
    for assignment in var.assignments : assignment.key => assignment
  }
}
