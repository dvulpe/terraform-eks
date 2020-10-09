resource "aws_security_group" "worker_sg" {
  name   = "${var.prefix}-worker-sg"
  vpc_id = var.vpc.vpc_id
  tags   = var.tags
}

resource "aws_security_group_rule" "egress" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.worker_sg.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "self" {
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.worker_sg.id
  to_port                  = 0
  type                     = "ingress"
  source_security_group_id = aws_security_group.worker_sg.id
}

resource "aws_security_group_rule" "from_cluster" {
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  type                     = "ingress"
  security_group_id        = aws_security_group.worker_sg.id
  source_security_group_id = aws_security_group.cluster_sg.id
}

resource "aws_security_group_rule" "from_ingress" {
  from_port                = 30443
  to_port                  = 30443
  protocol                 = "tcp"
  type                     = "ingress"
  security_group_id        = aws_security_group.worker_sg.id
  source_security_group_id = aws_security_group.ingress_sg.id
}

resource "aws_security_group_rule" "from_ingress_healthcheck" {
  from_port                = 32254
  to_port                  = 32254
  protocol                 = "tcp"
  type                     = "ingress"
  security_group_id        = aws_security_group.worker_sg.id
  source_security_group_id = aws_security_group.ingress_sg.id
}
