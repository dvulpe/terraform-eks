output "cluster" {
  value = aws_eks_cluster.eks
}

output "worker_role_name" {
  value = aws_iam_role.worker_role.name
}

output "cluster_autoscaler_role_arn" {
  value = aws_iam_role.cluster_autoscaler.arn
}

output "csi_role_arn" {
  value = aws_iam_role.csi.arn
}

output "oidc" {
  value = {
    issuer       = replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")
    provider_arn = aws_iam_openid_connect_provider.eks_oidc.arn
  }
}
