variable "project_name" { type = string }
variable "environment" { type = string }
variable "nat_gateway_config" {
  description = "Map of NAT Gateway names to their public subnet IDs"
  type        = map(string)
}
