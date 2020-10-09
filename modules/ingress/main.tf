data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    effect    = "Allow"
    principals {
      identifiers = [
        "arn:aws:iam::156460612806:root",
        "arn:aws:iam::652711504416:root",
      ]
      type        = "AWS"
    }
    resources = [
      "${aws_s3_bucket.access_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
    actions   = [
      "s3:PutObject",
    ]
  }
  
  statement {
    effect    = "Allow"
    principals {
      identifiers = [
        "delivery.logs.amazonaws.com",
      ]
      type        = "Service"
    }
    resources = [
      "${aws_s3_bucket.access_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
    actions   = [
      "s3:PutObject",
    ]
    condition {
      test     = "StringEquals"
      values   = [
        "bucket-owner-full-control",
      ]
      variable = "s3:x-amz-acl"
    }
  }
  statement {
    effect    = "Allow"
    principals {
      identifiers = [
        "delivery.logs.amazonaws.com",
      ]
      type        = "Service"
    }
    resources = [
      aws_s3_bucket.access_logs.arn,
    ]
    actions   = [
      "s3:GetBucketAcl",
    ]
  }
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.access_logs.bucket
  policy = data.aws_iam_policy_document.bucket_policy.json
}

resource "random_pet" "suffix" {
  length = 2
}

resource "aws_s3_bucket" "access_logs" {
  bucket = "ingress-access-logs-${random_pet.suffix.id}"
  tags   = var.tags
  
  force_destroy = true
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_lb" "alb" {
  name               = "${var.name}-ingress"
  subnets            = var.vpc.public_subnets
  enable_http2       = true
  load_balancer_type = "application"
  
  access_logs {
    bucket  = aws_s3_bucket.access_logs.bucket
    enabled = true
  }
  
  security_groups = [
    var.security_groups.ingress_sg_id,
  ]
  tags            = var.tags
  
  depends_on = [
    aws_s3_bucket.access_logs,
  ]
}

resource "aws_lb_listener" "ingress_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  default_action {
    type = "forward"
  
    forward {
      stickiness {
        duration = 60
        enabled  = false
      }
      target_group {
        arn    = aws_lb_target_group.ingress_variant-blue.arn
        weight = var.ingress_weights.blue
      }
      target_group {
        arn    = aws_lb_target_group.ingress_variant-green.arn
        weight = var.ingress_weights.green
      }
    }
  }
}
