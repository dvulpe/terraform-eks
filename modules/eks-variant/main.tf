data "aws_security_group" "cluster_sg" {
  name   = "variants-cluster-sg"
  vpc_id = data.aws_vpc.vpc.id
}

data "aws_security_group" "worker_sg" {
  name   = "variants-worker-sg"
  vpc_id = data.aws_vpc.vpc.id
}

data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    Tier = "private"
  }
}

data "aws_lb_target_group" "ingress" {
  name = "k8s-variants-${var.variant}-ingress"
}

module "cluster" {
  source       = "../eks-cluster"
  cluster_name = "${var.name}-${var.variant}"
  security_groups = {
    cluster_sg_id = data.aws_security_group.cluster_sg.id
  }
  tags = var.tags
  vpc = {
    vpc_id          = data.aws_vpc.vpc.id
    private_subnets = data.aws_subnet_ids.private.ids
  }
}

module "nodes" {
  source  = "../cluster-nodegroups"
  cluster = module.cluster.cluster
  security_groups = {
    worker_sg_id = data.aws_security_group.worker_sg.id
  }
  subnet_ids = data.aws_subnet_ids.private.ids
  target_group_arns = [
    data.aws_lb_target_group.ingress.arn,
  ]
  tags             = var.tags
  variant          = var.variant
  worker_role_name = module.cluster.worker_role_name
  min_size         = 0
  desired_size     = 1
  max_size         = 10
}

module "flux" {
  source              = "../flux-bootstrap"
  cluster_name        = module.cluster.cluster.name
  variant             = var.variant
  github_repository   = var.github_repository
  github_organisation = var.github_organisation
  depends_on = [
    module.nodes,
  ]
}
