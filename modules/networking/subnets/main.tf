resource "aws_subnet" "this" {
  for_each = var.subnet_config

  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.public

  tags = {
    Name        = "${var.project_name}-${var.environment}-${each.key}"
    Environment = var.environment
    Type        = each.value.public ? "public" : "private"
  }
}
