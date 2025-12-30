locals {
  # ==============================================
  # Project Settings
  # ==============================================
  project_name = "mortgage-xpert"
  environment  = "staging"
  aws_region   = "us-east-1"

  # ==============================================
  # Networking Configuration
  # ==============================================
  vpcs = {
    "main" = {
      cidr_block = "10.1.0.0/16"
      subnets = {
        "public-1b"  = { cidr_block = "10.1.1.0/24", availability_zone = "us-east-1b", public = true }
        "private-1b" = { cidr_block = "10.1.11.0/24", availability_zone = "us-east-1b", public = false }
      }
    }
  }

  # ==============================================
  # Storage Configuration
  # ==============================================
  s3_buckets = {
    "raw"       = { versioning = true }
    "bronze"    = { versioning = true }
    "silver"    = { versioning = true }
    "gold"      = { versioning = true }
    "kb-source" = { versioning = true }
  }

  # ==============================================
  # IAM Roles and Permissions
  # ==============================================
  iam_roles = {
    "bedrock-agent" = { trust_service = "bedrock.amazonaws.com" }
    "bedrock-kb"    = { trust_service = "bedrock.amazonaws.com" }
    "databricks"    = { trust_service = "ec2.amazonaws.com" }
    "fred-fetcher"  = { trust_service = "lambda.amazonaws.com" }
  }

  # ==============================================
  # Amazon Bedrock Configuration
  # ==============================================
  bedrock_config = {
    embedding_model_arn = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
    foundation_model    = "meta.llama3-70b-instruct-v1:0"
    vector_index_name   = "bedrock-knowledge-base-default-index"
    agent_version       = "DRAFT"
  }

  # ==============================================
  # AWS Lambda Configuration
  # ==============================================
  lambda_config = {
    runtime     = "python3.11"
    handler     = "fred_fetcher.handler"
    timeout     = 10
    memory_size = 128
  }

  # ==============================================
  # Databricks Modern Stack Configuration
  # ==============================================
  databricks_config = {
    catalog_name             = "mortgage_xpert_staging"
    schemas                  = ["bronze", "silver", "gold"]
    warehouse_cluster_size   = "2X-Small"
    warehouse_auto_stop_mins = 10
  }
}
