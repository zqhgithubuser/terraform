terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Region
provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "httpd" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "httpd"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "default" {
  tags = {
    Name = "default"
  }
}

# Internet Gateway Attachment
resource "aws_internet_gateway_attachment" "default" {
  internet_gateway_id = aws_internet_gateway.default.id
  vpc_id              = aws_vpc.httpd.id
}

# Subnet A
resource "aws_subnet" "subnetA" {
  availability_zone = data.aws_availability_zones.available.names[0]
  vpc_id            = aws_vpc.httpd.id
  cidr_block        = "172.31.38.0/24"

  tags = {
    Name = "subnetA"
  }
}

# Subnet B
resource "aws_subnet" "subnetB" {
  availability_zone = data.aws_availability_zones.available.names[1]
  vpc_id            = aws_vpc.httpd.id
  cidr_block        = "172.31.37.0/24"

  tags = {
    Name = "subnetB"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Route Table
resource "aws_route_table" "httpd" {
  vpc_id = aws_vpc.httpd.id

  tags = {
    Name = "httpd"
  }
}

# Route Table Association A
resource "aws_route_table_association" "route-table-association-A" {
  subnet_id      = aws_subnet.subnetA.id
  route_table_id = aws_route_table.httpd.id
}

# Route Table Association B
resource "aws_route_table_association" "route-table-association-B" {
  subnet_id      = aws_subnet.subnetB.id
  route_table_id = aws_route_table.httpd.id
}

# Route: Ref Internet Gateway
resource "aws_route" "public-nat-to-internet" {
  route_table_id         = aws_route_table.httpd.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# Network Acl
resource "aws_network_acl" "httpd" {
  vpc_id = aws_vpc.httpd.id

  tags = {
    Name = "httpd"
  }
}

# Network Acl AssociationA
resource "aws_network_acl_association" "network-acl-association-A" {
  subnet_id      = aws_subnet.subnetA.id
  network_acl_id = aws_network_acl.httpd.id
}

# Network Acl AssociationB
resource "aws_network_acl_association" "network-acl-association-B" {
  subnet_id      = aws_subnet.subnetB.id
  network_acl_id = aws_network_acl.httpd.id
}

# Network Acl Rule
resource "aws_network_acl_rule" "allow-all-ingress" {
  network_acl_id = aws_network_acl.httpd.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "allow-all-egress" {
  network_acl_id = aws_network_acl.httpd.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
}

resource "aws_security_group" "alb" {
  description = "alb-sg"
  vpc_id      = aws_vpc.httpd.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Elastic File System
resource "aws_efs_file_system" "httpd" {
  tags = {
    Name = "httpd"
  }
}

# Mount Target Security Group
resource "aws_security_group" "efs" {
  description = "EFS Mount target"
  vpc_id      = aws_vpc.httpd.id

  ingress {
    protocol        = "tcp"
    from_port       = 2049
    to_port         = 2049
    security_groups = [ aws_security_group.backend.id ]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Mount TargetA
resource "aws_efs_mount_target" "efs-mount-target-A" {
  file_system_id  = aws_efs_file_system.httpd.id
  security_groups = [ aws_security_group.efs.id ]
  subnet_id       = aws_subnet.subnetA.id
}

# Mount TargetB
resource "aws_efs_mount_target" "efs-mount-target-B" {
  file_system_id  = aws_efs_file_system.httpd.id
  security_groups = [ aws_security_group.efs.id ]
  subnet_id       = aws_subnet.subnetB.id
}

resource "aws_lb" "httpd" {
  name               = "httpd"

  load_balancer_type = "application"
  subnets            = [ aws_subnet.subnetA.id, aws_subnet.subnetB.id ]
  security_groups    = [ aws_security_group.alb.id ]
  depends_on         = [ aws_internet_gateway_attachment.default ]
}

resource "aws_lb_listener" "httpd" {
  load_balancer_arn = aws_lb.httpd.arn
  port              = 80
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "httpd" {
  name     = "httpd"

  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.httpd.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "httpd" {
  listener_arn = aws_lb_listener.httpd.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.httpd.arn
  }
}

# Security Group: backend
resource "aws_security_group" "backend" {
  description = "backend-sg"
  vpc_id = aws_vpc.httpd.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    security_groups = [ aws_security_group.alb.id ]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Launch Template
resource "aws_launch_template" "httpd" {
  iam_instance_profile {
    name = aws_iam_instance_profile.httpd.id
  }
  image_id = "ami-0d1d4b8d5a0cd293f"

  monitoring {
    enabled = false
  }

  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = true
    device_index                = 0
    security_groups             = [ aws_security_group.backend.id ]
  }

  user_data = base64encode(data.template_file.user_data.rendered)

  depends_on = [
    aws_efs_mount_target.efs-mount-target-A,
    aws_efs_mount_target.efs-mount-target-B
   ]
}

data "template_file" "user_data" {
  template = file("user_data.sh.tpl")

  vars = {
    efs_id     = aws_efs_file_system.httpd.id
    aws_region = var.aws_region
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "httpd" {
  name = "httpd"
  launch_template {
    id      = aws_launch_template.httpd.id
    version = "$Latest"
  }
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 2
  target_group_arns         = [ aws_lb_target_group.httpd.arn ]
  vpc_zone_identifier       = [ aws_subnet.subnetA.id, aws_subnet.subnetB.id ]

  depends_on = [ aws_internet_gateway_attachment.default ]
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

