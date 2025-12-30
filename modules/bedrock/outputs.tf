output "agent_id" {
  value = aws_bedrockagent_agent.this.id
}

output "kb_id" {
  value = aws_bedrockagent_knowledge_base.this.id
}

output "oss_collection_arn" {
  value = aws_opensearchserverless_collection.this.arn
}
