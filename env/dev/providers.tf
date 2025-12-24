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
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}
