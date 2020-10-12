module "ingress" {
  source          = "../../modules/ingress"
  name            = local.name
  security_groups = module.security_groups.security_groups
  tags            = local.tags
  ingress_weights = {
    blue  = 0
    green = 100
  }
  vpc = module.vpc
}

module "security_groups" {
  source = "../../modules/security-groups"
  prefix = "variants"
  tags   = local.tags
  vpc    = module.vpc
}
