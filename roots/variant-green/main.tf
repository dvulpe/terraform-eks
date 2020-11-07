module "variant" {
  source              = "../../modules/eks-variant"
  vpc_name            = "k8s-variants"
  name                = "eks-demo"
  variant             = "green"
  region              = local.region
  github_repository   = var.github_repository
  github_organisation = var.github_organisation
  tags = {
    Environment = "k8s-variants"
  }
}

output "oidc" {
  value = module.variant.oidc
}

variable "github_repository" {
  type = string
}

variable "github_organisation" {
  type = string
}
