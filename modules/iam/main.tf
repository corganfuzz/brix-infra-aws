data "aws_caller_identity" "current" {}

# Generic Role Creation
resource "aws_iam_role" "this" {
  for_each = var.iam_roles
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
  for_each = contains(keys(var.iam_roles), "databricks") ? { "databricks" = var.iam_roles["databricks"] } : {}
  name     = "DatabricksS3Access"
  role     = aws_iam_role.this["databricks"].id

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
  for_each = contains(keys(var.iam_roles), "databricks") ? { "databricks" = var.iam_roles["databricks"] } : {}
  name     = "${var.project_name}-${var.environment}-databricks-profile"
  role     = aws_iam_role.this["databricks"].name
}
