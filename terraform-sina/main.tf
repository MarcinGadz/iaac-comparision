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
  vpc_id      = aws_vpc.sina_vpc.id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "HTTPS from VPC"
    from_port=443
    to_port=443
    protocol="tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
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
    Name = "Allow HTTP and HTTPS"
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

resource "aws_lb_listener" "sina-http-listener" {
  load_balancer_arn = aws_lb.sina-lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sina-tg.arn
  }
}

resource "aws_lb_target_group" "sina-tg" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.sina_vpc.id
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.sina-asg.id
  lb_target_group_arn    = aws_lb_target_group.sina-tg.arn
}