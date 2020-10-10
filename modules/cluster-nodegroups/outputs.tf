output "asg_arns" {
  value = concat([
    for asg in module.zonal_workers :
    asg.asg_arn
    ],
    [for asg in module.zonal_monitoring :
      asg.asg_arn
    ],
  )
}
