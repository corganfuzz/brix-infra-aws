variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "vpc_cidr" {
  type = string
}
