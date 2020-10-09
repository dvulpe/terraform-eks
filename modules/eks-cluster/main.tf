data "aws_iam_policy_document" "eks_trust" {
  statement {
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole",
    ]
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_trust.json
}

locals {
  policies = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
  ]
}

resource "aws_iam_role_policy_attachment" "attach" {
  for_each   = toset(local.policies)
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = each.value
}

resource "aws_eks_cluster" "eks" {
  name       = var.cluster_name
  role_arn   = aws_iam_role.eks_cluster_role.arn
  version    = var.cluster_version
  vpc_config {
    subnet_ids              = var.vpc.private_subnets
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [
      var.security_groups.cluster_sg_id,
    ]
  }
  depends_on = [
    aws_iam_role_policy_attachment.attach,
    aws_cloudwatch_log_group.eks_logs,
  ]
  
  enabled_cluster_log_types = [
    "api", "audit", "authenticator", "controllerManager", "scheduler",
  ]
  
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "eks_logs" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 365
  tags              = var.tags
}

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole",
    ]
  }
}


resource "aws_iam_role" "worker_role" {
  name               = "${var.cluster_name}-worker-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}


locals {
  worker_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
}

resource "aws_iam_role_policy_attachment" "worker_attach" {
  for_each   = toset(local.worker_policies)
  role       = aws_iam_role.worker_role.name
  policy_arn = each.value
}

locals {
  worker_roles = [
    {
      rolearn  = aws_iam_role.worker_role.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = [
        "system:nodes",
        "system:bootstrappers",
      ]
    }
  ]
}


resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  
  data = {
    mapRoles    = yamlencode(local.worker_roles)
    mapUsers    = yamlencode("")
    mapAccounts = yamlencode("")
  }
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [
    "9e99a48a9960b14926bb7f3b02e22da2b0ab7280",
  ]
  url             = aws_eks_cluster.eks.identity.0.oidc.0.issuer
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }
    
    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_oidc.arn]
      type        = "Federated"
    }
  }
}


resource "aws_iam_role" "cluster_autoscaler" {
  name               = "${var.cluster_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler.json
}

data "aws_iam_policy_document" "autoscaling" {
  statement {
    actions   = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]
    resources = ["*"]
    effect    = "Allow"
  }
  statement {
    actions   = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
    ]
    resources = var.asg_arns
    effect    = "Allow"
  }
}

resource "aws_iam_role_policy" "autoscaling" {
  name   = "autoscaling"
  role   = aws_iam_role.cluster_autoscaler.name
  policy = data.aws_iam_policy_document.autoscaling.json
}
