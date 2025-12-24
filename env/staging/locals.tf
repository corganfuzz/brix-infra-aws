locals {
  project_name = "mortgage-xpert"
  environment  = "staging"

  vpcs = {
    "main" = {
      cidr_block = "10.1.0.0/16"
      subnets = {
        "public-1b"  = { cidr_block = "10.1.1.0/24", availability_zone = "us-east-1b", public = true }
        "private-1b" = { cidr_block = "10.1.11.0/24", availability_zone = "us-east-1b", public = false }
      }
    }
  }
}
