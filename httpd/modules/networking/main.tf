# VPC
resource "aws_vpc" "httpd" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.namespace}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "httpd" {
  tags = {
    Name = "${var.namespace}-igw"
  }
}

# Internet Gateway Attachment
resource "aws_internet_gateway_attachment" "httpd" {
  internet_gateway_id = aws_internet_gateway.httpd.id
  vpc_id              = aws_vpc.httpd.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Subnet A
resource "aws_subnet" "subnetA" {
  availability_zone = data.aws_availability_zones.available.names[0]
  vpc_id            = aws_vpc.httpd.id
  cidr_block        = "172.31.38.0/24"

  tags = {
    Name = "${var.namespace}-subnetA"
  }
}

# Subnet B
resource "aws_subnet" "subnetB" {
  availability_zone = data.aws_availability_zones.available.names[1]
  vpc_id            = aws_vpc.httpd.id
  cidr_block        = "172.31.37.0/24"

  tags = {
    Name = "${var.namespace}-subnetB"
  }
}

# Route Table
resource "aws_route_table" "httpd" {
  vpc_id = aws_vpc.httpd.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.httpd.id
  }

  tags = {
    Name = "${var.namespace}-route-table"
  }
}

# Route Table Association A
resource "aws_route_table_association" "route-table-associationA" {
  subnet_id      = aws_subnet.subnetA.id
  route_table_id = aws_route_table.httpd.id
}

# Route Table Association B
resource "aws_route_table_association" "route-table-associationB" {
  subnet_id      = aws_subnet.subnetB.id
  route_table_id = aws_route_table.httpd.id
}

# Network Acl
resource "aws_network_acl" "httpd" {
  vpc_id = aws_vpc.httpd.id

  egress {
    from_port  = -0
    to_port    = -0
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "${var.namespace}-acl"
  }
}

# Network Acl AssociationA
resource "aws_network_acl_association" "network-acl-associationA" {
  subnet_id      = aws_subnet.subnetA.id
  network_acl_id = aws_network_acl.httpd.id
}

# Network Acl AssociationB
resource "aws_network_acl_association" "network-acl-associationB" {
  subnet_id      = aws_subnet.subnetB.id
  network_acl_id = aws_network_acl.httpd.id
}

module "lb_sg" {
  source = "terraform-in-action/sg/aws"

  name        = "lb-sg"
  description = "Security group for LB"
  vpc_id      = aws_vpc.httpd.id

  ingress_rules = [
    {
      protocol    = "tcp"
      port        = 80
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "efs_sg" {
  source = "terraform-in-action/sg/aws"

  name        = "efs-sg"
  description = "Security group for EFS Mount target"
  vpc_id      = aws_vpc.httpd.id

  ingress_rules = [
    {
      protocol        = "tcp"
      port            = 2049
      security_groups = [module.backend_sg.security_group.id]
    }
  ]
}

# Security Group: backend
module "backend_sg" {
  source = "terraform-in-action/sg/aws"

  name        = "backend-sg"
  description = "Security group for backend servers"
  vpc_id      = aws_vpc.httpd.id

  ingress_rules = [
    {
      protocol        = "tcp"
      port            = 80
      security_groups = [module.lb_sg.security_group.id]
    }
  ]
}
