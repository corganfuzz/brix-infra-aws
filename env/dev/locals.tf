locals {
  project_name = "mortgage-xpert"
  environment  = "dev"

  vpcs = {
    "main" = {
      cidr_block = "10.0.0.0/16"
      subnets = {
        "public-1a"  = { cidr_block = "10.0.1.0/24", availability_zone = "us-east-1a", public = true }
        "private-1a" = { cidr_block = "10.0.11.0/24", availability_zone = "us-east-1a", public = false }
      }
    }
  }

  s3_buckets = {
    "raw"       = { versioning = true }
    "bronze"    = { versioning = true }
    "silver"    = { versioning = true }
    "gold"      = { versioning = true }
    "kb-source" = { versioning = true }
  }

  aws_region = "us-east-1"

  iam_roles = {
    "bedrock-agent" = { trust_service = "bedrock.amazonaws.com" }
    "bedrock-kb"    = { trust_service = "bedrock.amazonaws.com" }
    "databricks"    = { trust_service = "self" }
  }

  databricks_host  = "https://adb-xxx.cloud.databricks.com"
  databricks_token = "pattoken..."
}
