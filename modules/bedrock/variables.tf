variable "project_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string }
variable "kb_s3_bucket_arn" { type = string }
variable "kb_s3_bucket_name" { type = string }
variable "lambda_function_arn" { type = string }
variable "bedrock_kb_role_arn" { type = string }
variable "bedrock_agent_role_arn" { type = string }
variable "bedrock_config" { type = any }

data "aws_caller_identity" "current" {}
