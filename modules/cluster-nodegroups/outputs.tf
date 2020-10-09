output "asg_arns" {
  value = [
  for asg in module.zonal_workers:
  asg.asg_arn
  ]
}
