output "iam_roles" {
  value = module.infrastructure.iam_roles
}

output "bedrock_kb_id" {
  value = module.infrastructure.bedrock_kb_id
}

output "bedrock_data_source_id" {
  value = module.infrastructure.bedrock_data_source_id
}

output "knowledge_base_sync_command" {
  value = <<EOT
To sync your PDFs, run the following command from the root:
./scripts/sync_kb.sh ${module.infrastructure.bedrock_kb_id} ${module.infrastructure.bedrock_data_source_id}
EOT
}
