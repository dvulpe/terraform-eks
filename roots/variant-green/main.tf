module "variant" {
  source   = "../../modules/eks-variant"
  vpc_name = "k8s-variants"
  name     = "eks-demo"
  variant  = "green"
  region   = local.region
  github_repository = var.github_repository
  tags = {
    Environment = "k8s-variants"
  }
}

variable "github_repository" {
  type = string
}
