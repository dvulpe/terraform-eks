resource "aws_launch_configuration" "node" {
  instance_type        = var.instance_type
  name_prefix          = "${var.name}-"
  iam_instance_profile = var.iam_instance_profile
  image_id             = var.ami_id
  security_groups      = var.security_group_ids
  spot_price           = "0.5"
  user_data            = local.user_data

  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_size = 50
    volume_type = "gp2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  user_data = templatefile("${path.module}/files/bottlerocket.toml", {
    cluster_name      = var.cluster.name
    endpoint          = var.cluster.endpoint
    b64_cluster_ca    = var.cluster.certificate_authority.0.data,
    node_role         = var.node_role,
    availability_zone = var.zone
    taints            = var.taints
  })
}

resource "aws_autoscaling_group" "nodegroup" {
  max_size             = var.max_size
  min_size             = var.min_size
  desired_capacity     = var.desired_size
  vpc_zone_identifier  = [var.subnet]
  launch_configuration = aws_launch_configuration.node.id

  name = var.name

  target_group_arns = var.target_group_arns

  lifecycle {
    ignore_changes = [
      desired_capacity,
    ]
    create_before_destroy = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster.name}"
    value               = "owned"
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/cluster/${var.cluster.name}"
    value               = "owned"
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/node.kubernetes.io/role"
    value               = var.node_role
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = true
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster.name}"
    value               = "enabled"
    propagate_at_launch = true
  }
  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

output "asg" {
  value = aws_autoscaling_group.nodegroup.id
}

output "asg_arn" {
  value = aws_autoscaling_group.nodegroup.arn
}
