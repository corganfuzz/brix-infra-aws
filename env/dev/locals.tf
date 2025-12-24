locals {
  project_name = "mortgage-xpert"
  environment  = "dev"

  vpcs = {
    "main" = {
      cidr_block = "10.0.0.0/16"
      subnets = {
        "public-1a"  = { cidr_block = "10.0.1.0/24", availability_zone = "us-east-1a", public = true }
        "private-1a" = { cidr_block = "10.0.11.0/24", availability_zone = "us-east-1a", public = false }
      }
    }
  }
}
