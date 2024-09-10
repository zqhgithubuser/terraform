output "vpc_id" {
  value = aws_vpc.httpd.id
}

output "subnet" {
  value = {
    subnetA_id = aws_subnet.subnetA.id
    subnetB_id = aws_subnet.subnetB.id
  }
}

output "sg" {
  value = {
    lb      = module.lb_sg.security_group
    efs     = module.efs_sg.security_group
    backend = module.backend_sg.security_group
  }
}
