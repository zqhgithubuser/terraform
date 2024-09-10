# Launch Template
resource "aws_launch_template" "httpd" {
  iam_instance_profile {
    name = aws_iam_instance_profile.httpd.id
  }
  image_id = "ami-0d1d4b8d5a0cd293f"

  monitoring {
    enabled = false
  }

  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    device_index                = 0
    security_groups             = [ var.sg.backend.id ]
  }

  user_data = base64encode(data.template_file.user_data.rendered)

  depends_on = [
    var.efs_mount_targetA,
    var.efs_mount_targetB
  ]
}

data "template_file" "user_data" {
  template = file("${path.module}/userdata.sh")

  vars = {
    efs_id = var.efs_id
    region = var.region
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "httpd" {
  name = "${var.namespace}-asg"
  launch_template {
    id      = aws_launch_template.httpd.id
    version = "$Latest"
  }
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 2
  target_group_arns         = [ var.lb_target_group.arn ]
  vpc_zone_identifier       = [ var.subnet.subnetA_id, var.subnet.subnetB_id ]

  # depends_on = [ aws_internet_gateway_attachment.default ]
}

# Iam Role
resource "aws_iam_role" "httpd" {
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json

  inline_policy {
    name = "ssm"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ssmmessages:*",
            "ssm:UpdateInstanceInformation",
            "ec2messages:*"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

# Iam Instance Profile
resource "aws_iam_instance_profile" "httpd" {
  role = aws_iam_role.httpd.id
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
