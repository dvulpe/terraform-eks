output "security_groups" {
  value = {
    worker_sg_id  = aws_security_group.worker_sg.id
    cluster_sg_id = aws_security_group.cluster_sg.id
    ingress_sg_id = aws_security_group.ingress_sg.id
  }
}
