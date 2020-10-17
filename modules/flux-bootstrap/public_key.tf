data "flux_identity_public_key" "flux_key" {
  namespace = kubernetes_namespace.flux.metadata.0.name
  pod_labels = {
    app = "flux"
  }
  port = 3030
  depends_on = [
    helm_release.flux,
  ]
}

resource "github_repository_deploy_key" "deploy_key" {
  key        = data.flux_identity_public_key.flux_key.public_key
  repository = var.github_repository
  title      = "flux-${var.variant}-deploy-key"
  read_only  = false
}

terraform {
  required_providers {
    flux = {
      source  = "dvulpe/flux"
      version = "0.0.1"
    }
  }
}
