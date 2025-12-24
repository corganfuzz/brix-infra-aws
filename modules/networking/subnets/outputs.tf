output "subnet_ids" {
  value = { for k, v in aws_subnet.this : k => v.id }
}

output "public_subnet_ids" {
  value = [for k, v in aws_subnet.this : v.id if var.subnet_config[k].public]
}

output "private_subnet_ids" {
  value = [for k, v in aws_subnet.this : v.id if !var.subnet_config[k].public]
}

output "subnets_by_az" {
  value = {
    for az in distinct([for s in var.subnet_config : s.availability_zone]) :
    az => [for k, v in aws_subnet.this : v.id if v.availability_zone == az]
  }
}
