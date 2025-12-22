provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "mortgage-xpert-tfstate-446311000231"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}

module "main" {
  source = "../../main"

  project_name       = "mortgage-xpert"
  environment        = "prod"
  vpc_cidr           = "10.2.0.0/16"
  availability_zones = ["us-east-1c"]
}

output "vpc_id" {
  value = module.main.vpc_id
}
