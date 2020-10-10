variable "iam_instance_profile" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "instance_type" {
  type = string
}

variable "target_group_arns" {
  type = list(string)
}

variable "tags" {
  type = map(string)
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

variable "node_role" {
  type = string
}

variable "subnet" {
  type = string
}

variable "cluster" {
  type = object({
    name     = string
    endpoint = string
    certificate_authority = list(object({
      data = string
    }))
  })
}

variable "zone" {
  type = string
}

variable "name" {
  type = string
}

variable "taints" {
  type = list(object({
    key   = string
    value = string
  }))
  default = []
}
