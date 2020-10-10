resource "aws_security_group" "cluster_sg" {
  name   = "${var.prefix}-cluster-sg"
  vpc_id = var.vpc.vpc_id
  tags = merge({
    Name = "cluster-sg"
  }, var.tags)
}

resource "aws_security_group_rule" "cluster" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.cluster_sg.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "cluster_self" {
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.cluster_sg.id
  to_port                  = 0
  type                     = "ingress"
  source_security_group_id = aws_security_group.cluster_sg.id
}

resource "aws_security_group_rule" "ingress_from_nodes" {
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.cluster_sg.id
  to_port           = 443
  cidr_blocks       = [var.vpc.vpc_cidr_block]
  type              = "ingress"
}

resource "aws_security_group_rule" "ingress_workers" {
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster_sg.id
  to_port                  = 443
  source_security_group_id = aws_security_group.worker_sg.id
  type                     = "ingress"
}
