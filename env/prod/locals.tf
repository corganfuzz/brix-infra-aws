locals {
  project_name = "mortgage-xpert"
  environment  = "prod"

  vpcs = {
    "main" = {
      cidr_block = "10.2.0.0/16"
      subnets = {
        "public-1c"  = { cidr_block = "10.2.1.0/24", availability_zone = "us-east-1c", public = true }
        "private-1c" = { cidr_block = "10.2.11.0/24", availability_zone = "us-east-1c", public = false }
      }
    }
  }
}
