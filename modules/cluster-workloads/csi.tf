resource "kubernetes_storage_class" "ebs_sc" {
  metadata {
    name = "gp2-csi"
  }
  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  reclaim_policy         = "Delete"
  parameters = {
    type    = "gp2"
    fs_type = "ext4"
  }
}

variable "csi_role_arn" {
  type = string
}

locals {
  aws_ebs_csi_driver_values = {
    priorityClassName      = "system-cluster-critical"
    enableVolumeScheduling = true
    serviceAccount = {
      controller = {
        annotations = {
          "eks.amazonaws.com/role-arn" = var.csi_role_arn
        }
      }
    }
  }
}

resource "helm_release" "aws_ebs_csi_driver" {
  chart     = "${path.module}/charts/aws-ebs-csi-driver"
  name      = "aws-ebs-csi-driver"
  namespace = "kube-system"

  wait = false

  values = [yamlencode(local.aws_ebs_csi_driver_values)]
}
