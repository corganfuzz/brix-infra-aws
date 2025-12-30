resource "databricks_storage_credential" "this" {
  name = "${var.project_name}-${var.environment}-credential"
  aws_iam_role {
    role_arn = var.databricks_role_arn
  }
  comment = "Credential for Mortgage Xpert S3 access via Unity Catalog"
}

resource "databricks_external_location" "buckets" {
  for_each        = var.s3_buckets
  name            = "${var.project_name}-${var.environment}-${each.key}-location"
  url             = "s3://${each.value}"
  credential_name = databricks_storage_credential.this.name
  comment         = "External location for ${each.key} bucket"
}

resource "databricks_catalog" "mortgage" {
  name         = "mortgage_xpert"
  storage_root = databricks_external_location.buckets["gold"].url
  comment      = "Main catalog for Mortgage Xpert platform"
  properties = {
    purpose = "mlops"
  }
  depends_on = [databricks_external_location.buckets]
}

resource "databricks_schema" "layers" {
  for_each     = toset(["bronze", "silver", "gold"])
  catalog_name = databricks_catalog.mortgage.name
  name         = each.value
  comment      = "Data layer: ${each.value}"
}

# Serverless SQL Warehouse - Modern compute for data/AI
resource "databricks_sql_endpoint" "this" {
  name                      = "${var.project_name}-${var.environment}-warehouse"
  cluster_size              = "2X-Small"
  max_num_clusters          = 1
  auto_stop_mins            = 10
  enable_serverless_compute = true
}
