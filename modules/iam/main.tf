terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
    }
  }
}

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
# NOTE: Self-assume is added via null_resource AFTER creation to avoid chicken-and-egg
resource "aws_iam_role" "databricks" {
  for_each = contains(keys(var.iam_roles), "databricks") ? { "databricks" = var.iam_roles["databricks"] } : {}
  name     = "${var.project_name}-${var.environment}-databricks-role"

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
      }
    ]
  })

  lifecycle {
    ignore_changes = [assume_role_policy] # Allow external updates via null_resource
  }
}

# Add self-assume policy AFTER role creation (solves chicken-and-egg)
resource "null_resource" "databricks_self_assume" {
  for_each = aws_iam_role.databricks

  triggers = {
    role_arn = each.value.arn
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws iam update-assume-role-policy --role-name ${each.value.name} --policy-document '{
        "Version": "2012-10-17",
        "Statement": [
          {
            "Sid": "EC2AssumeRole",
            "Effect": "Allow",
            "Principal": {"Service": "ec2.amazonaws.com"},
            "Action": "sts:AssumeRole"
          },
          {
            "Sid": "UnityCatalogAssumeRole",
            "Effect": "Allow",
            "Principal": {"AWS": "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"},
            "Action": "sts:AssumeRole",
            "Condition": {"StringEquals": {"sts:ExternalId": "f5c1a4da-735a-402d-aa3b-303cf3885ae9"}}
          },
          {
            "Sid": "SelfAssumeRole",
            "Effect": "Allow",
            "Principal": {"AWS": "${each.value.arn}"},
            "Action": "sts:AssumeRole"
          }
        ]
      }'
    EOT
  }
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
  role     = aws_iam_role.databricks["databricks"].id

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
  role     = aws_iam_role.databricks["databricks"].name
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  for_each   = contains(keys(var.iam_roles), "fred-fetcher") ? { "fred-fetcher" = var.iam_roles["fred-fetcher"] } : {}
  role       = aws_iam_role.this["fred-fetcher"].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "fred_fetcher_s3_access" {
  for_each = contains(keys(var.iam_roles), "fred-fetcher") ? { "fred-fetcher" = var.iam_roles["fred-fetcher"] } : {}
  name     = "FredFetcherS3Access"
  role     = aws_iam_role.this["fred-fetcher"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
        Resource = ["${var.storage_bucket_arns["raw"]}/mortgage_rates/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_kb_model_access" {
  for_each = contains(keys(var.iam_roles), "bedrock-kb") ? { "bedrock-kb" = var.iam_roles["bedrock-kb"] } : {}
  name     = "BedrockKBModelAccess"
  role     = aws_iam_role.this["bedrock-kb"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "bedrock:InvokeModel"
        Effect   = "Allow"
        Resource = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
      }
    ]
  })
}

# API Proxy Lambda Policies
resource "aws_iam_role_policy_attachment" "api_proxy_basic" {
  for_each   = contains(keys(var.iam_roles), "api-proxy") ? { "api-proxy" = var.iam_roles["api-proxy"] } : {}
  role       = aws_iam_role.this["api-proxy"].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "api_proxy_bedrock_access" {
  for_each = contains(keys(var.iam_roles), "api-proxy") ? { "api-proxy" = var.iam_roles["api-proxy"] } : {}
  name     = "BedrockAgentInvoke"
  role     = aws_iam_role.this["api-proxy"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "bedrock:InvokeAgent"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_agent_model_access" {
  for_each = contains(keys(var.iam_roles), "bedrock-agent") ? { "bedrock-agent" = var.iam_roles["bedrock-agent"] } : {}
  name     = "BedrockAgentModelAccess"
  role     = aws_iam_role.this["bedrock-agent"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "bedrock:InvokeModel",
          "bedrock:GetFoundationModel",
          "bedrock:ListFoundationModels"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = ["bedrock:Retrieve", "bedrock:RetrieveAndGenerate"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_proxy_s3_log_access" {
  for_each = contains(keys(var.iam_roles), "api-proxy") ? { "api-proxy" = var.iam_roles["api-proxy"] } : {}
  name     = "ApiProxyS3LogAccess"
  role     = aws_iam_role.this["api-proxy"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:PutObject"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::*-raw-data-*/*"
      }
    ]
  })
}
