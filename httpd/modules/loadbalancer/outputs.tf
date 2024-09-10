output "lb_target_group" {
  value = aws_lb_target_group.httpd
}

output "lb_dns_name" {
  value = aws_lb.httpd.dns_name
}
