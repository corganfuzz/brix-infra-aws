# The Vector Store
resource "aws_opensearchserverless_security_policy" "network" {
  name = "${var.project_name}-${var.environment}-network-policy"
  type = "network"
  policy = jsonencode([
    {
      Description = "Public access for OSS"
      Rules = [
        {
          ResourceType = "collection"
          Resource     = ["collection/${var.project_name}-${var.environment}-collection"]
        },
        {
          ResourceType = "dashboard"
          Resource     = ["collection/${var.project_name}-${var.environment}-collection"]
        }
      ]
      AllowFromPublic = true
    }
  ])
}

resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${var.project_name}-${var.environment}-encryption-policy"
  type = "encryption"
  policy = jsonencode({
    Rules = [
      {
        ResourceType = "collection"
        Resource     = ["collection/${var.project_name}-${var.environment}-collection"]
      }
    ]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_collection" "this" {
  name       = "${var.project_name}-${var.environment}-collection"
  type       = "VECTORSEARCH"
  depends_on = [aws_opensearchserverless_security_policy.encryption, aws_opensearchserverless_security_policy.network]
}

# Knowledge Base (KB)
resource "aws_bedrockagent_knowledge_base" "this" {
  name     = "${var.project_name}-${var.environment}-kb"
  role_arn = var.bedrock_kb_role_arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = var.bedrock_config.embedding_model_arn
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.this.arn
      vector_index_name = var.bedrock_config.vector_index_name
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }
}

resource "aws_bedrockagent_data_source" "this" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.this.id
  name              = "${var.project_name}-${var.environment}-ds"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = var.kb_s3_bucket_arn
    }
  }
}

# Bedrock Agent
resource "aws_bedrockagent_agent" "this" {
  agent_name              = "${var.project_name}-${var.environment}-agent"
  agent_resource_role_arn = var.bedrock_agent_role_arn
  foundation_model        = var.bedrock_config.foundation_model
  instruction             = file("${path.module}/src/agent.txt")
}

resource "aws_bedrockagent_agent_action_group" "fred" {
  action_group_name          = "MortgageRateTools"
  agent_id                   = aws_bedrockagent_agent.this.id
  agent_version              = "DRAFT"
  skip_resource_in_use_check = true

  action_group_executor {
    lambda = var.lambda_function_arn
  }

  function_schema {
    member_functions {
      functions {
        name        = "fetch_mortgage_rates"
        description = "Gets the latest 30-year fixed mortgage rates from the Federal Reserve (FRED)."
      }
    }
  }
}

resource "aws_bedrockagent_agent_knowledge_base_association" "this" {
  agent_id             = aws_bedrockagent_agent.this.id
  agent_version        = var.bedrock_config.agent_version
  knowledge_base_id    = aws_bedrockagent_knowledge_base.this.id
  description          = "Access to mortgage guidelines and dictionaries."
  knowledge_base_state = "ENABLED"
}
