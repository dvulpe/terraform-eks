module "iam_roles" {
  source         = "../../modules/iam-roles"
  oidc_providers = [
    data.terraform_remote_state.variant_green.outputs.oidc,
    data.terraform_remote_state.variant_blue.outputs.oidc,
  ]
}

data "terraform_remote_state" "variant_green" {
  backend = "s3"
  config  = {
    bucket   = local.tf_state_bucket
    key      = "github.com/dvulpe/terraform-eks/variant-green"
    region   = "eu-west-2"
    role_arn = local.tf_state_role_arn
  }
}

data "terraform_remote_state" "variant_blue" {
  backend = "s3"
  config  = {
    bucket   = local.tf_state_bucket
    key      = "github.com/dvulpe/terraform-eks/variant-blue"
    region   = "eu-west-2"
    role_arn = local.tf_state_role_arn
  }
}
