locals {
  podinfo_values = {
    replicaCount = 3
    ui = {
      message = "Running on ${var.cluster_name}"
    }
    ingress = {
      enabled = true
      path    = "/"
    }
  }
}

resource "helm_release" "podinfo" {
  chart     = "${path.module}/charts/podinfo"
  name      = "podinfo"
  namespace = "default"

  wait = false

  values = [yamlencode(local.podinfo_values)]
}
