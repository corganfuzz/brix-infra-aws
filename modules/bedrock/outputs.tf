output "agent_id" {
  value = aws_bedrockagent_agent.this.id
}

output "kb_id" {
  value = aws_bedrockagent_knowledge_base.this.id
}

output "data_source_id" {
  value = aws_bedrockagent_data_source.this.data_source_id
}

output "oss_collection_arn" {
  value = aws_opensearchserverless_collection.this.arn
}
