variable "project_name" { type = string }
variable "environment" { type = string }

variable "vpcs" {
  description = "Map of VPC configurations including subnets"
  type = map(object({
    cidr_block = string
    subnets = map(object({
      cidr_block        = string
      availability_zone = string
      public            = bool
    }))
  }))
}
