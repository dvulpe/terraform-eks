module "variant" {
  source              = "../../modules/eks-variant"
  vpc_name            = "k8s-variants"
  name                = "eks-demo"
  variant             = "blue"
  region              = local.region
  github_repository   = var.github_repository
  github_organisation = var.github_organisation
  tags = {
    Environment = "k8s-variants"
  }
}

variable "github_repository" {
  type = string
}

variable "github_organisation" {
  type = string
}
