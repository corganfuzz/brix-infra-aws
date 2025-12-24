resource "aws_eip" "nat" {
  for_each = var.nat_gateway_config
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat-eip-${each.key}"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "this" {
  for_each      = var.nat_gateway_config
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value

  tags = {
    Name        = "${var.project_name}-${var.environment}-nat-${each.key}"
    Environment = var.environment
  }
}
