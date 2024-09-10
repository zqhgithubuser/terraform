output "lb_dns_name" {
  value       = "http://${module.loadbalancer.lb_dns_name}"
  description = "The domain name of the load balancer"
}
