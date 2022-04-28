data "aws_ami" "latest-sinaami" {
most_recent = true
owners = ["814824721268"]

  filter {
      name   = "name"
      values = ["sinaami-*"]
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