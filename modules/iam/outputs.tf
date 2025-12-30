output "role_arns" {
  value = { for k, v in aws_iam_role.this : k => v.arn }
}

output "databricks_role_arn" {
  value = try(aws_iam_role.databricks[0].arn, null)
}

output "databricks_instance_profile_arn" {
  value = try(aws_iam_instance_profile.databricks[0].arn, null)
}
