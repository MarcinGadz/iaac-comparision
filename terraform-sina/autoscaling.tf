data "aws_ami" "latest-sinaami" {
most_recent = true
owners = ["814824721268"]

  filter {
      name   = "name"
      values = ["sinaami-*"]
  }
}

resource "aws_launch_template" "sina-template" {
  name_prefix = "sina-template"
  image_id = data.aws_ami.latest-sinaami.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.sina-sg.id]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "SinaASGInstance"
    }
  }
}

resource "aws_autoscaling_group" "sina-asg" {
  name                      = "sina-asg"
  max_size                  = 4
  min_size                  = 2
  desired_capacity          = 2
  force_delete              = true
  vpc_zone_identifier       = [aws_subnet.sina-private-subnet-1.id, aws_subnet.sina-private-subnet-2.id]

  timeouts {
    delete = "5m"
  }

  launch_template {
    id      = "${aws_launch_template.sina-template.id}"
  }
}