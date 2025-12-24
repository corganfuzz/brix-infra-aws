module "infrastructure" {
  source = "../../infrastructure"

  project_name = local.project_name
  environment  = local.environment
  vpcs         = local.vpcs
}
