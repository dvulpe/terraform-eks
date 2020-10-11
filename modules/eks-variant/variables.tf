variable "name" {
  type = string
}

variable "variant" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "vpc_name" {
  type = string
}

variable "flux_repository_url" {
  type = string
}
