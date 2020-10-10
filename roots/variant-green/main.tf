module "variant" {
  source   = "../../modules/eks-variant"
  vpc_name = "k8s-variants"
  name     = "eks-demo"
  variant  = "green"
  region   = local.region
  tags = {
    Environment = "k8s-variants"
  }
}
