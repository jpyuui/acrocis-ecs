# =================
# VPC
# =================
resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}


# =================
# Public Subnets
# =================
locals {
  default_route = "0.0.0.0/0"
}

resource "aws_subnet" "public" {
  for_each = { for s in var.public_subnets : s.name => s }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.this.id
  destination_cidr_block = local.default_route
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

# =================
# Private Subnets
# =================
resource "aws_subnet" "private" {
  for_each = { for s in var.private_subnets : s.name => s }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false
}

resource "aws_route_table" "private" {
  for_each = aws_nat_gateway.this

  vpc_id = aws_vpc.this.id

  route {
    nat_gateway_id = each.value.id
    cidr_block     = local.default_route
  }
}

resource "aws_route_table_association" "private" {
  for_each = { for idx, s in var.private_subnets : idx => s }

  subnet_id      = aws_subnet.private[each.value.name].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_eip" "nat_gws" {
  count = length(aws_subnet.private)

  vpc = true

  depends_on = [
    aws_internet_gateway.this
  ]
}

resource "aws_nat_gateway" "this" {
  for_each = { for idx, s in var.public_subnets : idx => s }

  allocation_id = aws_eip.nat_gws[each.key].id
  subnet_id     = aws_subnet.public[each.value.name].id

  depends_on = [
    aws_internet_gateway.this
  ]
}
