data "aws_iam_policy_document" "eks_trust" {
  statement {
    effect = "Allow"
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

resource "aws_kms_key" "secret_encryption_key" {
  description         = "Key used by EKS to implement envelope encryption for secrets"
  enable_key_rotation = true
  tags = merge(var.tags, {
    Name = "${var.cluster_name}-secrets"
  })
}

resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.cluster_version
  vpc_config {
    subnet_ids              = var.vpc.private_subnets
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids = [
      var.security_groups.cluster_sg_id,
    ]
    public_access_cidrs = [
      "0.0.0.0/0",
    ]
  }
  depends_on = [
    aws_iam_role_policy_attachment.attach,
    aws_cloudwatch_log_group.eks_logs,
  ]

  encryption_config {
    resources = [
      "secrets",
    ]
    provider {
      key_arn = aws_kms_key.secret_encryption_key.arn
    }
  }

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
    effect = "Allow"
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
      groups = [
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

data "tls_certificate" "eks_oidc_cert" {
  url = aws_eks_cluster.eks.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    for cert in data.tls_certificate.eks_oidc_cert.certificates :
    cert.sha1_fingerprint if cert.is_ca
  ]
  url = aws_eks_cluster.eks.identity.0.oidc.0.issuer
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
    actions = [
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
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/k8s.io/cluster/${var.cluster_name}"
      values = [
        "owned",
      ]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role_policy" "autoscaling" {
  name   = "autoscaling"
  role   = aws_iam_role.cluster_autoscaler.name
  policy = data.aws_iam_policy_document.autoscaling.json
}

data "aws_iam_policy_document" "csi" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_oidc.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "csi" {
  name               = "${var.cluster_name}-csi"
  assume_role_policy = data.aws_iam_policy_document.csi.json
}

data "aws_iam_policy_document" "csi_policy" {
  statement {
    actions = [
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:DeleteVolume",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
    ]
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_role_policy" "csi" {
  name   = "csi"
  role   = aws_iam_role.csi.name
  policy = data.aws_iam_policy_document.csi_policy.json
}


