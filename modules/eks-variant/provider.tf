data "aws_eks_cluster_auth" "cluster" {
  name = module.cluster.cluster.id
}

provider "kubernetes" {
  host                   = module.cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(module.cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

provider "helm" {
  version = "~> 1.0"
  kubernetes {
    host                   = module.cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(module.cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
    load_config_file       = false
  }
}

provider "flux" {
  version                = "0.0.1"
  host                   = module.cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(module.cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

terraform {
  required_providers {
    flux = {
      source  = "dvulpe/flux"
      version = "0.0.1"
    }
  }
}
