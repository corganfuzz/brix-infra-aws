module "infrastructure" {
  source = "../../infrastructure"

  project_name     = local.project_name
  environment      = local.environment
  vpcs             = local.vpcs
  s3_buckets       = local.s3_buckets
  iam_roles        = local.iam_roles
  databricks_host  = local.databricks_host
  databricks_token = local.databricks_token
}
