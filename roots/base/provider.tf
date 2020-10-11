locals {
  region = "eu-west-1"
}

provider "aws" {
  region = local.region
}

