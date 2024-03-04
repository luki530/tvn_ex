variable "vpc_cidr" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "private_subnets_by_az" {
  type = map(string)
}

variable "public_subnets_by_az" {
  type = map(string)
}
