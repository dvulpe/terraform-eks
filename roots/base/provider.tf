locals {
  region = "eu-west-1"
}

provider "aws" {
  region = local.region
}

terraform {
  backend "local" {
  }
}
