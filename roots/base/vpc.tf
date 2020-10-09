locals {
  name      = "k8s-variants"
  tags      = {
    Environment = local.name
  }
  variant_a = "eks-demo-blue"
  variant_b = "eks-demo-green"
  
  variants_cidr = "192.168.0.0/19"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.54.0"
  name    = local.name
  cidr    = "192.168.0.0/16"
  
  azs = [
    "eu-west-1a",
    "eu-west-1b",
    "eu-west-1c",
  ]
  
  private_subnets = [
    cidrsubnet(local.variants_cidr, 4, 0),
    cidrsubnet(local.variants_cidr, 4, 1),
    cidrsubnet(local.variants_cidr, 4, 2),
  ]
  
  public_subnets = [
    cidrsubnet(local.variants_cidr, 4, 3),
    cidrsubnet(local.variants_cidr, 4, 4),
    cidrsubnet(local.variants_cidr, 4, 5),
  ]
  
  database_subnets = [
    cidrsubnet(local.variants_cidr, 4, 6),
    cidrsubnet(local.variants_cidr, 4, 7),
    cidrsubnet(local.variants_cidr, 4, 8),
  ]
  
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  enable_nat_gateway = true
  single_nat_gateway = true
  
  enable_s3_endpoint = true
  
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.variant_a}" = "shared",
    "kubernetes.io/cluster/${local.variant_b}" = "shared",
    Tier                                       = "private"
  }
  
  tags = local.tags
}
