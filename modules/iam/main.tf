data "aws_caller_identity" "current" {}

# Generic Role Creation (excludes databricks which has special trust requirements)
resource "aws_iam_role" "this" {
  for_each = { for k, v in var.iam_roles : k => v if k != "databricks" }
  name     = "${var.project_name}-${var.environment}-${each.key}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = each.value.trust_service == "self" ? {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          } : length(regexall("\\.amazonaws\\.com$", each.value.trust_service)) > 0 ? {
          Service = each.value.trust_service
          } : {
          AWS = each.value.trust_service
        }
      }
    ]
  })
}

# Dedicated Databricks Role with composite trust policy
resource "aws_iam_role" "databricks" {
  count = contains(keys(var.iam_roles), "databricks") ? 1 : 0
  name  = "${var.project_name}-${var.environment}-databricks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EC2AssumeRole"
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      },
      {
        Sid       = "UnityCatalogAssumeRole"
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL" }
        Condition = {
          StringEquals = { "sts:ExternalId" = "f5c1a4da-735a-402d-aa3b-303cf3885ae9" }
        }
      },
      {
        Sid       = "SelfAssumeRole"
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.environment}-databricks-role" }
      }
    ]
  })
}

# Bedrock KB Policy
resource "aws_iam_role_policy" "bedrock_kb_s3_access" {
  for_each = contains(keys(var.iam_roles), "bedrock-kb") ? { "bedrock-kb" = var.iam_roles["bedrock-kb"] } : {}
  name     = "BedrockKBS3Access"
  role     = aws_iam_role.this["bedrock-kb"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:GetObject", "s3:ListBucket"]
        Effect = "Allow"
        Resource = [
          var.storage_bucket_arns["kb-source"],
          "${var.storage_bucket_arns["kb-source"]}/*"
        ]
      }
    ]
  })
}

# Databricks S3 Access Policy
resource "aws_iam_role_policy" "databricks_s3_access" {
  count = contains(keys(var.iam_roles), "databricks") ? 1 : 0
  name  = "DatabricksS3Access"
  role  = aws_iam_role.databricks[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Effect = "Allow"
        Resource = [
          for arn in values(var.storage_bucket_arns) : arn
        ]
      },
      {
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Effect = "Allow"
        Resource = [
          for arn in values(var.storage_bucket_arns) : "${arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "databricks" {
  count = contains(keys(var.iam_roles), "databricks") ? 1 : 0
  name  = "${var.project_name}-${var.environment}-databricks-profile"
  role  = aws_iam_role.databricks[0].name
}
