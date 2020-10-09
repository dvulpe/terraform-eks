output "alb_address" {
  value = module.ingress.alb_dns_name
}
