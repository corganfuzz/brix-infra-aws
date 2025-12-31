output "role_arns" {
  value = { for k, v in aws_iam_role.this : k => v.arn }
}

output "role_names" {
  value = { for k, v in aws_iam_role.this : k => v.name }
}

output "databricks_role_arn" {
  value = try(aws_iam_role.databricks["databricks"].arn, null)
}

output "databricks_instance_profile_arn" {
  value = try(aws_iam_instance_profile.databricks["databricks"].arn, null)
}
