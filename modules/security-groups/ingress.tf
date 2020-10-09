resource "aws_security_group" "ingress_sg" {
  name   = "${var.prefix}-ingress-sg"
  vpc_id = var.vpc.vpc_id
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 30443
    protocol        = "tcp"
    to_port         = 30443
    description     = "https port"
    security_groups = [
      aws_security_group.worker_sg.id,
    ]
  }
  egress {
    from_port       = 32254
    protocol        = "tcp"
    to_port         = 32254
    description     = "healthcheck port"
    security_groups = [
      aws_security_group.worker_sg.id,
    ]
  }
  egress {
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags   = var.tags
}
