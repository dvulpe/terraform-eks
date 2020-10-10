variable "variant" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "cluster" {
  type = object({
    name     = string
    endpoint = string
    version  = string
    certificate_authority = list(object({
      data = string
    }))
  })
}

variable "worker_role_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "security_groups" {
  type = object({
    worker_sg_id = string
  })
}

variable "target_group_arns" {
  type = list(string)
}

variable "min_size" {
  type    = number
  default = 0
}

variable "desired_size" {
  type = number
}

variable "max_size" {
  type = number
}
