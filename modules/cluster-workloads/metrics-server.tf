locals {
  metrics_server_values = {
    resources         = {
      requests = {
        cpu    = "100m"
        memory = "300Mi"
      }
    }
    priorityClassName = "system-cluster-critical"
  }
}

resource "helm_release" "metrics-server" {
  chart     = "${path.module}/charts/metrics-server"
  name      = "metrics-server"
  namespace = "kube-system"
  
  wait = false
  
  values = [yamlencode(local.metrics_server_values)]
}
