locals {
  nginx_ingress_values = {
    controller = {
      config         = {
        "use-forwarded-headers" = "true"
      }
      kind           = "DaemonSet"
      podAnnotations = {
        "prometheus.io/scrape" = "true"
        "prometheus.io/port"   = "10254"
      }
      nodeSelector   = {
        "node.kubernetes.io/role" = "workers"
      }
      service        = {
        enableHttp            = "false"
        externalTrafficPolicy = "Local"
        type                  = "NodePort"
        nodePorts             = {
          https = "30443"
          tcp   = {
            "10254" = "32254"
          }
        }
      }
    }
    tcp        = {
      "10254" = "32254"
    }
  }
}

resource "helm_release" "nginx_ingress" {
  chart     = "${path.module}/charts/nginx-ingress"
  name      = "nginx-ingress"
  namespace = "default"

  wait = false

  values = [yamlencode(local.nginx_ingress_values)]
}
