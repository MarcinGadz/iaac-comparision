resource "aws_internet_gateway" "sina-ig" {
  vpc_id = aws_vpc.sina_vpc.id
  tags = {
    Name = "SinaInternetGateway"
  }
}

resource "aws_vpc" "sina_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "sina-vpc"
  }
}