output "role_arns" {
  value = { for k, v in aws_iam_role.this : k => v.arn }
}

output "databricks_role_arn" {
  value = aws_iam_role.this["databricks"].arn
}

output "databricks_instance_profile_arn" {
  value = try(aws_iam_instance_profile.databricks["databricks"].arn, null)
}
