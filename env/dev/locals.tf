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
    "databricks"    = { trust_service = "ec2.amazonaws.com" }
    "fred-fetcher"  = { trust_service = "lambda.amazonaws.com" }
  }

  bedrock_config = {
    embedding_model_arn = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
    foundation_model    = "meta.llama3-70b-instruct-v1:0"
    vector_index_name   = "bedrock-knowledge-base-default-index"
    agent_version       = "DRAFT"
  }

  lambda_config = {
    runtime     = "python3.11"
    handler     = "fred_fetcher.handler"
    timeout     = 10
    memory_size = 128
  }
}
