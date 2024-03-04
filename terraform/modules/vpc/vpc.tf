resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    "Name" = var.vpc_name
  }
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = format("%s-igw", var.vpc_name)
  }
}

resource "aws_subnet" "private" {
  for_each          = var.private_subnets_by_az
  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  tags = {
    "Name" = format("private-subnet-%s", each.key)
  }
  cidr_block = each.value
}

resource "aws_subnet" "public" {
  for_each          = var.public_subnets_by_az
  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  tags = {
    "Name" = format("public-subnet-%s", each.key)
  }
  cidr_block = each.value
}

resource "aws_eip" "eip" {
  for_each = var.private_subnets_by_az
}

resource "aws_nat_gateway" "ng" {
  for_each      = var.public_subnets_by_az
  allocation_id = aws_eip.eip[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  tags = {
    "Name" = format("nat-gateway-%s", each.key)
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "public-route-table"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id

}

resource "aws_route_table_association" "public" {
  for_each       = var.public_subnets_by_az
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = var.private_subnets_by_az
  vpc_id   = aws_vpc.main.id
  tags = {
    "Name" = format("private-rt-%s", each.key)
  }
}

resource "aws_route" "private" {
  for_each               = var.private_subnets_by_az
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ng[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each       = var.private_subnets_by_az
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}
