module "role_assignment" {
  source = "../../../../modules/role-assignment"

  assignments = var.assignments
}
