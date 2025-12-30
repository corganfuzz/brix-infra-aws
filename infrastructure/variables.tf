variable "project_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string }

variable "vpcs" {
  description = "Map of VPC configurations including subnets"
  type = map(object({
    cidr_block = string
    subnets = map(object({
      cidr_block        = string
      availability_zone = string
      public            = bool
    }))
  }))
}

variable "s3_buckets" {
  description = "Map of S3 bucket configurations"
  type = map(object({
    versioning = bool
  }))
}

variable "iam_roles" {
  description = "Map of IAM role configurations"
  type = map(object({
    trust_service = string
  }))
}

variable "databricks_host" {
  description = "Databricks Workspace URL"
  type        = string
}

variable "databricks_token" {
  description = "Databricks Personal Access Token"
  type        = string
  sensitive   = true
}

variable "fred_api_key" {
  description = "FRED API Key for mortgage rates"
  type        = string
  sensitive   = true
}

variable "bedrock_config" {
  description = "Configuration for Bedrock Knowledge Base and Agent"
  type        = any
}

variable "lambda_config" {
  description = "Configuration for Lambda functions"
  type        = any
}

variable "databricks_config" {
  description = "Configuration for Databricks catalog and compute"
  type        = any
}
