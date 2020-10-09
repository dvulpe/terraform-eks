variable "name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "security_groups" {
  type = object({
    ingress_sg_id = string
  })
}

variable "vpc" {
  type = object({
    vpc_id         = string
    public_subnets = list(string)
  })
}

variable "ingress_weights" {
  type = object({
    blue  = number
    green = number
  })
}
