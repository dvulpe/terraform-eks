module "variant" {
  source              = "../../modules/eks-variant"
  vpc_name            = "k8s-variants"
  name                = "eks-demo"
  variant             = "blue"
  region              = local.region
  flux_repository_url = var.flux_repository_url
  tags = {
    Environment = "k8s-variants"
  }
}

variable "flux_repository_url" {
  type = string
}
