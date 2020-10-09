variable "prefix" {
  type = string
}

variable "vpc" {
  type = object({
    vpc_id         = string
    vpc_cidr_block = string
  })
}

variable "tags" {
  type = map(string)
}
