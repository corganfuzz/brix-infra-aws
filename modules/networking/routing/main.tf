# Public Routing
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_ids)
  subnet_id      = var.public_subnet_ids[count.index]
  route_table_id = aws_route_table.public.id
}

# Private Routing
resource "aws_route_table" "private" {
  for_each = var.private_routing_config
  vpc_id   = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = each.value.nat_gateway_id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-rt-${each.key}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private" {
  for_each       = var.private_routing_config
  subnet_id      = each.value.subnet_id
  route_table_id = aws_route_table.private[each.key].id
}
