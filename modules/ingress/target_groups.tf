resource "aws_lb_target_group" "ingress_variant-blue" {
  name                 = "${var.name}-blue-ingress"
  protocol             = "HTTPS"
  port                 = 30443
  target_type          = "instance"
  health_check {
    enabled             = true
    interval            = 10
    path                = "/healthz"
    port                = 32254
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200-399"
  }
  vpc_id               = var.vpc.vpc_id
  deregistration_delay = 60
  stickiness {
    type            = "lb_cookie"
    enabled         = false
    cookie_duration = 300
  }
  tags                 = var.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "ingress_variant-green" {
  name                 = "${var.name}-green-ingress"
  protocol             = "HTTPS"
  port                 = 30443
  target_type          = "instance"
  health_check {
    enabled             = true
    interval            = 10
    path                = "/healthz"
    port                = 32254
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200-399"
  }
  vpc_id               = var.vpc.vpc_id
  deregistration_delay = 60
  stickiness {
    type            = "lb_cookie"
    enabled         = false
    cookie_duration = 300
  }
  tags                 = var.tags
  lifecycle {
    create_before_destroy = true
  }
}
