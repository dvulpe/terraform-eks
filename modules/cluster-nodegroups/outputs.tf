output "asg_arns" {
  value = flatten([
    for node_group in local.node_groups : [
      for asg in node_group :
    asg.asg_arn]
  ])
}
