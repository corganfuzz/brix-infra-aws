output "vpc_id" {
  value = aws_vpc.this.id
}

output "igw_id" {
  value = aws_internet_gateway.this.id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}
