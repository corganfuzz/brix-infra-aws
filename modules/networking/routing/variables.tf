variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "igw_id" { type = string }
variable "public_subnet_ids" {
  type = list(string)
}
variable "private_routing_config" {
  description = "Map of private subnet keys to their NAT Gateway targets"
  type = map(object({
    subnet_id      = string
    nat_gateway_id = string
  }))
}
