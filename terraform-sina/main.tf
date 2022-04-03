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
  vpc_id      = aws_vpc.sina_vpc.id # TODO check if it is correct

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.sina_vpc.cidr_block] # TODO CHECK
    ipv6_cidr_blocks = [aws_vpc.sina_vpc.ipv6_cidr_block]
  }

  ingress {
    description = "HTTPS from VPC"
    from_port=443
    to_port=443
    protocol="tcp"
    cidr_blocks      = [aws_vpc.sina_vpc.cidr_block] # TODO CHECK
    ipv6_cidr_blocks = [aws_vpc.sina_vpc.ipv6_cidr_block]
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

  tags = {
    Name = "sina-private-subnet-1"
  }
}

resource "aws_subnet" "sina-private-subnet-2" {
  vpc_id     = aws_vpc.sina_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "sina-private-subnet-2"
  }
}

resource "aws_subnet" "sina-public-subnet-1" {
  vpc_id     = aws_vpc.sina_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "sina-public-subnet-1"
  }
}

resource "aws_subnet" "sina-public-subnet-2" {
  vpc_id     = aws_vpc.sina_vpc.id
  cidr_block = "10.0.3.0/24"

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

  enable_deletion_protection = true
}

resource "aws_s3_bucket" "sina-bucket" {
  bucket = "pl-sina-bucket"

  tags = {
    Name        = "Sina bucket"
  }
}

resource "aws_placement_group" "sina_placement_group" {
  name     = "sina_placement_group"
  strategy = "cluster"
}

# resource "aws_launch_template" "sina-template" {
#   name = "sina-template"
#   ami           = "ami-0dcc0ebde7b2e00db"
#   instance_type = "t2.micro"
# }

# resource "aws_autoscaling_group" "sina-asg" {
#   name                      = "sina-asg"
#   max_size                  = 4
#   min_size                  = 2
#   health_check_grace_period = 300
#   health_check_type         = "ELB"
#   desired_capacity          = 3
#   force_delete              = true
#   placement_group           = aws_placement_group.sina_placement_group.id
#   launch_configuration      = aws_launch_template.sina-template.name
#   vpc_zone_identifier       = [aws_subnet.sina-private-subnet-1.id, aws_subnet.sina-private-subnet-2.id]

#   initial_lifecycle_hook {
#     name                 = "sina"
#     default_result       = "CONTINUE"
#     heartbeat_timeout    = 2000
#     lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"

# #     notification_metadata = <<EOF
# # {
# #   "foo": "bar"
# # }
# # EOF

# #     notification_target_arn = "arn:aws:sqs:us-east-1:444455556666:queue1*"
# #     role_arn                = "arn:aws:iam::123456789012:role/S3Access"
#   }

#   # tag {
#   #   key                 = "sina-key"
#   #   value               = "Sina"
#   #   propagate_at_launch = false
#   # }

#   timeouts {
#     delete = "5m"
#   }

#   launch_template {
#     id      = aws_launch_template.foobar.id
#     version = "$Latest"
#   }
# }
