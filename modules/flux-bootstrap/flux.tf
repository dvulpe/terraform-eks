locals {
  flux_values = {
    resources = {
      requests = {
        cpu    = "100m"
        memory = "300Mi"
      }
    }

    git = {
      url    = "git@github.com:${var.github_organisation}/${var.github_repository}.git"
      path   = "kustomize/environments/variant-${var.variant}"
      branch = "main"
      label  = "flux-variant-${var.variant}"
    }

    manifestGeneration = true

    registry = {
      disableScanning = true
    }

    memcached = {
      enabled = false
    }

    syncGarbageCollection = {
      enabled = true
      dry     = false
    }

    podDisruptionBudget = {
      enabled        = true
      maxUnavailable = 1
    }
  }
}

variable "variant" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "github_organisation" {
  type = string
}

resource "kubernetes_namespace" "flux" {
  metadata {
    name = "flux"
  }
}

resource "helm_release" "flux" {
  chart     = "${path.module}/charts/flux"
  name      = "flux"
  namespace = kubernetes_namespace.flux.metadata.0.name

  wait      = true

  values = [yamlencode(local.flux_values)]
}
