output "variant_a_target_group_name" {
  value = aws_lb_target_group.ingress_variant-blue.name
}

output "variant_b_target_group_name" {
  value = aws_lb_target_group.ingress_variant-green.name
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}
