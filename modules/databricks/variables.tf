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
variable "databricks_instance_profile_arn" { type = string }
variable "s3_buckets" { type = map(string) }
