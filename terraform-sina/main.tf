terraform {
  required_providers {
    aws = ">= 4.8.0"
  }
  required_version = ">= 0.12"
}

provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}

resource "aws_security_group" "sina-sg" {
  description = "Allow http and https traffic from the instance"
  vpc_id      = aws_vpc.main.id # TODO check if it is correct

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block] # TODO CHECK
    ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    description = "HTTPS from VPC"
    from_port=443
    to_port=443
    protocol="tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block] # TODO CHECK
    ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    description = "Anything to VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Allow HTTPS/S"
  }
}

resource "aws_internet_gateway" "sina-ig" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "SinaInternetGateway"
  }
}

resource "aws_subnet" "sina-private-subnet-1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "sina-private-subnet-1"
  }
}

resource "aws_subnet" "sina-private-subnet-2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "sina-private-subnet-2"
  }
}

resource "aws_subnet" "sina-public-subnet-1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "sina-public-subnet-1"
  }
}


# Route table


#

# TO REMOVE

resource "aws_instance" "app_test" {
  ami           = "ami-0dcc0ebde7b2e00db"
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}