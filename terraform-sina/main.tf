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

resource "aws_vpc" "sina_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "sina-vpc"
  }
}

resource "aws_security_group" "sina-sg" {
  description = "Allow http and https traffic from the instance"
  vpc_id      = aws_vpc.sina_vpc.id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    # ipv6_cidr_blocks = [aws_vpc.sina_vpc.ipv6_cidr_block]
  }

  ingress {
    description = "HTTPS from VPC"
    from_port=443
    to_port=443
    protocol="tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    # ipv6_cidr_blocks = [aws_vpc.sina_vpc.ipv6_cidr_block]
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
  vpc_id = aws_vpc.sina_vpc.id
  tags = {
    Name = "SinaInternetGateway"
  }
}

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

resource "aws_lb" "sina-lb" {
  name               = "sina-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sina-sg.id]
  subnets            = [aws_subnet.sina-public-subnet-1.id, aws_subnet.sina-public-subnet-2.id]

  enable_deletion_protection = false
}

resource "aws_s3_bucket" "sina-bucket" {
  bucket = "pl-sina-bucket-tf"
  tags = {
    Name        = "Sina bucket"
  }
}

resource "aws_s3_bucket_acl" "sina-bucket-acl" {
  bucket = aws_s3_bucket.sina-bucket.id
  acl    = "private"
}

data "aws_ami" "latest-sinaami" {
most_recent = true
owners = ["814824721268"]

  filter {
      name   = "name"
      values = ["sinaami-*"]
  }
}

resource "aws_route_table" "sina-route-table" {
  vpc_id = aws_vpc.sina_vpc.id
  route {
    cidr_block = "0.0.0.0/0" # 0.0.0.0/10 ???
    gateway_id = aws_internet_gateway.sina-ig.id
  }
}

resource "aws_launch_template" "sina-template" {
  name = "sina-template"
  # ami           = latest-sinaami # Check
  image_id = data.aws_ami.latest-sinaami.id
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "sina-asg" {
  name                      = "sina-asg"
  max_size                  = 4
  min_size                  = 2
#  health_check_grace_period = 300 ## to remove??
#  health_check_type         = "ELB" ## to remove??
  desired_capacity          = 2
  force_delete              = true
  # placement_group           = aws_placement_group.sina_placement_group.id
  # launch_configuration      = aws_launch_template.sina-template.name
  vpc_zone_identifier       = [aws_subnet.sina-private-subnet-1.id, aws_subnet.sina-private-subnet-2.id]

  timeouts {
    delete = "5m"
  }

  launch_template {
    id      = "${aws_launch_template.sina-template.id}"
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.sina-asg.id
  lb_target_group_arn    = aws_lb_target_group.sina-tg.arn
}

resource "aws_lb_target_group" "sina-tg" {
  name     = "sina-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.sina_vpc.id
}

resource "aws_lb_listener" "sina-http-listener" {
  load_balancer_arn = aws_lb.sina-lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sina-tg.arn
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