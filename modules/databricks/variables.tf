terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "project_name" { type = string }
variable "environment" { type = string }
variable "databricks_role_arn" { type = string }
variable "s3_buckets" { type = map(string) }
variable "databricks_config" { type = any }
