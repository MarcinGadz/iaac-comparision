resource "aws_subnet" "sina-private-subnet-1" {
  vpc_id     = aws_vpc.sina_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "sina-private-subnet-1"
  }
}

resource "aws_subnet" "sina-private-subnet-2" {
  vpc_id     = aws_vpc.sina_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "sina-private-subnet-2"
  }
}

resource "aws_subnet" "sina-public-subnet-1" {
  vpc_id     = aws_vpc.sina_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "sina-public-subnet-1"
  }
}

resource "aws_subnet" "sina-public-subnet-2" {
  vpc_id     = aws_vpc.sina_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "sina-public-subnet-2"
  }
}

resource "aws_route_table" "sina-route-table" {
  vpc_id = aws_vpc.sina_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sina-ig.id
  }
}

resource "aws_route_table_association" "route-assoc-1" {
  subnet_id      = aws_subnet.sina-public-subnet-1.id
  route_table_id = aws_route_table.sina-route-table.id
}

resource "aws_route_table_association" "route-assoc-2" {
  subnet_id      = aws_subnet.sina-public-subnet-1.id
  route_table_id = aws_route_table.sina-route-table.id
}