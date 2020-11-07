data "aws_iam_policy_document" "thanos_trust" {
  dynamic "statement" {
    for_each = var.oidc_providers
    
    content {
      actions = ["sts:AssumeRoleWithWebIdentity"]
      effect  = "Allow"
      
      condition {
        variable = "${statement.value.issuer}:sub"
        test     = "StringEquals"
        values   = ["system:serviceaccount:monitoring:thanos"]
      }
      
      principals {
        identifiers = [statement.value.provider_arn]
        type        = "Federated"
      }
    }
  }
}

resource "aws_iam_role" "thanos" {
  name               = "thanos"
  assume_role_policy = data.aws_iam_policy_document.thanos_trust.json
}

variable "oidc_providers" {
  type = list(object({
    issuer       = string
    provider_arn = string
  }))
}
