output "cluster" {
  value = aws_eks_cluster.eks
}

output "worker_role_name" {
  value = aws_iam_role.worker_role.name
}

output "cluster_autoscaler_role_arn" {
  value = aws_iam_role.cluster_autoscaler.arn
}
