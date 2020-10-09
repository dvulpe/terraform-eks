data "aws_ssm_parameter" "bottlerocket_ami" {
  name = "/aws/service/bottlerocket/aws-k8s-${var.cluster.version}/x86_64/latest/image_id"
}

data "aws_subnet" "subnet" {
  for_each = toset(var.subnet_ids)
  id       = each.value
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = var.worker_role_name
  role = var.worker_role_name
}

locals {
  zone_name_to_subnet_id = {
  for subnet in data.aws_subnet.subnet:
  subnet.availability_zone => subnet.id
  }
}

module "zonal_workers" {
  for_each             = local.zone_name_to_subnet_id
  source               = "../node-group"
  ami_id               = data.aws_ssm_parameter.bottlerocket_ami.value
  cluster              = var.cluster
  iam_instance_profile = aws_iam_instance_profile.instance_profile.arn
  instance_type        = "r5.xlarge"
  name                 = "${var.variant}-workers-${each.key}"
  node_role            = "workers"
  security_group_ids   = [var.security_groups.worker_sg_id]
  subnet               = each.value
  tags                 = var.tags
  target_group_arns    = var.target_group_arns
  zone                 = each.key
  
  
  min_size     = var.min_size
  desired_size = var.desired_size
  max_size     = var.max_size
}

module "zonal_monitoring" {
  for_each             = local.zone_name_to_subnet_id
  source               = "../node-group"
  ami_id               = data.aws_ssm_parameter.bottlerocket_ami.value
  cluster              = var.cluster
  iam_instance_profile = aws_iam_instance_profile.instance_profile.arn
  instance_type        = "r5.xlarge"
  name                 = "${var.variant}-monitoring-${each.key}"
  node_role            = "monitoring"
  security_group_ids   = [var.security_groups.worker_sg_id]
  subnet               = each.value
  tags                 = var.tags
  target_group_arns    = var.target_group_arns
  zone                 = each.key
  taints               = [{
    key   = "node.kubernetes.io/role"
    value = "monitoring:NoSchedule"
  }]
  
  
  min_size     = var.min_size
  desired_size = var.desired_size
  max_size     = var.max_size
}
