variable "autoscaler_role_arn" {
  type = string
}
variable "region" {
  type = string
}
variable "cluster_name" {
  type = string
}
locals {
  cluster_autoscaler_values = {
    
    podAnnotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/port"   = "8085"
    }
    
    resources = {
      requests = {
        cpu    = "100m"
        memory = "300Mi"
      }
      limits   = {
        cpu    = "1000m"
        memory = "512Mi"
      }
    }
    
    image = {
      repository = "k8s.gcr.io/autoscaling/cluster-autoscaler"
      tag        = "v1.17.3"
    }
    
    priorityClassName = "system-cluster-critical"
    awsRegion         = var.region
    fullnameOverride  = "cluster-autoscaler"
    autoDiscovery     = {
      clusterName = var.cluster_name
    }
    
    extraArgs = {
      "scale-down-utilization-threshold" = "0.8"
      "scale-down-unneeded-time"         = "2m"
      "skip-nodes-with-local-storage"    = "false"
    }
    
    rbac = {
      pspEnabled                = true
      serviceAccountAnnotations = {
        "eks.amazonaws.com/role-arn" = var.autoscaler_role_arn
      }
    }
  }
}

resource "helm_release" "autoscaler" {
  chart     = "${path.module}/charts/cluster-autoscaler"
  name      = "cluster-autoscaler"
  namespace = "kube-system"
  
  wait = false
  
  values = [yamlencode(local.cluster_autoscaler_values)]
}
